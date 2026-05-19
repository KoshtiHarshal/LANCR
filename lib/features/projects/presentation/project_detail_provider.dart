// lib/features/projects/presentation/project_detail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

final projectDetailProvider =
FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  try {
    // Fetch project row only — no join
    final project = await supabase
        .from('projects')
        .select(
      'id, title, description, budget_min, budget_max, '
          'skills, duration, status, created_at, client_id',
    )
        .eq('id', projectId)
        .single();

    // Fetch client profile separately — avoids FK name issues
    final clientId = project['client_id'] as String?;
    Map<String, dynamic>? profile;
    if (clientId != null) {
      try {
        profile = await supabase
            .from('profiles')
            .select('name, location, company')
            .eq('id', clientId)
            .maybeSingle();
      } catch (_) {
        profile = null;
      }
    }

    return {
      ...Map<String, dynamic>.from(project),
      'profiles': profile,
    };
  } catch (e) {
    throw Exception('Failed to load project: $e');
  }
});

final existingProposalProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, projectId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  try {
    final data = await supabase
        .from('proposals')
        .select('id, bid_amount, status, cover_letter')
        .eq('project_id', projectId)
        .eq('freelancer_id', user.id)
        .maybeSingle();
    return data != null ? Map<String, dynamic>.from(data) : null;
  } catch (e) {
    return null;
  }
});