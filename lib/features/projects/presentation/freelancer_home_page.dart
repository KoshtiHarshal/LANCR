import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/models/user.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';

class FreelancerHomePage extends ConsumerWidget {
  const FreelancerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        if (user == null) {
          // Should not happen if router checks auth
          return const Scaffold(
            body: Center(child: Text('Not logged in')),
          );
        }
        return _FreelancerHomeContent(user: user);
      },
    );
  }
}

class _FreelancerHomeContent extends StatelessWidget {
  final User user;
  const _FreelancerHomeContent({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lancr'),
        actions: [
          IconButton(
            onPressed: () => context.go('/profile/edit'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Welcome back, ${user.profile.name ?? user.email}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.profile.headline?.isNotEmpty == true
                  ? user.profile.headline!
                  : 'Set a headline to attract clients',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Stats row (placeholder values for now)
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Active projects',
                    value: '${user.profileCompleted ? 0 : 0}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Proposals sent',
                    value: '0',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Earnings',
                    value: '\$0',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Skills
            if (user.profile.skills.isNotEmpty) ...[
              Text(
                'Skills',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: user.profile.skills
                    .map(
                      (s) => Chip(
                    label: Text(s),
                  ),
                )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Quick actions
            Text(
              'Quick actions',
              style: theme.textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: navigate to browse projects list
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Browse projects'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/profile/edit'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}