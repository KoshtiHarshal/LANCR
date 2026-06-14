import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
        loading: () => const Center(
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
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _ProfileHero(
              name: name,
              subtitle: headline ??
                  (isClient ? company ?? 'Hiring on LANCR' : 'Freelancer'),
              initials: initials.isEmpty ? '?' : initials,
              avatarUrl: avatarUrl,
              isClient: isClient,
              onBack: () => context.pop(),
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
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: RatingSummary(userId: userId),
                ),
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
                if (!isClient) ...[
                  const SizedBox(height: 14),
                  _SectionCard(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Skills & expertise',
                    child: skills.isEmpty
                        ? const Text(
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
                            label: 'Portfolio',
                            value: portfolio,
                          ),
                        if (portfolio != null && linkedin != null)
                          const Divider(color: AppColors.shadow),
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
  final String name;
  final String subtitle;
  final String initials;
  final String? avatarUrl;
  final bool isClient;
  final VoidCallback onBack;

  const _ProfileHero({
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.avatarUrl,
    required this.isClient,
    required this.onBack,
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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
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
                    image: NetworkImage(avatarUrl!),
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
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
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
      loading: () => const _StatsShell(
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
            style: const TextStyle(
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

  const _InfoPill({required this.icon, required this.label});

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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
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
                style: const TextStyle(
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
        style: const TextStyle(
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          const Icon(
            Icons.person_off_outlined,
            color: AppColors.textSecondary,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
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