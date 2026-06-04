// lib/features/projects/presentation/project_completion_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

/// Marks a project as completed.
/// - Sets project status → 'completed'
/// - Sets the accepted proposal status → 'completed'
Future<void> completeProject({
  required String projectId,
}) async {
  // 1. Mark project as completed
  await supabase
      .from('projects')
      .update({'status': 'completed'})
      .eq('id', projectId);

  // 2. Mark the accepted proposal as completed too
  await supabase
      .from('proposals')
      .update({'status': 'completed'})
      .eq('project_id', projectId)
      .eq('status', 'accepted');
}

/// Fetches the accepted freelancer's info for a closed/completed project.
final acceptedFreelancerProvider =
FutureProvider.family<Map<String, dynamic>?, String>(
      (ref, projectId) async {
    try {
      final result = await supabase
          .from('proposals')
          .select(
          'id, bid_amount, freelancer_id, status, profiles:freelancer_id(name, headline, location, skills)')
          .eq('project_id', projectId)
          .inFilter('status', ['accepted', 'completed'])
          .maybeSingle();
      return result;
    } catch (_) {
      return null;
    }
  },
);

/// Provider to fetch a single project's full detail (used in completion screen).
final projectDetailProvider =
FutureProvider.family<Map<String, dynamic>?, String>(
      (ref, projectId) async {
    try {
      final result = await supabase
          .from('projects')
          .select('id, title, description, status, budget_min, budget_max, created_at')
          .eq('id', projectId)
          .single();
      return result;
    } catch (_) {
      return null;
    }
  },
);