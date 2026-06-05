// lib/features/messages/presentation/messages_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

// ── Conversation model ──────────────────────────────────────
class ConversationModel {
  final String id;
  final String otherPersonName;
  final String otherPersonId;
  final String projectTitle;
  final String projectId;
  final String? proposalId;
  final bool isClient;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ConversationModel({
    required this.id,
    required this.otherPersonName,
    required this.otherPersonId,
    required this.projectTitle,
    required this.projectId,
    this.proposalId,
    this.isClient = false,
    this.lastMessage,
    this.lastMessageAt,
  });
}

// ── All conversations for current user ─────────────────────
final conversationsProvider =
FutureProvider<List<ConversationModel>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  // Step 1: fetch conversations — NO proposals join
  final data = await supabase
      .from('conversations')
      .select('''
        id, project_id, last_message, last_message_at,
        client:client_id(id, name),
        freelancer:freelancer_id(id, name),
        project:project_id(title)
      ''')
      .or('client_id.eq.${user.id},freelancer_id.eq.${user.id}')
      .order('last_message_at', ascending: false);

  final rows = data as List;
  if (rows.isEmpty) return [];

  // Step 2: fetch accepted proposals for all project_ids in one query
  final projectIds =
  rows.map((r) => r['project_id'] as String).toSet().toList();

  final proposals = await supabase
      .from('proposals')
      .select('id, project_id')
      .inFilter('project_id', projectIds)
      .eq('status', 'accepted');

  // Build a map: project_id → proposal_id
  final Map<String, String> proposalMap = {};
  for (final p in (proposals as List)) {
    proposalMap[p['project_id'] as String] = p['id'] as String;
  }

  // Step 3: map rows to ConversationModel
  return rows.map((row) {
    final isClient = (row['client']['id'] == user.id);
    final other = isClient ? row['freelancer'] : row['client'];
    final projectId = row['project_id'] as String;

    return ConversationModel(
      id: row['id'],
      otherPersonId: other['id'],
      otherPersonName: other['name'] ?? 'Unknown',
      projectId: projectId,
      projectTitle: row['project']['title'] ?? '',
      proposalId: proposalMap[projectId],
      isClient: isClient,
      lastMessage: row['last_message'],
      lastMessageAt: row['last_message_at'] != null
          ? DateTime.parse(row['last_message_at'])
          : null,
    );
  }).toList();
});

// ── Real-time messages stream for a conversation ────────────
final messagesProvider =
StreamProvider.family<List<Map<String, dynamic>>, String>(
      (ref, conversationId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  },
);

// ── Send a message ──────────────────────────────────────────
Future<void> sendMessage({
  required String conversationId,
  required String content,
}) async {
  final user = supabase.auth.currentUser!;

  await supabase.from('messages').insert({
    'conversation_id': conversationId,
    'sender_id': user.id,
    'content': content,
  });

  await supabase.from('conversations').update({
    'last_message': content,
    'last_message_at': DateTime.now().toIso8601String(),
  }).eq('id', conversationId);
}