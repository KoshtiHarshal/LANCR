// lib/features/proposals/data/proposals_repository.dart
// Central repository for all proposal-related Supabase calls.
// UI providers import from here instead of calling supabase directly.

import '../../../../main.dart';

class ProposalsRepository {
  /// Fetch all proposals for a project (client view).
  Future<List<Map<String, dynamic>>> fetchProjectProposals(
      String projectId) async {
    final proposals = await supabase
        .from('proposals')
        .select(
        'id, cover_letter, bid_amount, status, created_at, freelancer_id')
        .eq('project_id', projectId)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> result = [];
    for (final proposal in (proposals as List)) {
      final p = Map<String, dynamic>.from(proposal);
      final freelancerId = p['freelancer_id'] as String?;
      if (freelancerId != null) {
        try {
          final profile = await supabase
              .from('profiles')
              .select('name, headline, location, skills, experience_years, completed_projects_count')
              .eq('id', freelancerId)
              .maybeSingle();
          p['freelancer'] = profile;
        } catch (_) {
          p['freelancer'] = null;
        }
      }
      result.add(p);
    }
    return result;
  }

  /// Accept a proposal → sets it accepted, rejects others, closes project.
  Future<void> acceptProposal({
    required String proposalId,
    required String projectId,
    required String freelancerId,
  }) async {
    await supabase
        .from('proposals')
        .update({'status': 'accepted'}).eq('id', proposalId);
    await supabase
        .from('proposals')
        .update({'status': 'rejected'})
        .eq('project_id', projectId)
        .neq('id', proposalId);
    await supabase
        .from('projects')
        .update({'status': 'closed'}).eq('id', projectId);
  }

  /// Reject a single proposal.
  Future<void> rejectProposal({required String proposalId}) async {
    await supabase
        .from('proposals')
        .update({'status': 'rejected'}).eq('id', proposalId);
  }
}

final proposalsRepository = ProposalsRepository();