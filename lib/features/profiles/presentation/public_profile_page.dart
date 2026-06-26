import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/url_launcher_util.dart';
import '../../../main.dart';
import '../../moderation/presentation/moderation_widgets.dart';
import '../../portfolio/presentation/portfolio_provider.dart';
import '../../portfolio/presentation/portfolio_widgets.dart';
import '../../reviews/presentation/reviews_provider.dart';
import '../../reviews/presentation/review_widgets.dart';
import 'profile_provider.dart';

class PublicProfilePage extends ConsumerWidget {
  final String userId;

  const PublicProfilePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(publicProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(publicProfileProvider(userId)),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          return _ProfileContent(profile: profile, userId: userId);
        },
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final Map<String, dynamic> profile;
  final String userId;

  const _ProfileContent({required this.profile, required this.userId});

  String? _text(String key) {
    final value = profile[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  String? _memberSince(String? raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Member since ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = _text('name') ?? 'LANCR member';
    final role = _text('role') ?? 'freelancer';
    final isClient = role == 'client';
    final headline = _text('headline');
    final company = _text('company');
    final location = _text('location');
    final bio = _text('bio');
    final portfolio = _text('portfolio_url');
    final linkedin = _text('linkedin_url');
    final avatarUrl = _text('avatar_url');
    final experience = profile['experience_years'];
    final skills =
    (profile['skills'] as List? ?? []).map((item) => '$item').toList();
    final emailVerified = profile['email_verified'] == true;
    final memberSince = _memberSince(profile['created_at'] as String?);
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(publicProfileProvider(userId));
        ref.invalidate(freelancerStatsProvider(userId));
        ref.invalidate(clientStatsProvider(userId));
        ref.invalidate(portfolioProvider(userId));
        ref.invalidate(userReviewsProvider(userId));
        ref.invalidate(userRatingStatsProvider(userId));
        ref.invalidate(clientRecentProjectsProvider(userId));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              userId: userId,
              name: name,
              subtitle: headline ??
                  (isClient ? company ?? 'Hiring on LANCR' : 'Freelancer'),
              initials: initials.isEmpty ? '?' : initials,
              avatarUrl: avatarUrl,
              isClient: isClient,
              emailVerified: emailVerified,
              onBack: () => context.pop(),
              onReport: (supabase.auth.currentUser?.id == userId)
                  ? null
                  : () async {
                      final ok = await showReportDialog(context,
                          reportedUserId: userId, targetName: name);
                      if (ok == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Report submitted. Thank you.')),
                        );
                      }
                    },
              onBlock: (supabase.auth.currentUser?.id == userId)
                  ? null
                  : () async {
                      final blocked = await confirmAndBlockUser(
                          context, ref, userId, name);
                      if (blocked && context.mounted) context.pop();
                    },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: _StatsCard(userId: userId, isClient: isClient),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (location != null)
                      _InfoPill(
                        icon: Icons.location_on_outlined,
                        label: location,
                      ),
                    if (isClient && company != null)
                      _InfoPill(
                        icon: Icons.apartment_rounded,
                        label: company,
                      ),
                    if (!isClient && experience != null)
                      _InfoPill(
                        icon: Icons.workspace_premium_outlined,
                        label: '$experience years experience',
                      ),
                    _InfoPill(
                      icon: isClient
                          ? Icons.business_center_outlined
                          : Icons.work_outline_rounded,
                      label: isClient ? 'Client' : 'Freelancer',
                    ),
                    if (memberSince != null)
                      _InfoPill(
                        icon: Icons.calendar_today_outlined,
                        label: memberSince,
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionCard(
                  icon: Icons.person_outline_rounded,
                  title: isClient ? 'About the client' : 'About',
                  child: Text(
                    bio ??
                        (isClient
                            ? 'This client has not added a company description yet.'
                            : 'This freelancer has not added a bio yet.'),
                    style: TextStyle(
                      color: bio == null
                          ? AppColors.textSecondary.withValues(alpha: 0.75)
                          : AppColors.textSecondary,
                      height: 1.6,
                      fontStyle:
                      bio == null ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                if (isClient) ...[
                  const SizedBox(height: 14),
                  _ClientTrustCard(clientId: userId),
                  const SizedBox(height: 14),
                  _ClientProjectsSection(clientId: userId),
                ],
                if (!isClient) ...[
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Skills & expertise',
                    child: skills.isEmpty
                        ? Text(
                      'Skills have not been added yet.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                        : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills
                          .map((skill) => _SkillChip(label: skill))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.work_outline_rounded,
                    title: 'Portfolio',
                    child: PortfolioGallery(userId: userId),
                  ),
                ],
                if (portfolio != null || linkedin != null) ...[
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.link_rounded,
                    title: 'Professional links',
                    child: Column(
                      children: [
                        if (portfolio != null)
                          _LinkRow(
                            icon: Icons.language_rounded,
                            label: isClient ? 'Website' : 'Portfolio',
                            value: portfolio,
                          ),
                        if (portfolio != null && linkedin != null)
                          Divider(color: AppColors.shadow),
                        if (linkedin != null)
                          _LinkRow(
                            icon: Icons.badge_outlined,
                            label: 'LinkedIn',
                            value: linkedin,
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _SectionCard(
                  icon: Icons.star_outline_rounded,
                  title: isClient ? 'Reviews from freelancers' : 'Reviews',
                  child: ReviewsList(userId: userId),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String userId;
  final String name;
  final String subtitle;
  final String initials;
  final String? avatarUrl;
  final bool isClient;
  final bool emailVerified;
  final VoidCallback onBack;
  final VoidCallback? onReport;
  final VoidCallback? onBlock;

  const _ProfileHero({
    required this.userId,
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.avatarUrl,
    required this.isClient,
    required this.emailVerified,
    required this.onBack,
    this.onReport,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        MediaQuery.of(context).padding.top + 12,
        18,
        54,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00B3AC), Color(0xFF007B76)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: 12,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                    ),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const Spacer(),
                  if (onReport != null || onBlock != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white),
                      onSelected: (v) {
                        if (v == 'report') onReport?.call();
                        if (v == 'block') onBlock?.call();
                      },
                      itemBuilder: (_) => [
                        if (onReport != null)
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(children: [
                              Icon(Icons.flag_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Report'),
                            ]),
                          ),
                        if (onBlock != null)
                          const PopupMenuItem(
                            value: 'block',
                            child: Row(children: [
                              Icon(Icons.block,
                                  size: 18, color: Color(0xFFD94F4F)),
                              SizedBox(width: 10),
                              Text('Block',
                                  style: TextStyle(color: Color(0xFFD94F4F))),
                            ]),
                          ),
                      ],
                    ),
                ],
              ),
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  image: avatarUrl == null
                      ? null
                      : DecorationImage(
                    image: CachedNetworkImageProvider(avatarUrl!),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: Colors.white54, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: avatarUrl == null
                    ? Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                )
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (emailVerified) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD8F4F2),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              RatingSummary(userId: userId, light: true, centered: true),
              const SizedBox(height: 12),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isClient
                          ? Icons.business_center_outlined
                          : Icons.verified_outlined,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isClient ? 'LANCR Client' : 'LANCR Freelancer',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends ConsumerWidget {
  final String userId;
  final bool isClient;

  const _StatsCard({required this.userId, required this.isClient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = isClient
        ? ref.watch(clientStatsProvider(userId))
        : ref.watch(freelancerStatsProvider(userId));

    return stats.when(
      loading: () => _StatsShell(
        children: [CircularProgressIndicator(color: AppColors.primary)],
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (values) => _StatsShell(
        children: [
          _Stat(
            value: '${values[isClient ? 'totalProjects' : 'totalProposals']}',
            label: isClient ? 'Projects' : 'Proposals',
            color: AppColors.primary,
          ),
          const _StatDivider(),
          _Stat(
            value: '${values['activeProjects']}',
            label: 'Active',
            color: Color(0xFFF59E0B),
          ),
          const _StatDivider(),
          _Stat(
            value: '${values['completedProjects']}',
            label: 'Completed',
            color: Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }
}

class _StatsShell extends StatelessWidget {
  final List<Widget> children;

  const _StatsShell({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shadow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: children,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _Stat({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: AppColors.shadow);
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// Trust/credibility signals for a client, derived from clientStatsProvider
// (no extra queries): freelancers hired, projects completed, completion rate.
class _ClientTrustCard extends ConsumerWidget {
  final String clientId;
  const _ClientTrustCard({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(clientStatsProvider(clientId));

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (v) {
        // 'activeProjects' counts in-progress (closed) projects; together with
        // completed projects these are the projects where a freelancer was hired.
        final active = v['activeProjects'] ?? 0;
        final completed = v['completedProjects'] ?? 0;
        final hired = active + completed;
        final rate = hired > 0 ? ((completed / hired) * 100).round() : null;

        return _SectionCard(
          icon: Icons.verified_user_outlined,
          title: 'Hiring activity',
          child: hired == 0
              ? Text(
                  'New to hiring on LANCR.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : Column(
                  children: [
                    _TrustRow(
                      icon: Icons.handshake_outlined,
                      label: 'Freelancers hired',
                      value: '$hired',
                    ),
                    Divider(color: AppColors.shadow, height: 18),
                    _TrustRow(
                      icon: Icons.check_circle_outline,
                      label: 'Projects completed',
                      value: '$completed',
                    ),
                    if (rate != null) ...[
                      Divider(color: AppColors.shadow, height: 18),
                      _TrustRow(
                        icon: Icons.trending_up_rounded,
                        label: 'Completion rate',
                        value: '$rate%',
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}

class _TrustRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TrustRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ClientProjectsSection extends ConsumerWidget {
  final String clientId;
  const _ClientProjectsSection({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(clientRecentProjectsProvider(clientId));
    return projectsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (projects) => _SectionCard(
        icon: Icons.work_outline_rounded,
        title: 'Open projects',
        child: projects.isEmpty
            ? Text(
                'No open projects right now.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < projects.length; i++) ...[
                    _ClientProjectRow(project: projects[i]),
                    if (i != projects.length - 1)
                      Divider(color: AppColors.shadow, height: 18),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ClientProjectRow extends StatelessWidget {
  final Map<String, dynamic> project;
  const _ClientProjectRow({required this.project});

  @override
  Widget build(BuildContext context) {
    final title = (project['title'] as String?) ?? 'Untitled project';
    final min = project['budget_min'];
    final max = project['budget_max'];
    final budget = (min != null && max != null) ? '\$$min – \$$max' : null;

    return InkWell(
      onTap: () => context.push('/projects/${project['id']}'),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.assignment_outlined,
                  color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (budget != null)
                    Text(
                      budget,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  final String label;

  const _SkillChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LinkRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final ok = await openExternalLink(value);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open link')),
          );
        }
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_off_outlined,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Could not load this profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}