// lib/features/projects/presentation/proposals_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

// ── Proposals for a single project (used by ViewProposalsPage) ──
final projectProposalsProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, projectId) async {
      try {
        final data = await supabase
            .from('proposals')
            .select(
          'id, bid_amount, cover_letter, status, freelancer_id, '
              'freelancer:profiles!freelancer_id(name, headline, location, experience_years, skills)',
        )
            .eq('project_id', projectId)
            .order('created_at', ascending: false);
        return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        throw Exception('Failed to load proposals: $e');
      }
    });

// ── Accept a proposal ────────────────────────────────────────────────────────
// Sets the chosen proposal → 'accepted'
// Sets the project status → 'closed' (in-progress, not yet complete)
// Rejects all other pending proposals on the same project
Future<void> acceptProposal({
  required String proposalId,
  required String projectId,
  required String freelancerId,
}) async {
  // 1. Accept the chosen proposal
  await supabase
      .from('proposals')
      .update({'status': 'accepted'})
      .eq('id', proposalId);

  // 2. Close the project (in-progress)
  await supabase
      .from('projects')
      .update({'status': 'closed'})
      .eq('id', projectId);

  // 3. Reject all other pending proposals on this project
  await supabase
      .from('proposals')
      .update({'status': 'rejected'})
      .eq('project_id', projectId)
      .eq('status', 'pending')
      .neq('id', proposalId);
}

// ── Reject a single proposal ─────────────────────────────────────────────────
Future<void> rejectProposal({required String proposalId}) async {
  await supabase
      .from('proposals')
      .update({'status': 'rejected'})
      .eq('id', proposalId);
}

// ── Complete a project ───────────────────────────────────────────────────────
// BUG 3 FIX: was missing — must set project status → 'completed'
// and proposal status → 'completed' so freelancer stats reflect it
Future<void> completeProject({
  required String projectId,
  required String proposalId,
}) async {
  // 1. Mark project as 'completed' (was incorrectly left as 'closed' before)
  await supabase
      .from('projects')
      .update({'status': 'completed'})
      .eq('id', projectId);

  // 2. Mark the accepted proposal as 'completed' so freelancer stats update
  await supabase
      .from('proposals')
      .update({'status': 'completed'})
      .eq('id', proposalId);
}