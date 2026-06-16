import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../portfolio/presentation/portfolio_provider.dart';
import '../../portfolio/presentation/portfolio_widgets.dart';
import '../../reviews/presentation/review_widgets.dart';
import 'profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    await context.push('/profile/edit');
    ref.invalidate(profileProvider);
    ref.invalidate(publicProfileProvider(userId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => _ProfileError(
            onRetry: () => ref.invalidate(profileProvider),
          ),
          data: (profile) {
            if (profile == null) {
              return const Center(child: Text('Profile not found'));
            }
            return _ProfileBody(
              profile: profile,
              onEdit: () => _openEditor(
                context,
                ref,
                profile['id'] as String,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onEdit;

  const _ProfileBody({
    required this.profile,
    required this.onEdit,
  });

  String? _text(String key) {
    final value = profile[key]?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = profile['id'] as String;
    final name = _text('name') ?? 'Complete your profile';
    final headline = _text('headline');
    final location = _text('location');
    final company = _text('company');
    final bio = _text('bio');
    final avatarUrl = _text('avatar_url');
    final skills =
        (profile['skills'] as List? ?? []).map((skill) => '$skill').toList();
    final isClient = (_text('role') ?? 'freelancer') == 'client';
    final emailVerified = profile['email_verified'] == true;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final completion = [
      name,
      headline ?? '',
      location ?? '',
      bio ?? '',
      isClient ? company ?? '' : skills.join(),
    ].where((value) => value.trim().isNotEmpty).length *
        20;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(profileProvider);
        ref.invalidate(freelancerStatsProvider(userId));
        ref.invalidate(clientStatsProvider(userId));
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'My profile',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.7,
                  ),
                ),
              ),
              _TopAction(
                icon: Icons.settings_outlined,
                tooltip: 'Settings',
                onTap: () async {
                  await context.push('/settings');
                  ref.invalidate(profileProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _IdentityCard(
            userId: userId,
            name: name,
            subtitle: headline ??
                (isClient ? company ?? 'LANCR client' : 'LANCR freelancer'),
            initials: initials.isEmpty ? '?' : initials,
            avatarUrl: avatarUrl,
            isClient: isClient,
            emailVerified: emailVerified,
            onEditAvatar: onEdit,
          ),
          const SizedBox(height: 14),
          _StatsCard(userId: userId, isClient: isClient),
          if (completion < 100) ...[
            const SizedBox(height: 14),
            _CompletionCard(
              percent: completion,
              onTap: onEdit,
            ),
          ],
          const SizedBox(height: 18),
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: isClient ? 'About your business' : 'About you',
            child: Text(
              bio ??
                  (isClient
                      ? 'Add a short company introduction so freelancers know who they will work with.'
                      : 'Add a concise bio to explain your experience and working style.'),
              style: TextStyle(
                color: AppColors.textSecondary,
                height: 1.6,
                fontStyle: bio == null ? FontStyle.italic : FontStyle.normal,
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
                      'Add your strongest skills to improve project matching.',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PortfolioGallery(userId: userId),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await context.push('/portfolio/manage');
                        ref.invalidate(portfolioProvider(userId));
                      },
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('Manage portfolio'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TopAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.shadow),
      ),
      icon: Icon(icon, size: 20),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final String userId;
  final String name;
  final String subtitle;
  final String initials;
  final String? avatarUrl;
  final bool isClient;
  final bool emailVerified;
  final VoidCallback onEditAvatar;

  const _IdentityCard({
    required this.userId,
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.avatarUrl,
    required this.isClient,
    required this.emailVerified,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F1EC), Color(0xFFE0F5F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.shadow),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEditAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.primary,
                  backgroundImage:
                      avatarUrl == null ? null : NetworkImage(avatarUrl ?? 'Unknown'),
                  child: avatarUrl == null
                      ? Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.shadow),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 15,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    if (emailVerified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                RatingSummary(userId: userId),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isClient ? 'CLIENT' : 'FREELANCER',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
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

class _StatsCard extends ConsumerWidget {
  final String userId;
  final bool isClient;

  const _StatsCard({required this.userId, required this.isClient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = isClient
        ? ref.watch(clientStatsProvider(userId))
        : ref.watch(freelancerStatsProvider(userId));

    return Container(
      constraints: const BoxConstraints(minHeight: 88),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shadow),
      ),
      child: stats.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2,
          ),
        ),
        error: (_, _) => const Center(child: Text('Stats unavailable')),
        data: (values) => Row(
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
              color: const Color(0xFFF59E0B),
            ),
            const _StatDivider(),
            _Stat(
              value: '${values['completedProjects']}',
              label: 'Completed',
              color: const Color(0xFF2E7D32),
            ),
          ],
        ),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
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

class _CompletionCard extends StatelessWidget {
  final int percent;
  final VoidCallback onTap;

  const _CompletionCard({required this.percent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: percent / 100,
                    strokeWidth: 5,
                    backgroundColor: AppColors.shadow,
                    color: AppColors.primary,
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Finish your profile',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Complete profiles build more trust.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.primary,
              size: 14,
            ),
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
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
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

class _ProfileError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ProfileError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          const Text('Could not load your profile'),
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
