// lib/features/proposals/presentation/my_proposals_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lancr_app/main.dart';
import 'package:lancr_app/features/auth/presentation/auth_provider.dart';

final myProposalsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return [];

  try {
    final proposals = await supabase
        .from('proposals')
        .select('id, bid_amount, status, cover_letter, created_at, project_id')
        .eq('freelancer_id', userId)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> result = [];

    for (final proposal in (proposals as List)) {
      final p = Map<String, dynamic>.from(proposal);
      final projectId = p['project_id'] as String?;

      // Fetch project details separately
      if (projectId != null) {
        try {
          final project = await supabase
              .from('projects')
              .select('id, title, description, budget_min, budget_max, status')
              .eq('id', projectId)
              .maybeSingle();
          p['project'] = project;
        } catch (_) {
          p['project'] = null;
        }
      }
      result.add(p);
    }

    return result;
  } catch (e) {
    throw Exception('Failed to load proposals: $e');
  }
});

// ─────────────────────────────────────────────────────────────
// Stats computed from myProposalsProvider
// ─────────────────────────────────────────────────────────────
final myProposalStatsProvider = Provider<Map<String, int>>((ref) {
  final proposalsAsync = ref.watch(myProposalsProvider);

  return proposalsAsync.maybeWhen(
    data: (proposals) {
      int total = proposals.length;
      int pending = 0;
      int accepted = 0;
      int rejected = 0;
      int completed = 0;

      for (final p in proposals) {
        switch (p['status']) {
          case 'pending':
            pending++;
            break;
          case 'accepted':
            accepted++;
            break;
          case 'rejected':
            rejected++;
            break;
          case 'completed':
            completed++;
            break;
        }
      }

      return {
        'total': total,
        'pending': pending,
        'accepted': accepted,
        'rejected': rejected,
        'completed': completed,
      };
    },
    orElse: () => {
      'total': 0,
      'pending': 0,
      'accepted': 0,
      'rejected': 0,
      'completed': 0,
    },
  );
});
