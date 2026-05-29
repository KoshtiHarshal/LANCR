// lib/features/projects/presentation/freelancer_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../profiles/presentation/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'freelancer_home_provider.dart';

class FreelancerHomePage extends ConsumerWidget {
  const FreelancerHomePage({super.key});

  String _formatDuration(String? raw) {
    switch (raw) {
      case 'less_1_month':  return '< 1 month';
      case '1_3_months':    return '1–3 months';
      case '3_6_months':    return '3–6 months';
      case 'more_6_months': return '6+ months';
      default:              return raw ?? '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user           = ref.watch(authProvider).value;
    final profileAsync   = ref.watch(profileProvider);
    final activeAsync    = ref.watch(activeProjectsProvider);
    final statsAsync     = ref.watch(proposalStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lancr'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {},
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person_outline,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(activeProjectsProvider);
          ref.invalidate(proposalStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Hero Greeting Card ──────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${user?.email ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          profileAsync.when(
                            data: (profile) {
                              final headline = profile?['headline'];
                              return Text(
                                (headline != null &&
                                    headline.toString().isNotEmpty)
                                    ? headline
                                    : 'Add a headline to stand out →',
                                style: const TextStyle(
                                    color: Color(0xFFCCEEEC),
                                    fontSize: 13),
                              );
                            },
                            loading: () => const Text('Loading...',
                                style: TextStyle(
                                    color: Color(0xFFCCEEEC),
                                    fontSize: 13)),
                            error: (e, _) => const Text(
                                'Add a headline to stand out →',
                                style: TextStyle(
                                    color: Color(0xFFCCEEEC),
                                    fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Overview Stats ───────────────────────────
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                loading: () => Row(children: [
                  StatCard(icon: Icons.work_outline,     value: '…', label: 'Active\nProjects'),
                  const SizedBox(width: 8),
                  StatCard(icon: Icons.send_outlined,    value: '…', label: 'Proposals\nSent'),
                  const SizedBox(width: 8),
                  StatCard(icon: Icons.account_balance_wallet_outlined, value: '\$0', label: 'Earnings'),
                ]),
                error: (_, __) => Row(children: [
                  StatCard(icon: Icons.work_outline,     value: '0', label: 'Active\nProjects'),
                  const SizedBox(width: 8),
                  StatCard(icon: Icons.send_outlined,    value: '0', label: 'Proposals\nSent'),
                  const SizedBox(width: 8),
                  StatCard(icon: Icons.account_balance_wallet_outlined, value: '\$0', label: 'Earnings'),
                ]),
                data: (stats) => Row(children: [
                  StatCard(icon: Icons.work_outline,     value: '${stats.active}', label: 'Active\nProjects'),
                  const SizedBox(width: 8),
                  StatCard(icon: Icons.send_outlined,    value: '${stats.total}',  label: 'Proposals\nSent'),
                  const SizedBox(width: 8),
                  StatCard(icon: Icons.account_balance_wallet_outlined, value: '\$0', label: 'Earnings'),
                ]),
              ),

              const SizedBox(height: 24),

              // ── Quick Actions ────────────────────────────
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/projects/browse'),
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Browse Projects'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/profile/edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Update Profile'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Active Projects ──────────────────────────
              Row(
                children: [
                  const Text(
                    'Active Projects',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  activeAsync.maybeWhen(
                    data: (list) => list.isNotEmpty
                        ? GestureDetector(
                      onTap: () => context.push('/proposals'),
                      child: const Text(
                        'View all →',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              activeAsync.when(
                loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    )),
                error: (e, _) => _EmptyProjectsCard(
                    onBrowse: () => context.push('/projects/browse')),
                data: (activeList) {
                  if (activeList.isEmpty) {
                    return _EmptyProjectsCard(
                        onBrowse: () =>
                            context.push('/projects/browse'));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeList.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item    = activeList[index];
                      final project = item['projects'] as Map?;
                      final title   = project?['title'] ?? 'Project';
                      final bid     = item['bid_amount'];
                      final projId  = project?['id'] as String?;
                      final duration =
                      _formatDuration(project?['duration'] as String?);
                      final budgetMin = project?['budget_min'];
                      final budgetMax = project?['budget_max'];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Hired badge + title
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32)
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle,
                                          size: 11,
                                          color: Color(0xFF2E7D32)),
                                      SizedBox(width: 4),
                                      Text(
                                        'HIRED',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Budget + bid + duration
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (budgetMin != null || budgetMax != null)
                                  _SmallChip(
                                    label:
                                    'Budget: \$$budgetMin–\$$budgetMax',
                                    color: AppColors.textSecondary,
                                    bgColor: AppColors.background,
                                  ),
                                _SmallChip(
                                  label: 'Your bid: \$$bid',
                                  color: AppColors.primary,
                                  bgColor: AppColors.primaryLight,
                                ),
                                if (duration.isNotEmpty)
                                  _SmallChip(
                                    label: duration,
                                    color: AppColors.textSecondary,
                                    bgColor: AppColors.background,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // View Project button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: projId != null
                                    ? () => context
                                    .push('/projects/$projId')
                                    : null,
                                icon: const Icon(
                                    Icons.arrow_forward, size: 16),
                                label:
                                const Text('View Project'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // ── Sign out ─────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(authNotifierProvider.notifier)
                        .logout();
                    if (context.mounted) context.go('/auth/login');
                  },
                  icon: const Icon(Icons.logout,
                      size: 18, color: AppColors.textSecondary),
                  label: const Text(
                    'Sign out',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.shadow)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty Active Projects Card
// ─────────────────────────────────────────────────────────────
class _EmptyProjectsCard extends StatelessWidget {
  final VoidCallback onBrowse;
  const _EmptyProjectsCard({required this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(Icons.notifications_outlined,
                  color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'No active projects yet. Submit proposals to get hired.',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Small Chip
// ─────────────────────────────────────────────────────────────
class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _SmallChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat Card
// ─────────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const StatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}