// lib/features/projects/presentation/browse_projects_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

/// Canonical project categories (shared by post form, browse filter, cards).
const kProjectCategories = <String>[
  'Web Development',
  'Mobile Development',
  'Design & Creative',
  'Writing & Translation',
  'Marketing & Sales',
  'Video & Animation',
  'Data & Analytics',
  'Admin & Support',
  'Other',
];

// ── Raw data ──────────────────────────────────────────────────
final browseProjectsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final data = await supabase
        .from('projects')
        .select(
      'id, title, description, budget_min, budget_max, '
          'skills, duration, status, category, created_at, client_id, '
          'profiles!client_id(name, company, location), '
          'proposals(count)',
    )
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(data as List);
  } catch (e) {
    throw Exception('Failed to load projects: $e');
  }
});

// ── Skill filter ──────────────────────────────────────────────
class SkillFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';
  void select(String skill) => state = skill;
}

final selectedSkillFilterProvider =
NotifierProvider<SkillFilterNotifier, String>(SkillFilterNotifier.new);

// ── Search query ──────────────────────────────────────────────
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String q) => state = q;
  void clear() => state = '';
}

final searchQueryProvider =
NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// ── Sort ──────────────────────────────────────────────────────
enum SortOption { newest, budgetHigh, budgetLow }

class SortNotifier extends Notifier<SortOption> {
  @override
  SortOption build() => SortOption.newest;
  void select(SortOption o) => state = o;
}

final sortOptionProvider =
NotifierProvider<SortNotifier, SortOption>(SortNotifier.new);

// ── Filter state ──────────────────────────────────────────────
@immutable
class FilterState {
  final String status;
  final double budgetMin;
  final double budgetMax;
  final String duration;
  final String category; // 'any' or a value from kProjectCategories

  const FilterState({
    this.status = 'open',
    this.budgetMin = 0,
    this.budgetMax = 5000,
    this.duration = 'any',
    this.category = 'any',
  });

  FilterState copyWith({
    String? status,
    double? budgetMin,
    double? budgetMax,
    String? duration,
    String? category,
  }) =>
      FilterState(
        status: status ?? this.status,
        budgetMin: budgetMin ?? this.budgetMin,
        budgetMax: budgetMax ?? this.budgetMax,
        duration: duration ?? this.duration,
        category: category ?? this.category,
      );

  bool get isDefault =>
      status == 'open' &&
          budgetMin == 0 &&
          budgetMax == 5000 &&
          duration == 'any' &&
          category == 'any';
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setStatus(String s) => state = state.copyWith(status: s);
  void setBudgetRange(double mn, double mx) =>
      state = state.copyWith(budgetMin: mn, budgetMax: mx);
  void setDuration(String d) => state = state.copyWith(duration: d);
  void setCategory(String c) => state = state.copyWith(category: c);
  void reset() => state = const FilterState();
}

final filterProvider =
NotifierProvider<FilterNotifier, FilterState>(FilterNotifier.new);