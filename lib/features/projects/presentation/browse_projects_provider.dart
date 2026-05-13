// lib/features/projects/presentation/browse_projects_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

/// Fetches all open projects from Supabase, newest first.
final browseProjectsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final data = await supabase
        .from('projects')
        .select('''
      id, title, description, budget_min, budget_max,
      skills, duration, status, created_at, client_id,
      profiles!inner(name, location)
    ''')
        .eq('status', 'open')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  } catch (e) {
    throw Exception('Failed to load projects: $e');
  }
});

/// Notifier for the active skill filter chip. Default: 'All'
class SkillFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void select(String skill) => state = skill;
}

final selectedSkillFilterProvider =
NotifierProvider<SkillFilterNotifier, String>(SkillFilterNotifier.new);