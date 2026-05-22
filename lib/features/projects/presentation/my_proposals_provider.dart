// lib/features/projects/presentation/my_proposals_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

final myProposalsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  try {
    final proposals = await supabase
        .from('proposals')
        .select('id, bid_amount, status, cover_letter, created_at, project_id')
        .eq('freelancer_id', user.id)
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