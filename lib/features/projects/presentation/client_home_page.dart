// lib/features/projects/presentation/client_home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../profiles/presentation/profile_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import 'freelancer_home_page.dart'; // StatCard lives here

// ── Open projects count ──────────────────────────────────────
final clientProjectsCountProvider = FutureProvider<int>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return 0;
  try {
    final data = await supabase
        .from('projects')
        .select('id')
        .eq('client_id', user.id)
        .eq('status', 'open');
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

// ── Proposals received count (across all client's projects) ──
final clientProposalsCountProvider = FutureProvider<int>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return 0;
  try {
    // Get all project IDs belonging to this client
    final projects = await supabase
        .from('projects')
        .select('id')
        .eq('client_id', user.id);

    final projectIds = (projects as List)
        .map((p) => p['id'] as String)
        .toList();

    if (projectIds.isEmpty) return 0;

    // Count all proposals on those projects
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
final clientCompletedCountProvider = FutureProvider<int>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return 0;
  try {
    final data = await supabase
        .from('projects')
        .select('id')
        .eq('client_id', user.id)
        .eq('status', 'closed');
    return (data as List).length;
  } catch (_) {
    return 0;
  }
});

// ────────────────────────────────────────────────────────────
class ClientHomePage extends ConsumerWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user             = ref.watch(authProvider).value;
    final profileAsync     = ref.watch(profileProvider);
    final projectCountAsync   = ref.watch(clientProjectsCountProvider);
    final proposalCountAsync  = ref.watch(clientProposalsCountProvider);
    final completedCountAsync = ref.watch(clientCompletedCountProvider);

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
                child: Icon(Icons.person_outline,
                    color: AppColors.primary, size: 20),
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

            // ── Hero Greeting Card ───────────────────────
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
                    child: Icon(Icons.business_center, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileAsync.when(
                          data: (profile) => Text(
                            'Hi, ${profile?['name'] ?? user?.email ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Text('Loading...',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15)),
                          error: (_, __) => Text(user?.email ?? '',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15)),
                        ),
                        const SizedBox(height: 4),
                        profileAsync.when(
                          data: (profile) {
                            final company = profile?['company'];
                            return Text(
                              (company != null &&
                                  company.toString().isNotEmpty)
                                  ? company
                                  : 'Post your first project →',
                              style: const TextStyle(
                                  color: Color(0xFFCCEEEC), fontSize: 13),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const Text(
                            'Post your first project →',
                            style: TextStyle(
                                color: Color(0xFFCCEEEC), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Overview ─────────────────────────────────
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Open Projects
                projectCountAsync.when(
                  data: (count) => StatCard(
                    icon: Icons.folder_open_outlined,
                    value: '$count',
                    label: 'Open\nProjects',
                  ),
                  loading: () => const StatCard(
                    icon: Icons.folder_open_outlined,
                    value: '—',
                    label: 'Open\nProjects',
                  ),
                  error: (_, __) => const StatCard(
                    icon: Icons.folder_open_outlined,
                    value: '0',
                    label: 'Open\nProjects',
                  ),
                ),
                const SizedBox(width: 8),

                // ✅ Proposals Received — now live from DB
                proposalCountAsync.when(
                  data: (count) => StatCard(
                    icon: Icons.people_outline,
                    value: '$count',
                    label: 'Proposals\nReceived',
                  ),
                  loading: () => const StatCard(
                    icon: Icons.people_outline,
                    value: '—',
                    label: 'Proposals\nReceived',
                  ),
                  error: (_, __) => const StatCard(
                    icon: Icons.people_outline,
                    value: '0',
                    label: 'Proposals\nReceived',
                  ),
                ),
                const SizedBox(width: 8),

                // ✅ Projects Completed — now live from DB
                completedCountAsync.when(
                  data: (count) => StatCard(
                    icon: Icons.check_circle_outline,
                    value: '$count',
                    label: 'Projects\nCompleted',
                  ),
                  loading: () => const StatCard(
                    icon: Icons.check_circle_outline,
                    value: '—',
                    label: 'Projects\nCompleted',
                  ),
                  error: (_, __) => const StatCard(
                    icon: Icons.check_circle_outline,
                    value: '0',
                    label: 'Projects\nCompleted',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Quick Actions ─────────────────────────────
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
                    onPressed: () => context.push('/projects/post'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Post a Project'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/client/projects'),
                    icon: const Icon(Icons.manage_search, size: 18),
                    label: const Text('My Projects'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Recent Activity ───────────────────────────
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            proposalCountAsync.when(
              data: (count) => count > 0
                  ? Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.notifications_active_outlined,
                            color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'You have $count proposal${count == 1 ? '' : 's'} waiting for review.',
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(Icons.lightbulb_outline,
                            color: AppColors.primary),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'No activity yet. Post a project to start receiving proposals from freelancers.',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // ── Sign out ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/auth/login');
                },
                icon: const Icon(Icons.logout,
                    size: 18, color: AppColors.textSecondary),
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