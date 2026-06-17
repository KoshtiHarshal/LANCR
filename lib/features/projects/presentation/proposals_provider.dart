// lib/features/projects/presentation/proposals_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

// ─────────────────────────────────────────────────────────────
// Fetches all proposals for a given project (client use)
// ─────────────────────────────────────────────────────────────
final projectProposalsProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
      (ref, projectId) async {
    try {
      // Single query: embed the freelancer profile via the FK (no N+1).
      final rows = await supabase
          .from('proposals')
          .select(
              'id, cover_letter, bid_amount, status, created_at, freelancer_id, '
              'freelancer:profiles!freelancer_id(name, headline, location, skills, experience_years, rating_avg, rating_count)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw Exception('Failed to load proposals: $e');
    }
  },
);

// ─────────────────────────────────────────────────────────────
// Accept a proposal → sets it accepted, rejects all others,
// closes the project, and creates a conversation
// ─────────────────────────────────────────────────────────────
Future<void> acceptProposal({
  required String proposalId,
  required String projectId,
  required String freelancerId,
}) async {
  // 1. Accept this proposal
  await supabase
      .from('proposals')
      .update({'status': 'accepted'})
      .eq('id', proposalId);

  // 2. Reject all other proposals for this project
  await supabase
      .from('proposals')
      .update({'status': 'rejected'})
      .eq('project_id', projectId)
      .neq('id', proposalId);

  // 3. Close the project
  await supabase
      .from('projects')
      .update({'status': 'closed'})
      .eq('id', projectId);

  // 4. Create or get existing conversation
  await getOrCreateConversation(
    projectId: projectId,
    freelancerId: freelancerId,
  );
}

// ─────────────────────────────────────────────────────────────
// Reject a single proposal
// ─────────────────────────────────────────────────────────────
Future<void> rejectProposal({required String proposalId}) async {
  await supabase
      .from('proposals')
      .update({'status': 'rejected'})
      .eq('id', proposalId);
}

// ─────────────────────────────────────────────────────────────
// Gets an existing conversation or creates a new one
// ─────────────────────────────────────────────────────────────
Future<String> getOrCreateConversation({
  required String projectId,
  required String freelancerId,
}) async {
  final clientId = supabase.auth.currentUser?.id;
  if (clientId == null) throw Exception('Not signed in');

  final existing = await supabase
      .from('conversations')
      .select('id')
      .eq('project_id', projectId)
      .eq('client_id', clientId)
      .eq('freelancer_id', freelancerId)
      .maybeSingle();

  if (existing != null) {
    return existing['id'] as String;
  }

  final created = await supabase
      .from('conversations')
      .insert({
    'project_id': projectId,
    'client_id': clientId,
    'freelancer_id': freelancerId,
  })
      .select('id')
      .single();

  return created['id'] as String;
}

// ─────────────────────────────────────────────────────────────
// Mark project as completed (client triggers after work is done)
// ─────────────────────────────────────────────────────────────
Future<void> completeProject({
  required String projectId,
  required String proposalId,
}) async {
  await supabase
      .from('projects')
      .update({'status': 'completed'})
      .eq('id', projectId);

  await supabase
      .from('proposals')
      .update({'status': 'completed'})
      .eq('id', proposalId);
}