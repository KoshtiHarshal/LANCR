// lib/features/profiles/presentation/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

/// Current logged-in user's own profile
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  try {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  } catch (_) {
    return null;
  }
});

/// Any user's public profile by userId — used for Public Profile Page
final publicProfileProvider =
FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  try {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return data;
  } catch (_) {
    return null;
  }
});

/// Completed projects count for a freelancer — shown on public profile
final freelancerCompletedProjectsProvider =
FutureProvider.family<int, String>((ref, freelancerId) async {
  try {
    final result = await supabase
        .from('proposals')
        .select('id')
        .eq('freelancer_id', freelancerId)
        .eq('status', 'accepted');
    // Count projects where status is 'completed'
    final projectIds =
    (result as List).map((p) => p['id'] as String).toList();
    if (projectIds.isEmpty) return 0;

    final completed = await supabase
        .from('projects')
        .select('id')
        .eq('status', 'completed')
        .inFilter('id',
        (result as List).map((p) => p['project_id'] as String).toList());
    return (completed as List).length;
  } catch (_) {
    return 0;
  }
});

/// Cleaner version — directly query proposals joined with projects
final freelancerStatsProvider =
FutureProvider.family<Map<String, int>, String>((ref, freelancerId) async {
  try {
    // Total proposals sent
    final proposals = await supabase
        .from('proposals')
        .select('id, status, project_id')
        .eq('freelancer_id', freelancerId);

    final list = proposals as List;
    final totalProposals = list.length;
    final acceptedProposals =
        list.where((p) => p['status'] == 'accepted').length;

    // Completed projects: proposals accepted + project status = completed
    int completedProjects = 0;
    for (final p in list) {
      if (p['status'] == 'accepted') {
        try {
          final proj = await supabase
              .from('projects')
              .select('status')
              .eq('id', p['project_id'])
              .maybeSingle();
          if (proj != null && proj['status'] == 'completed') {
            completedProjects++;
          }
        } catch (_) {}
      }
    }

    return {
      'totalProposals': totalProposals,
      'activeProjects': acceptedProposals - completedProjects,
      'completedProjects': completedProjects,
    };
  } catch (_) {
    return {
      'totalProposals': 0,
      'activeProjects': 0,
      'completedProjects': 0,
    };
  }
});