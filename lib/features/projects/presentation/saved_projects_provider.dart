// lib/features/projects/presentation/saved_projects_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../main.dart';

/// Set of project ids the current freelancer has saved — drives the bookmark
/// state on project cards.
final savedProjectIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return <String>{};
  try {
    final rows = await supabase
        .from('saved_projects')
        .select('project_id')
        .eq('freelancer_id', userId);
    return (rows as List).map((e) => e['project_id'] as String).toSet();
  } catch (_) {
    return <String>{};
  }
});

/// Full saved-project rows (newest-saved first) for the Saved list. The project
/// is embedded via the FK; rows whose project is no longer visible (e.g. closed
/// and the user never applied) are dropped.
final savedProjectsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return [];
  try {
    final rows = await supabase
        .from('saved_projects')
        .select(
          'created_at, project:projects!project_id('
          'id, title, description, budget_min, budget_max, skills, duration, '
          'status, category, created_at, client_id, '
          'profiles!client_id(name, company, location), proposals(count))',
        )
        .eq('freelancer_id', userId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((e) => e['project'])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (e) {
    throw Exception('Failed to load saved projects: $e');
  }
});

/// Save or unsave a project for the current freelancer.
Future<void> toggleSaveProject(
  String projectId, {
  required bool currentlySaved,
}) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return;
  if (currentlySaved) {
    await supabase
        .from('saved_projects')
        .delete()
        .eq('freelancer_id', userId)
        .eq('project_id', projectId);
  } else {
    await supabase.from('saved_projects').insert({
      'freelancer_id': userId,
      'project_id': projectId,
    });
  }
}
