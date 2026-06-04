// lib/features/projects/presentation/client_projects_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

final clientProjectsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];
  try {
    final data = await supabase
        .from('projects')
        .select(
        'id, title, description, status, budget_min, budget_max, created_at')
        .eq('client_id', user.id)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data as List);
  } catch (e) {
    throw Exception('Failed to load projects: $e');
  }
});

Color _statusColor(String status) {
  switch (status) {
    case 'open':      return const Color(0xFF2E7D32);
    case 'closed':    return const Color(0xFF1565C0);
    case 'completed': return const Color(0xFF6A1B9A);
    default:          return AppColors.textSecondary;
  }
}

Color _statusBg(String status) {
  switch (status) {
    case 'open':      return const Color(0xFF2E7D32).withValues(alpha: 0.1); // ✅ fixed
    case 'closed':    return const Color(0xFF1565C0).withValues(alpha: 0.1); // ✅ fixed
    case 'completed': return const Color(0xFF6A1B9A).withValues(alpha: 0.1); // ✅ fixed
    default:          return AppColors.shadow;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'open':      return 'Open';
    case 'closed':    return 'In Progress';
    case 'completed': return 'Completed';
    default:          return status.toUpperCase();
  }
}

class ClientProjectsPage extends ConsumerWidget {
  const ClientProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(clientProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Projects')),
      body: projectsAsync.when(
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
                onPressed: () => ref.invalidate(clientProjectsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_open_outlined,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No projects yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Post a project to start\nreceiving proposals.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => context.push('/projects/post'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Post a Project'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (_,index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              final status = project['status'] ?? 'open';

              return GestureDetector(
                onTap: () => context.push('/projects/${project['id']}'),
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

                      // ── Title + Status badge ──────────────
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              project['title'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusBg(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // ── Description preview ───────────────
                      Text(
                        project['description'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Budget + Actions ──────────────────
                      Row(
                        children: [
                          if (project['budget_min'] != null ||
                              project['budget_max'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '\$${project['budget_min'] ?? '?'} – \$${project['budget_max'] ?? '?'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          const Spacer(),

                          // View Proposals button
                          TextButton.icon(
                            onPressed: () => context.push(
                                '/projects/${project['id']}/proposals'),
                            icon: const Icon(Icons.people_outline, size: 16),
                            label: const Text('Proposals'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}