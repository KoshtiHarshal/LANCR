// lib/features/profiles/presentation/profile_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../profiles/presentation/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                e.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(profileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }

          final name         = profile['name'] as String? ?? '';
          final email        = profile['email'] as String? ?? '';
          final role         = profile['role'] as String? ?? 'freelancer';
          final headline     = profile['headline'] as String?;
          final bio          = profile['bio'] as String?;
          final location     = profile['location'] as String?;
          final company      = profile['company'] as String?;
          final expYears     = profile['experience_years'];
          final portfolioUrl = profile['portfolio_url'] as String?;
          final linkedinUrl  = profile['linkedin_url'] as String?;
          final skills = (profile['skills'] as List? ?? [])
              .map((s) => s.toString())
              .toList();
          final isClient = role == 'client';
          final initials = name.trim().isNotEmpty
              ? name.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
              : '?';

          return CustomScrollView(
            slivers: [

              // ── App Bar ─────────────────────────────────
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: AppColors.primary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, Color(0xFF007A75)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),

                          // Avatar
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white24,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Name
                          Text(
                            name.isNotEmpty ? name : 'No name set',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),

                          // Headline or role badge
                          const SizedBox(height: 4),
                          if (headline != null && headline.isNotEmpty)
                            Text(
                              headline,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFCCEEEC),
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isClient ? 'Client' : 'Freelancer',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white),
                    onPressed: () =>
                        context.push('/profile/edit'),
                    tooltip: 'Edit Profile',
                  ),
                ],
              ),

              // ── Body ────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Info chips row ─────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (location != null && location.isNotEmpty)
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              label: location,
                            ),
                          if (isClient &&
                              company != null &&
                              company.isNotEmpty)
                            _InfoChip(
                              icon: Icons.business_outlined,
                              label: company,
                            ),
                          if (!isClient && expYears != null)
                            _InfoChip(
                              icon: Icons.workspace_premium_outlined,
                              label: '$expYears yrs experience',
                            ),
                          _InfoChip(
                            icon: Icons.email_outlined,
                            label: email,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Bio ────────────────────────────
                      if (bio != null && bio.isNotEmpty) ...[
                        _SectionTitle('About'),
                        const SizedBox(height: 8),
                        Text(
                          bio,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Skills (freelancer only) ───────
                      if (!isClient && skills.isNotEmpty) ...[
                        _SectionTitle('Skills'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: skills
                              .map(
                                (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius:
                                BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          )
                              .toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // ── Links ──────────────────────────
                      if ((portfolioUrl != null &&
                          portfolioUrl.isNotEmpty) ||
                          (linkedinUrl != null &&
                              linkedinUrl.isNotEmpty)) ...[
                        _SectionTitle('Links'),
                        const SizedBox(height: 10),
                        if (portfolioUrl != null &&
                            portfolioUrl.isNotEmpty)
                          _LinkTile(
                            icon: Icons.language_outlined,
                            label: 'Portfolio',
                            url: portfolioUrl,
                          ),
                        if (linkedinUrl != null &&
                            linkedinUrl.isNotEmpty)
                          _LinkTile(
                            icon: Icons.link_outlined,
                            label: 'LinkedIn',
                            url: linkedinUrl,
                          ),
                        const SizedBox(height: 24),
                      ],

                      // ── Role badge ─────────────────────
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.shadow),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isClient
                                  ? Icons.business_center_outlined
                                  : Icons.work_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isClient
                                  ? 'Registered as a Client'
                                  : 'Registered as a Freelancer',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Edit Profile button ────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/profile/edit'),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Edit Profile'),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Sign out ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await ref
                                .read(authNotifierProvider.notifier)
                                .logout();
                            if (context.mounted) {
                              context.go('/auth/login');
                            }
                          },
                          icon: const Icon(Icons.logout,
                              size: 18,
                              color: AppColors.textSecondary),
                          label: const Text(
                            'Sign out',
                            style:
                            TextStyle(color: AppColors.textSecondary),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: AppColors.shadow),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Title
// ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
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

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Link Tile
// ─────────────────────────────────────────────────────────────
class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;

  const _LinkTile({
    required this.icon,
    required this.label,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  url,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              size: 14, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}