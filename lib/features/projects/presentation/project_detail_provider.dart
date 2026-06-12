// lib/features/projects/presentation/project_detail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import 'package:flutter/foundation.dart';
import '../../auth/presentation/auth_provider.dart';

final projectDetailProvider =
FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) async {
  try {
    final rawProject = await supabase
        .from('projects')
        .select(
      'id, title, description, budget_min, budget_max, '
          'skills, duration, status, created_at, client_id',
    )
        .eq('id', projectId)
        .single();

    // ✅ Force typed map — critical step
    final project = Map<String, dynamic>.from(rawProject as Map);
    final clientId = project['client_id'] as String?;

    Map<String, dynamic>? profile;
    int proposalCount = 0;

    if (clientId != null) {
      try {
        final rawProfile = await supabase
            .from('profiles')
            .select('id, name, location, company, bio, avatar_url')
            .eq('id', clientId)
            .maybeSingle();
        profile = rawProfile != null
            ? Map<String, dynamic>.from(rawProfile as Map)
            : null;
      } catch (e) {
        assert(() { debugPrint('Profile fetch error: $e'); return true; }());
        profile = null;
      }
    }

    try {
      final countData = await supabase
          .from('proposals')
          .select('id')
          .eq('project_id', projectId);
      proposalCount = (countData as List).length;
    } catch (_) {
      proposalCount = 0;
    }

    // ✅ Build typed map explicitly — NO spread operator
    return <String, dynamic>{
      'id': project['id'],
      'title': project['title'],
      'description': project['description'],
      'budget_min': project['budget_min'],
      'budget_max': project['budget_max'],
      'skills': project['skills'],
      'duration': project['duration'],
      'status': project['status'],
      'created_at': project['created_at'],
      'client_id': project['client_id'],
      'profiles': profile,
      'proposal_count': proposalCount,
    };
  } catch (e) {
    throw Exception('Failed to load project: $e');
  }
});

final existingProposalProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, projectId) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return null;
  try {
    final raw = await supabase
        .from('proposals')
        .select('id, bid_amount, status, cover_letter, created_at')
        .eq('project_id', projectId)
        .eq('freelancer_id', userId)
        .maybeSingle();
    // ✅ Force typed here too
    return raw != null ? Map<String, dynamic>.from(raw as Map) : null;
  } catch (_) {
    return null;
  }
});
