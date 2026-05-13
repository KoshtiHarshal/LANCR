// lib/features/projects/presentation/browse_projects_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'browse_projects_provider.dart';

class BrowseProjectsPage extends ConsumerWidget {
  const BrowseProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(browseProjectsProvider);
    final selectedSkill = ref.watch(selectedSkillFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Browse Projects'),
      ),
      body: projectsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, st) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              const Text(
                'Could not load projects',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(browseProjectsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (projects) {
          // Build unique sorted skill list from all fetched projects
          final allSkills = <String>{};
          for (final p in projects) {
            final skills = p['skills'] as List? ?? [];
            allSkills.addAll(skills.map((s) => s.toString()));
          }
          final filterChips = ['All', ...allSkills.toList()..sort()];

          // Apply the active skill filter
          final filtered = selectedSkill == 'All'
              ? projects
              : projects.where((p) {
            final skills = (p['skills'] as List? ?? [])
                .map((s) => s.toString())
                .toList();
            return skills.contains(selectedSkill);
          }).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(browseProjectsProvider),
            child: CustomScrollView(
              slivers: [

                // ── Skill Filter Chips ─────────────────────
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      itemCount: filterChips.length,
                      separatorBuilder: (context, index) =>
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
                              horizontal: 14,
                              vertical: 6,
                            ),
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
                              chip,
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
                      },
                    ),
                  ),
                ),

                // ── Project count label ────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(
                      '${filtered.length} project${filtered.length == 1 ? '' : 's'} found',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                // ── Empty state ────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_outlined,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            selectedSkill == 'All'
                                ? 'No projects posted yet.'
                                : 'No projects require "$selectedSkill".',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Project Cards ──────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return ProjectCard(
                        project: filtered[index],
                        onTap: () => context.push(
                          '/projects/${filtered[index]['id']}',
                        ),
                      );
                    },
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

// ── Project Card ─────────────────────────────────────────
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
      case 'less_1_month':
        return '< 1 month';
      case '1_3_months':
        return '1–3 months';
      case '3_6_months':
        return '3–6 months';
      case 'more_6_months':
        return '6+ months';
      default:
        return raw ?? '';
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
    final profile = project['profiles'] as Map<String, dynamic>?;
    final clientName =
        profile?['name'] ?? profile?['company'] ?? 'Client';
    final clientLocation = profile?['location'] as String?;
    final duration = _formatDuration(project['duration'] as String?);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.shadow),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Title + time ago ───────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    project['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _timeAgo(project['created_at'] as String?),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // ── Description preview ────────────────────
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

            // ── Budget + Duration chips ────────────────
            Row(
              children: [
                _InfoChip(
                  icon: Icons.attach_money,
                  label: _formatBudget(),
                  color: AppColors.primaryLight,
                  textColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                if (duration.isNotEmpty)
                  _InfoChip(
                    icon: Icons.schedule_outlined,
                    label: duration,
                    color: AppColors.background,
                    textColor: AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Skill tags ─────────────────────────────
            if (skills.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills
                    .take(4)
                    .map(
                      (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.shadow),
                    ),
                    child: Text(
                      skill,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
                    .toList(),
              ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.shadow, height: 1),
            const SizedBox(height: 10),

            // ── Client info ────────────────────────────
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    Icons.person_outline,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  clientName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (clientLocation != null &&
                    clientLocation.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.location_on_outlined,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    clientLocation,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Chip ─────────────────────────────────────────────
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