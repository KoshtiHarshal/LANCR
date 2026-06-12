// lib/features/projects/presentation/freelancer_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      default: return raw ?? '';
    }
  }

  // ── Navigate to real profile page with slide-up transition ──
  void _openProfile(BuildContext context) {
    context.push('/profile/me');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final activeAsync  = ref.watch(activeProjectsProvider);
    final statsAsync   = ref.watch(proposalStatsProvider);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(activeProjectsProvider);
          ref.invalidate(proposalStatsProvider);
          ref.invalidate(profileProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── Hero Header ────────────────────────────
            SliverToBoxAdapter(
              child: profileAsync.when(
                loading: () => _HeroHeader(
                  name: '',
                  onProfileOpen: () => _openProfile(context),
                ),
                error: (_, _) => _HeroHeader(
                  name: '',
                  onProfileOpen: () => _openProfile(context),
                ),
                data: (profile) => _HeroHeader(
                  name: profile?['name'] ?? '',
                  onProfileOpen: () => _openProfile(context),
                ),
              ),
            ),

            // ── Body ───────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  const SizedBox(height: 24),

                  // ── Stats ──────────────────────────
                  statsAsync.when(
                    loading: () => const _StatsSection(
                        active: '…', completed: '…', earnings: '…'),
                    error: (_, _) => const _StatsSection(
                        active: '0', completed: '0', earnings: '\$0'),
                    data: (s) => _StatsSection(
                      active: '${s.active}',
                      completed: '${s.completed}',
                      earnings: '\$${s.earnings.toStringAsFixed(0)}',
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Active Projects ────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const _SectionHeader(title: 'Active Projects'),
                      const Spacer(),
                      activeAsync.maybeWhen(
                        data: (list) => list.isNotEmpty
                            ? GestureDetector(
                          onTap: () => context.push('/proposals'),
                          child: const Text(
                            'See all →',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(
                            color: AppColors.primary),
                      ),
                    ),
                    error: (_, _) => _EmptyState(
                        onTap: () => context.push('/projects/browse')),
                    data: (list) {
                      if (list.isEmpty) {
                        return _EmptyState(
                            onTap: () => context.push('/projects/browse'));
                      }
                      return Column(
                        children: list.map((item) {
                          final project   = item['projects'] as Map?;
                          final title     = project?['title'] ?? 'Project';
                          final bid       = item['bid_amount'];
                          final projId    = project?['id'] as String?;
                          final duration  = _formatDuration(
                              project?['duration'] as String?);
                          final budgetMin = project?['budget_min'];
                          final budgetMax = project?['budget_max'];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActiveProjectCard(
                              title: title,
                              bid: bid,
                              projId: projId,
                              duration: duration,
                              budgetMin: budgetMin,
                              budgetMax: budgetMax,
                              onTap: projId != null
                                  ? () => context.push('/projects/$projId')
                                  : null,
                            ),
                          );
                        }).toList(),
                      );
                    },
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
// Hero Header — compact, drag-down to navigate
// No headline, no hint pill, smaller avatar
// ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatefulWidget {
  final String name;
  final VoidCallback onProfileOpen;
  const _HeroHeader({
    required this.name,
    required this.onProfileOpen,
  });

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnim;

  bool _dragging = false;
  double _dragStartY = 0;
  double _dragProgress = 0; // 0.0 → 1.0 as user drags down 60px

  @override
  void initState() {
    super.initState();
    // Subtle bounce on avatar to hint tappability
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning ☀️';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final initial =
    widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';

    // Interpolate header shadow/glow as user drags
    final glowOpacity = (0.2 + _dragProgress * 0.3).clamp(0.0, 0.5);
    final gradientDark = _dragging;

    return GestureDetector(
      onVerticalDragStart: (d) {
        _dragStartY = d.globalPosition.dy;
        setState(() {
          _dragging = true;
          _dragProgress = 0;
        });
      },
      onVerticalDragUpdate: (d) {
        final delta = d.globalPosition.dy - _dragStartY;
        if (delta > 0) {
          setState(() {
            _dragProgress = (delta / 60).clamp(0.0, 1.0);
          });
        }
      },
      onVerticalDragEnd: (d) {
        final totalDelta = d.globalPosition.dy - _dragStartY;
        setState(() {
          _dragging = false;
          _dragProgress = 0;
        });
        if (totalDelta >= 30) {
          widget.onProfileOpen();
        }
      },
      onVerticalDragCancel: () {
        setState(() {
          _dragging = false;
          _dragProgress = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
            20, MediaQuery.of(context).padding.top + 14, 20, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientDark
                ? [const Color(0xFF007B76), const Color(0xFF005F5B)]
                : [const Color(0xFF00A19B), const Color(0xFF007B76)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00A19B).withValues(alpha: glowOpacity),
              blurRadius: 16 + _dragProgress * 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            // ── LEFT: Logo + greeting ──────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lancr',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      color: Color(0xFFB2DFDB),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // ── RIGHT: Avatar + name (tap or drag to profile) ─
            GestureDetector(
              onTap: widget.onProfileOpen,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.name.isNotEmpty ? widget.name : 'Freelancer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Subtle "tap" hint
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'My profile',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Avatar — bounces subtly
                  AnimatedBuilder(
                    animation: _bounceAnim,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, -_bounceAnim.value),
                      child: child,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withValues(alpha: _dragging ? 0.35 : 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white
                              .withValues(alpha: _dragging ? 1.0 : 0.5),
                          width: 2,
                        ),
                        boxShadow: _dragging
                            ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: 14,
                          )
                        ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ),
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
// Section Header
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Stats Section
// ─────────────────────────────────────────────────────────────
class _StatsSection extends StatelessWidget {
  final String active;
  final String completed;
  final String earnings;
  const _StatsSection({
    required this.active,
    required this.completed,
    required this.earnings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Overview'),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            children: [
              _StatTile(
                value: active,
                label: 'Active',
                icon: Icons.bolt_rounded,
                iconColor: const Color(0xFF00A19B),
                bgColor: const Color(0xFFE0F7F5),
              ),
              const SizedBox(width: 10),
              _StatTile(
                value: completed,
                label: 'Done',
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF2E7D32),
                bgColor: const Color(0xFFE8F5E9),
              ),
              const SizedBox(width: 10),
              _StatTile(
                value: earnings,
                label: 'Earned',
                icon: Icons.account_balance_wallet_rounded,
                iconColor: const Color(0xFF6200EA),
                bgColor: const Color(0xFFEDE7F6),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  const _StatTile({
    required this.value,
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
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
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
// Active Project Card
// ─────────────────────────────────────────────────────────────
class _ActiveProjectCard extends StatelessWidget {
  final String title;
  final dynamic bid;
  final String? projId;
  final String duration;
  final dynamic budgetMin;
  final dynamic budgetMax;
  final VoidCallback? onTap;

  const _ActiveProjectCard({
    required this.title,
    required this.bid,
    required this.projId,
    required this.duration,
    required this.budgetMin,
    required this.budgetMax,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF00A19B),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2E7D32)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded,
                                    size: 10, color: Color(0xFF2E7D32)),
                                SizedBox(width: 3),
                                Text('HIRED',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2E7D32),
                                        letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              size: 13,
                              color: AppColors.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (budgetMin != null || budgetMax != null)
                            _Chip(
                              label: '\$$budgetMin–\$$budgetMax',
                              icon: Icons.attach_money_rounded,
                              color: AppColors.textSecondary,
                              bg: AppColors.background,
                            ),
                          _Chip(
                            label: 'Bid: \$$bid',
                            icon: Icons.local_offer_outlined,
                            color: AppColors.primary,
                            bg: AppColors.primaryLight,
                          ),
                          if (duration.isNotEmpty)
                            _Chip(
                              label: duration,
                              icon: Icons.schedule_rounded,
                              color: AppColors.textSecondary,
                              bg: AppColors.background,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chip with icon
// ─────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bg;
  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work_outline_rounded,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'No active projects yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Browse open projects and submit\na proposal to get hired.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Browse Projects',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
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
// StatCard — kept for external use
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
      child: SizedBox(
        height: 110,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: AppColors.primary, size: 22),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
