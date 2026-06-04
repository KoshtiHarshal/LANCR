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
  final String? lastMessage;
  final DateTime? lastMessageAt;

  ConversationModel({
    required this.id,
    required this.otherPersonName,
    required this.otherPersonId,
    required this.projectTitle,
    required this.projectId,
    this.lastMessage,
    this.lastMessageAt,
  });
}

// ── All conversations for current user ─────────────────────
final conversationsProvider =
FutureProvider<List<ConversationModel>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

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

  return (data as List).map((row) {
    final isClient = (row['client']['id'] == user.id);
    final other = isClient ? row['freelancer'] : row['client'];
    return ConversationModel(
      id: row['id'],
      otherPersonId: other['id'],
      otherPersonName: other['name'] ?? 'Unknown',
      projectId: row['project_id'],
      projectTitle: row['project']['title'] ?? '',
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

  // Update last_message snapshot on conversation
  await supabase.from('conversations').update({
    'last_message': content,
    'last_message_at': DateTime.now().toIso8601String(),
  }).eq('id', conversationId);
}