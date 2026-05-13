// lib/features/projects/presentation/freelancer_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../profiles/presentation/profile_provider.dart';
import '../../../core/theme/app_colors.dart';

class FreelancerHomePage extends ConsumerWidget {
  const FreelancerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lancr'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                // TODO: navigate to profile
              },
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.person_outline, color: AppColors.primary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                              (headline != null && headline.toString().isNotEmpty)
                                  ? headline
                                  : 'Add a headline to stand out →',
                              style: const TextStyle(
                                color: Color(0xFFCCEEEC),
                                fontSize: 13,
                              ),
                            );
                          },
                          loading: () => const Text(
                            'Loading...',
                            style: TextStyle(color: Color(0xFFCCEEEC), fontSize: 13),
                          ),
                          error: (e, _) => const Text(
                            'Add a headline to stand out →',
                            style: TextStyle(color: Color(0xFFCCEEEC), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Overview ────────────────────────────────
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                StatCard(icon: Icons.work_outline, value: '0', label: 'Active\nProjects'),
                SizedBox(width: 8),
                StatCard(icon: Icons.send_outlined, value: '0', label: 'Proposals\nSent'),
                SizedBox(width: 8),
                StatCard(icon: Icons.account_balance_wallet_outlined, value: '\$0', label: 'Earnings'),
              ],
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
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Update Profile'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Upcoming ─────────────────────────────────
            const Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Icon(Icons.notifications_outlined, color: AppColors.primary),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'No upcoming deadlines. Start by browsing projects that match your skills.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Sign out ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/auth/login');
                },
                icon: const Icon(Icons.logout, size: 18, color: AppColors.textSecondary),
                label: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.shadow),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Card Widget ─────────────────────────────────────
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
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}