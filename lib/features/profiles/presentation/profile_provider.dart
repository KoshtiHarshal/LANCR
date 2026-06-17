// lib/features/profiles/presentation/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../main.dart';

/// Current logged-in user's own profile
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return null;
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
    // Single query: embed each proposal's project status (no N+1).
    final proposals = await supabase
        .from('proposals')
        .select('status, project:projects!project_id(status)')
        .eq('freelancer_id', freelancerId);

    final list = proposals as List;
    final totalProposals = list.length;
    final acceptedProposals =
        list.where((p) => p['status'] == 'accepted').length;

    // Completed projects: accepted proposals whose project is completed.
    final completedProjects = list.where((p) {
      final project = p['project'] as Map<String, dynamic>?;
      return p['status'] == 'accepted' && project?['status'] == 'completed';
    }).length;

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

/// A client's currently open projects — shown on their public profile so
/// freelancers can see what they hire for. Only 'open' projects are returned
/// (those are visible to everyone under the projects RLS policy).
final clientRecentProjectsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, clientId) async {
  try {
    final rows = await supabase
        .from('projects')
        .select('id, title, budget_min, budget_max, status, created_at, skills')
        .eq('client_id', clientId)
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(5);
    return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
  } catch (_) {
    return [];
  }
});

final clientStatsProvider =
    FutureProvider.family<Map<String, int>, String>((ref, clientId) async {
  try {
    final projects = await supabase
        .from('projects')
        .select('id, status')
        .eq('client_id', clientId);
    final list = projects as List;

    return {
      'totalProjects': list.length,
      'activeProjects':
          list.where((project) => project['status'] == 'closed').length,
      'completedProjects':
          list.where((project) => project['status'] == 'completed').length,
    };
  } catch (_) {
    return {
      'totalProjects': 0,
      'activeProjects': 0,
      'completedProjects': 0,
    };
  }
});
