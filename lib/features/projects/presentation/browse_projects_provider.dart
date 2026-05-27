// lib/features/projects/presentation/browse_projects_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

// ── Raw data ──────────────────────────────────────────────────
final browseProjectsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final data = await supabase
        .from('projects')
        .select(
      'id, title, description, budget_min, budget_max, '
          'skills, duration, status, created_at, client_id',
    )
        .order('created_at', ascending: false);
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

// ── Filter state (status + budget range + duration) ───────────
@immutable
class FilterState {
  final String status;        // 'all' | 'open' | 'closed'
  final double budgetMin;
  final double budgetMax;
  final String duration;      // 'any' | 'less_1_month' | '1_3_months' | '3_6_months' | 'more_6_months'

  const FilterState({
    this.status = 'open',
    this.budgetMin = 0,
    this.budgetMax = 5000,
    this.duration = 'any',
  });

  FilterState copyWith({
    String? status,
    double? budgetMin,
    double? budgetMax,
    String? duration,
  }) =>
      FilterState(
        status: status ?? this.status,
        budgetMin: budgetMin ?? this.budgetMin,
        budgetMax: budgetMax ?? this.budgetMax,
        duration: duration ?? this.duration,
      );

  bool get isDefault =>
      status == 'open' &&
          budgetMin == 0 &&
          budgetMax == 5000 &&
          duration == 'any';
}

class FilterNotifier extends Notifier<FilterState> {
  @override
  FilterState build() => const FilterState();

  void setStatus(String s)       => state = state.copyWith(status: s);
  void setBudgetMin(double v)    => state = state.copyWith(budgetMin: v);
  void setBudgetMax(double v)    => state = state.copyWith(budgetMax: v);
  void setBudgetRange(double mn, double mx) =>
      state = state.copyWith(budgetMin: mn, budgetMax: mx);
  void setDuration(String d)     => state = state.copyWith(duration: d);
  void reset()                   => state = const FilterState();
}

final filterProvider =
NotifierProvider<FilterNotifier, FilterState>(FilterNotifier.new);