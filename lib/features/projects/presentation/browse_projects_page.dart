// lib/features/projects/presentation/browse_projects_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'browse_projects_provider.dart';

class BrowseProjectsPage extends ConsumerStatefulWidget {
  const BrowseProjectsPage({super.key});

  @override
  ConsumerState<BrowseProjectsPage> createState() =>
      _BrowseProjectsPageState();
}

class _BrowseProjectsPageState extends ConsumerState<BrowseProjectsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterSheet(ref: ref),
    );
  }

  PopupMenuItem<SortOption> _sortItem(
      SortOption value,
      String label,
      IconData icon,
      SortOption current,
      ) {
    final isActive = value == current;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final projectsAsync = ref.watch(browseProjectsProvider);
    final selectedSkill = ref.watch(selectedSkillFilterProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final sortOption = ref.watch(sortOptionProvider);
    final filters = ref.watch(filterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: projectsAsync.when(
        loading: () => _SkeletonLoader(),
        error: (e, _) => _ErrorState(
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(browseProjectsProvider),
        ),
        data: (projects) {
          // Build skill list
          final allSkills = <String>{};
          for (final p in projects) {
            final skills = p['skills'] as List? ?? [];
            allSkills.addAll(skills.map((s) => s.toString()));
          }
          final filterChips = ['All', ...allSkills.toList()..sort()];

          // Apply filters
          var filtered = projects.where((p) {
            if (filters.status != 'all') {
              if ((p['status'] as String? ?? 'open') != filters.status) {
                return false;
              }
            }
            if (selectedSkill != 'All') {
              final skills = (p['skills'] as List? ?? [])
                  .map((s) => s.toString())
                  .toList();
              if (!skills.contains(selectedSkill)) return false;
            }
            final bMin = (p['budget_min'] as num?)?.toDouble() ?? 0;
            final bMax = (p['budget_max'] as num?)?.toDouble() ?? 5000;
            if (bMax < filters.budgetMin || bMin > filters.budgetMax) {
              return false;
            }
            if (filters.duration != 'any') {
              if ((p['duration'] as String? ?? '') != filters.duration) {
                return false;
              }
            }
            if (searchQuery.trim().isNotEmpty) {
              final q = searchQuery.trim().toLowerCase();
              final title = (p['title'] as String? ?? '').toLowerCase();
              final desc = (p['description'] as String? ?? '').toLowerCase();
              final skillStr = ((p['skills'] as List? ?? [])
                  .map((s) => s.toString())
                  .join(' '))
                  .toLowerCase();
              final category = (p['category'] as String? ?? '').toLowerCase();
              if (!title.contains(q) &&
                  !desc.contains(q) &&
                  !skillStr.contains(q) &&
                  !category.contains(q)) {
                return false;
              }
            }
            return true;
          }).toList();

          // Sort
          switch (sortOption) {
            case SortOption.newest:
              filtered.sort((a, b) {
                final aD = DateTime.tryParse(
                    a['created_at'] as String? ?? '') ??
                    DateTime(0);
                final bD = DateTime.tryParse(
                    b['created_at'] as String? ?? '') ??
                    DateTime(0);
                return bD.compareTo(aD);
              });
            case SortOption.budgetHigh:
              filtered.sort((a, b) {
                final aV = (a['budget_max'] as num?)?.toDouble() ?? 0;
                final bV = (b['budget_max'] as num?)?.toDouble() ?? 0;
                return bV.compareTo(aV);
              });
            case SortOption.budgetLow:
              filtered.sort((a, b) {
                final aV = (a['budget_min'] as num?)?.toDouble() ??
                    double.infinity;
                final bV = (b['budget_min'] as num?)?.toDouble() ??
                    double.infinity;
                return aV.compareTo(bV);
              });
          }

          int activeFilters = 0;
          if (selectedSkill != 'All') activeFilters++;
          if (searchQuery.trim().isNotEmpty) activeFilters++;
          if (sortOption != SortOption.newest) activeFilters++;
          if (!filters.isDefault) activeFilters++;

          void clearAll() {
            ref.read(selectedSkillFilterProvider.notifier).select('All');
            ref.read(searchQueryProvider.notifier).clear();
            ref.read(sortOptionProvider.notifier).select(SortOption.newest);
            ref.read(filterProvider.notifier).reset();
            _searchController.clear();
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(browseProjectsProvider),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [

                // ── Gradient Header ──────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF00A19B), Color(0xFF007B76)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.of(context).padding.top + 16,
                      20,
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (context.canPop())
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                  Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            if (context.canPop()) const SizedBox(width: 12),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Browse Projects',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Find your next opportunity',
                                    style: TextStyle(
                                      color: Color(0xFFB2DFDB),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Sort button
                            PopupMenuButton<SortOption>(
                              tooltip: 'Sort',
                              offset: const Offset(0, 52),
                              onSelected: (o) => ref
                                  .read(sortOptionProvider.notifier)
                                  .select(o),
                              itemBuilder: (context) => [
                                _sortItem(SortOption.newest, 'Newest First',
                                    Icons.access_time, sortOption),
                                _sortItem(SortOption.budgetHigh,
                                    'Budget: High → Low', Icons.arrow_upward,
                                    sortOption),
                                _sortItem(SortOption.budgetLow,
                                    'Budget: Low → High',
                                    Icons.arrow_downward, sortOption),
                              ],
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: sortOption != SortOption.newest
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.sort_rounded,
                                  color: sortOption != SortOption.newest
                                      ? AppColors.primary
                                      : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Filter button
                            GestureDetector(
                              onTap: _openFilters,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: !filters.isDefault
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      color: !filters.isDefault
                                          ? AppColors.primary
                                          : Colors.white,
                                      size: 20,
                                    ),
                                    if (!filters.isDefault)
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFFF5252),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Search bar inside header
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => ref
                                .read(searchQueryProvider.notifier)
                                .update(val),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search title, skill, category...',
                              hintStyle: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                              prefixIcon: const Icon(
                                Icons.search_rounded,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              suffixIcon: searchQuery.isNotEmpty
                                  ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  ref
                                      .read(searchQueryProvider.notifier)
                                      .clear();
                                },
                                child: const Icon(Icons.close_rounded,
                                    color: AppColors.textSecondary,
                                    size: 18),
                              )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Skill chips ──────────────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      itemCount: filterChips.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final chip = filterChips[index];
                        final isSelected = chip == selectedSkill;
                        return GestureDetector(
                          onTap: () => ref
                              .read(selectedSkillFilterProvider.notifier)
                              .select(chip),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.shadow,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                                  : [],
                            ),
                            child: Text(
                              chip,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // ── Result count + Clear ─────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(
                      children: [
                        Text(
                          '${filtered.length} project${filtered.length == 1 ? '' : 's'} found',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        if (activeFilters > 0)
                          GestureDetector(
                            onTap: clearAll,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.filter_alt_off_rounded,
                                      size: 13,
                                      color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Clear ($activeFilters)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Empty state ──────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_outlined,
                              size: 52,
                              color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'No results for "$searchQuery"'
                                : 'No projects match your filters.',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (activeFilters > 0) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: clearAll,
                              child: const Text('Clear all filters'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                // ── Project cards ────────────────────────────
                if (filtered.isNotEmpty)
                  SliverPadding(
                    padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: 12),
                      itemBuilder: (context, index) => ProjectCard(
                        project: filtered[index],
                        onTap: () => context.push(
                          '/projects/${filtered[index]['id']}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Skeleton Loader
// ─────────────────────────────────────────────────────────────
class _SkeletonLoader extends StatefulWidget {
  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bone(double w, double h, {double radius = 10}) =>
      AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Opacity(
          opacity: _anim.value,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: AppColors.shadow,
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Fake header
          Container(
            height: 160,
            decoration: const BoxDecoration(
              color: Color(0xFF00A19B),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: List.generate(
                4,
                    (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            _bone(200, 16),
                            _bone(40, 12),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _bone(double.infinity, 12),
                        const SizedBox(height: 6),
                        _bone(240, 12),
                        const SizedBox(height: 12),
                        Row(children: [
                          _bone(80, 28, radius: 20),
                          const SizedBox(width: 8),
                          _bone(80, 28, radius: 20),
                        ]),
                        const SizedBox(height: 10),
                        Row(children: [
                          _bone(60, 24, radius: 20),
                          const SizedBox(width: 6),
                          _bone(80, 24, radius: 20),
                          const SizedBox(width: 6),
                          _bone(70, 24, radius: 20),
                        ]),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Error State
// ─────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 52, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
              'Could not load projects',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Filter Bottom Sheet
// ─────────────────────────────────────────────────────────────
class _FilterSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _FilterSheet({required this.ref});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late String _status;
  late RangeValues _budget;
  late String _duration;

  @override
  void initState() {
    super.initState();
    final f = ref.read(filterProvider);
    _status = f.status;
    _budget = RangeValues(f.budgetMin, f.budgetMax);
    _duration = f.duration;
  }

  void _apply() {
    ref.read(filterProvider.notifier)
      ..setStatus(_status)
      ..setBudgetRange(_budget.start, _budget.end)
      ..setDuration(_duration);
    Navigator.pop(context);
  }

  void _reset() {
    setState(() {
      _status = 'open';
      _budget = const RangeValues(0, 5000);
      _duration = 'any';
    });
    ref.read(filterProvider.notifier).reset();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.shadow,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _reset,
                  child: const Text('Reset',
                      style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
            const Divider(color: AppColors.shadow),
            const SizedBox(height: 12),

            // Status
            const Text('Status',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Row(
              children: ['open', 'all', 'closed'].map((s) {
                final label = s == 'all'
                    ? 'All'
                    : s[0].toUpperCase() + s.substring(1);
                final isSelected = _status == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.shadow,
                        ),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Budget
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Budget Range',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Text(
                  '\$${_budget.start.toInt()} – \$${_budget.end.toInt()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _budget,
              min: 0,
              max: 5000,
              divisions: 50,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.primaryLight,
              onChanged: (v) => setState(() => _budget = v),
            ),
            const SizedBox(height: 24),

            // Duration
            const Text('Duration',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const {
                'any': 'Any',
                'less_1_month': '< 1 Month',
                '1_3_months': '1–3 Months',
                '3_6_months': '3–6 Months',
                'more_6_months': '6+ Months',
              }.entries.map((e) {
                final isSelected = _duration == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _duration = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.shadow,
                      ),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _apply,
                child: const Text('Apply Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Project Card — upgraded
// ─────────────────────────────────────────────────────────────
class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
  });

  String _formatBudget() {
    final min = project['budget_min'];
    final max = project['budget_max'];
    if (min == null && max == null) return 'Negotiable';
    if (min != null && max != null) return '\$$min – \$$max';
    if (min != null) return 'From \$$min';
    return 'Up to \$$max';
  }

  String _formatDuration(String? raw) {
    switch (raw) {
      case 'less_1_month': return '< 1 month';
      case '1_3_months':   return '1–3 months';
      case '3_6_months':   return '3–6 months';
      case 'more_6_months': return '6+ months';
      default: return raw ?? '';
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final skills = (project['skills'] as List? ?? [])
        .map((s) => s.toString())
        .toList();
    final profile = project['profiles'] as Map?;
    final clientName =
        profile?['name'] ?? profile?['company'] ?? 'Client';
    final clientLocation = profile?['location'] as String?;
    final duration = _formatDuration(project['duration'] as String?);
    final category = project['category'] as String?;

    // Proposal count from aggregation
    final proposalsList = project['proposals'] as List?;
    final proposalCount = proposalsList?.isNotEmpty == true
        ? (proposalsList!.first['count'] as int? ?? 0)
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top accent bar
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00A19B), Color(0xFF007B76)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge + time
                  Row(
                    children: [
                      if (category != null && category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        _timeAgo(project['created_at'] as String?),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    project['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Description
                  Text(
                    project['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Budget + Duration chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _InfoChip(
                        icon: Icons.attach_money_rounded,
                        label: _formatBudget(),
                        color: AppColors.primaryLight,
                        textColor: AppColors.primary,
                      ),
                      if (duration.isNotEmpty)
                        _InfoChip(
                          icon: Icons.schedule_outlined,
                          label: duration,
                          color: AppColors.background,
                          textColor: AppColors.textSecondary,
                        ),
                      if (proposalCount > 0)
                        _InfoChip(
                          icon: Icons.people_outline_rounded,
                          label: '$proposalCount proposal${proposalCount == 1 ? '' : 's'}',
                          color: const Color(0xFFFFF3E0),
                          textColor: const Color(0xFFE65100),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Skill tags
                  if (skills.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skills
                          .take(4)
                          .map(
                            (skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppColors.shadow),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                          .toList(),
                    ),

                  const SizedBox(height: 12),
                  const Divider(color: AppColors.shadow, height: 1),
                  const SizedBox(height: 10),

                  // Client info
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.person_outline_rounded,
                            color: AppColors.primary, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (clientLocation != null &&
                          clientLocation.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.location_on_outlined,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          clientLocation,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 12, color: AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Info Chip
// ─────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}