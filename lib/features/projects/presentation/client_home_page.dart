// lib/features/projects/presentation/client_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../profiles/presentation/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

// ── Open projects count ──────────────────────────────────────
final clientProjectsCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return 0;
  try {
    final data = await supabase
        .from('projects')
        .select('id')
        .eq('client_id', userId)
        .eq('status', 'open');
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

// ── Proposals received count (across all client's projects) ──
final clientProposalsCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return 0;
  try {
    final projects = await supabase
        .from('projects')
        .select('id')
        .eq('client_id', userId);

    final projectIds = (projects as List)
        .map((p) => p['id'] as String)
        .toList();

    if (projectIds.isEmpty) return 0;

    final proposals = await supabase
        .from('proposals')
        .select('id')
        .inFilter('project_id', projectIds);

    return (proposals as List).length;
  } catch (_) {
    return 0;
  }
});

// ── Completed projects count ─────────────────────────────────
// BUG 3 FIX: was previously querying status = 'closed'.
// acceptProposal sets status → 'closed' (in-progress).
// completeProject sets status → 'completed' (done).
// This provider must query 'completed', not 'closed'.
final clientCompletedCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return 0;
  try {
    final data = await supabase
        .from('projects')
        .select('id')
        .eq('client_id', userId)
        .eq('status', 'completed'); // ← was 'closed' — fixed
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

// ─────────────────────────────────────────────────────────────
// Client Home Page
// BUG 3 FIX: Changed to ConsumerStatefulWidget so we can
// invalidate dashboard providers when we pop back from
// ClientProjectsPage or ViewProposalsPage.
// ─────────────────────────────────────────────────────────────
class ClientHomePage extends ConsumerStatefulWidget {
  const ClientHomePage({super.key});

  @override
  ConsumerState<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends ConsumerState<ClientHomePage> {
  // BUG 3 FIX: push helper that invalidates dashboard counts on pop
  Future<void> _pushAndRefresh(String route) async {
    await context.push(route);
    if (!mounted) return;
    ref.invalidate(clientProjectsCountProvider);
    ref.invalidate(clientProposalsCountProvider);
    ref.invalidate(clientCompletedCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final openCountAsync = ref.watch(clientProjectsCountProvider);
    final proposalsCountAsync = ref.watch(clientProposalsCountProvider);
    final completedCountAsync = ref.watch(clientCompletedCountProvider);

    final name = profileAsync.asData?.value?['name'] ?? 'there';
    final firstName = name.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(clientProjectsCountProvider);
          ref.invalidate(clientProposalsCountProvider);
          ref.invalidate(clientCompletedCountProvider);
          ref.invalidate(profileProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, Color(0xFF007A75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 20,
                    20,
                    28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $firstName 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Manage your projects & proposals',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: AppColors.surface,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                                title: const Text('Sign Out',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary)),
                                content: const Text(
                                    'Are you sure you want to sign out?',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancel',
                                        style: TextStyle(
                                            color: AppColors.textSecondary)),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFFD94F4F)),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Sign Out'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              await ref
                                  .read(authNotifierProvider.notifier)
                                  .logout();
                            }
                          },
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white70),
                          tooltip: 'Sign out',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Stats row ─────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Open Projects',
                            valueAsync: openCountAsync,
                            icon: Icons.work_outline,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Proposals',
                            valueAsync: proposalsCountAsync,
                            icon: Icons.inbox_outlined,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            label: 'Completed',
                            valueAsync: completedCountAsync,
                            icon: Icons.check_circle_outline,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Quick Actions ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.add_circle_outline,
                            label: 'Post a Project',
                            subtitle: 'Find talented freelancers',
                            onTap: () =>
                                _pushAndRefresh('/projects/post'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.folder_open_outlined,
                            label: 'My Projects',
                            subtitle: 'View & manage posts',
                            // BUG 3 FIX: navigate with refresh so counts
                            // update after returning from manage actions
                            onTap: () =>
                                _pushAndRefresh('/client/projects'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Tips section ────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tips for Success',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _TipCard(
                      icon: Icons.lightbulb_outline,
                      title: 'Write clear descriptions',
                      body:
                      'Projects with detailed descriptions receive 3× more quality proposals.',
                    ),
                    const SizedBox(height: 10),
                    _TipCard(
                      icon: Icons.people_outline,
                      title: 'Review profiles carefully',
                      body:
                      'Check experience, skills, and past work before accepting a proposal.',
                    ),
                    const SizedBox(height: 10),
                    _TipCard(
                      icon: Icons.star_outline,
                      title: 'Set a realistic budget',
                      body:
                      'Competitive budgets attract top freelancers faster.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stat Card (header pill inside gradient)
// ─────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final AsyncValue<int> valueAsync;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.valueAsync,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 6),
          valueAsync.when(
            loading: () => const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            ),
            error: (_, _) => const Text('–',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            data: (v) => Text(
              '$v',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Action Card
// ─────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tip Card
// ─────────────────────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
