// lib/features/projects/presentation/client_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../profiles/presentation/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import 'home_header.dart';

// Client dashboard counts in a single aggregate RPC (open projects, proposals
// received, completed projects) — replaces three row-fetching providers.
typedef ClientCounts = ({int open, int proposals, int completed});

final clientDashboardCountsProvider = FutureProvider<ClientCounts>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return (open: 0, proposals: 0, completed: 0);
  try {
    final rows = await supabase.rpc('client_dashboard_counts');
    final list = rows as List;
    final row = list.isNotEmpty ? list.first as Map : const {};
    return (
      open: (row['open_projects'] as int?) ?? 0,
      proposals: (row['proposals_received'] as int?) ?? 0,
      completed: (row['completed_projects'] as int?) ?? 0,
    );
  } catch (_) {
    return (open: 0, proposals: 0, completed: 0);
  }
});

// ─────────────────────────────────────────────────────────────
// Client Home Page — mirrors the freelancer home layout:
// shared hero header (drag-down to profile), an Overview stats
// section below, and tips.
// ─────────────────────────────────────────────────────────────
class ClientHomePage extends ConsumerStatefulWidget {
  const ClientHomePage({super.key});

  @override
  ConsumerState<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends ConsumerState<ClientHomePage> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final countsAsync = ref.watch(clientDashboardCountsProvider);

    final name = profileAsync.asData?.value?['name'] as String? ?? '';
    final avatarUrl = profileAsync.asData?.value?['avatar_url'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(clientDashboardCountsProvider);
          ref.invalidate(profileProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero Header (drag-down to open profile) ──
            SliverToBoxAdapter(
              child: HomeHeader(
                name: name,
                avatarUrl: avatarUrl,
                fallbackName: 'there',
                onProfileOpen: () => context.push('/profile/me'),
              ),
            ),

            // ── Body ───────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 24),

                  // ── Overview stats ──────────────────
                  _OverviewSection(counts: countsAsync),

                  const SizedBox(height: 28),

                  // ── Tips ────────────────────────────
                  Text(
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
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Overview stats section (below the header, like freelancer home)
// ─────────────────────────────────────────────────────────────
class _OverviewSection extends StatelessWidget {
  final AsyncValue<ClientCounts> counts;

  const _OverviewSection({required this.counts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            children: [
              _StatTile(
                valueAsync: counts.whenData((c) => c.open),
                label: 'Open',
                icon: Icons.work_outline,
                iconColor: const Color(0xFF00A19B),
                bgColor: const Color(0xFFE0F7F5),
              ),
              const SizedBox(width: 10),
              _StatTile(
                valueAsync: counts.whenData((c) => c.proposals),
                label: 'Proposals',
                icon: Icons.inbox_outlined,
                iconColor: const Color(0xFF1565C0),
                bgColor: const Color(0xFFE3F2FD),
              ),
              const SizedBox(width: 10),
              _StatTile(
                valueAsync: counts.whenData((c) => c.completed),
                label: 'Done',
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final AsyncValue<int> valueAsync;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatTile({
    required this.valueAsync,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: 12),
            valueAsync.when(
              loading: () => Text(
                '…',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              error: (_, _) => Text(
                '0',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              data: (v) => Text(
                '$v',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
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
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(body,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
