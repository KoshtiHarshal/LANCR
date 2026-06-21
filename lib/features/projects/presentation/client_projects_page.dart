// lib/features/projects/presentation/client_projects_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../messages/presentation/messages_provider.dart';
import '../../../main.dart';

final clientProjectsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return [];
  try {
    // Fetch archived rows too (so tab counts stay stable); the list filters
    // archived projects out of the visible cards.
    final data = await supabase
        .from('projects')
        .select(
        'id, title, description, status, budget_min, budget_max, created_at, archived')
        .eq('client_id', userId)
        .order('created_at', ascending: false)
        .limit(100);
    return List<Map<String, dynamic>>.from(data as List);
  } catch (e) {
    throw Exception('Failed to load projects: $e');
  }
});

// Hide a client's own project from the My Projects list. Clients have a direct
// UPDATE policy on their own projects, so a plain update is sufficient (no RPC).
// Stats are unaffected — stat providers keep counting archived projects.
Future<void> archiveProject({required String projectId}) async {
  await supabase
      .from('projects')
      .update({'archived': true})
      .eq('id', projectId);
}

Color _statusColor(String status) {
  switch (status) {
    case 'open':      return const Color(0xFF2E7D32);
    case 'closed':    return const Color(0xFF2F8FE0); // readable blue both modes
    case 'completed': return const Color(0xFFB07CE8); // readable purple both modes
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

class ClientProjectsPage extends ConsumerStatefulWidget {
  const ClientProjectsPage({super.key});

  @override
  ConsumerState<ClientProjectsPage> createState() => _ClientProjectsPageState();
}

class _ClientProjectsPageState extends ConsumerState<ClientProjectsPage> {
  // 'all' | 'open' | 'closed' (In Progress) | 'completed'
  String _tab = 'all';

  // Open (or reconnect) the chat with the hired freelancer for an active
  // (in-progress) project. Only used on 'closed' status cards.
  Future<void> _openChat(Map<String, dynamic> project) async {
    final projectId = project['id'] as String?;
    final me = supabase.auth.currentUser?.id;
    if (projectId == null || me == null) return;
    try {
      final row = await supabase
          .from('proposals')
          .select('freelancer_id, freelancer:profiles!freelancer_id(name)')
          .eq('project_id', projectId)
          .inFilter('status', ['accepted', 'completed'])
          .maybeSingle();
      final freelancerId = row?['freelancer_id'] as String?;
      final freelancerName =
          (row?['freelancer'] as Map?)?['name'] as String? ?? 'Freelancer';
      if (freelancerId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hired freelancer to chat with.')),
          );
        }
        return;
      }
      final convId = await openConversation(
        projectId: projectId,
        clientId: me,
        freelancerId: freelancerId,
      );
      if (!mounted) return;
      context.push('/messages/$convId', extra: {
        'otherPersonName': freelancerName,
        'otherPersonId': freelancerId,
        'projectTitle': project['title'] ?? '',
        'projectId': projectId,
        'isClient': true,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open chat: $e')),
        );
      }
    }
  }

  Future<void> _confirmRemove(Map<String, dynamic> project) async {
    final id = project['id'] as String?;
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove project?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(
          'This removes "${project['title'] ?? 'this project'}" from your '
          'My Projects list. Your stats are not affected.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD94F4F)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await archiveProject(projectId: id);
      ref.invalidate(clientProjectsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from your projects.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(clientProjectsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Projects')),
      body: projectsAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                e.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
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
                  Text(
                    'No projects yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
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

          // Tab counts include archived projects so the numbers stay stable
          // even after a project is removed from the list.
          final counts = <String, int>{
            'all': projects.length,
            'open':
                projects.where((p) => (p['status'] ?? 'open') == 'open').length,
            'closed': projects.where((p) => p['status'] == 'closed').length,
            'completed':
                projects.where((p) => p['status'] == 'completed').length,
          };

          // Visible cards: hide archived, filter by tab, then order
          // open → in progress → completed (newest first within each group).
          int rank(String s) =>
              switch (s) { 'open' => 0, 'closed' => 1, 'completed' => 2, _ => 3 };
          final filtered = projects
              .where((p) => p['archived'] != true)
              .where((p) => _tab == 'all' || (p['status'] ?? 'open') == _tab)
              .toList()
            ..sort((a, b) {
              final r = rank(a['status'] ?? 'open')
                  .compareTo(rank(b['status'] ?? 'open'));
              if (r != 0) return r;
              final da = a['created_at'] as String? ?? '';
              final db = b['created_at'] as String? ?? '';
              return db.compareTo(da);
            });

          return Column(
            children: [
              _ProjectsFilterBar(
                counts: counts,
                selected: _tab,
                onSelect: (t) => setState(() => _tab = t),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_open_outlined,
                                size: 56,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'No ${_statusLabel(_tab == 'all' ? 'open' : _tab).toLowerCase()} projects',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final project = filtered[index];
                          final status = project['status'] ?? 'open';

                          return GestureDetector(
                onTap: () => context.push('/projects/${project['id']}'),
                onLongPress: () => _confirmRemove(project),
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
                              style: TextStyle(
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
                        style: TextStyle(
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
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          const Spacer(),

                          // View Proposals button — hidden on active projects
                          // (they already have a hired freelancer + chat).
                          if (status != 'closed')
                            TextButton.icon(
                              onPressed: () => context.push(
                                  '/projects/${project['id']}/proposals'),
                              icon:
                                  const Icon(Icons.people_outline, size: 16),
                              label: const Text('Proposals'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                              ),
                            ),

                          // Chat with the hired freelancer (active projects only)
                          if (status == 'closed') ...[
                            Material(
                              color: AppColors.primary,
                              shape: const CircleBorder(),
                              elevation: 1,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => _openChat(project),
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: Colors.white,
                                      size: 18),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
                        },
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
// Status filter strip — All / Open / Active / Done
// (same design as the My Proposals stats strip)
// ─────────────────────────────────────────────────────────────
class _ProjectsFilterBar extends StatelessWidget {
  final Map<String, int> counts;
  final String selected;
  final ValueChanged<String> onSelect;

  const _ProjectsFilterBar({
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.shadow),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatTab(
            label: 'All',
            value: '${counts['all'] ?? 0}',
            color: AppColors.primary,
            selected: selected == 'all',
            onTap: () => onSelect('all'),
          ),
          _StatTab(
            label: 'Open',
            value: '${counts['open'] ?? 0}',
            color: _statusColor('open'),
            selected: selected == 'open',
            onTap: () => onSelect('open'),
          ),
          _StatTab(
            label: 'Active',
            value: '${counts['closed'] ?? 0}',
            color: _statusColor('closed'),
            selected: selected == 'closed',
            onTap: () => onSelect('closed'),
          ),
          _StatTab(
            label: 'Done',
            value: '${counts['completed'] ?? 0}',
            color: _statusColor('completed'),
            selected: selected == 'completed',
            onTap: () => onSelect('completed'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tappable filter tab (value on top, label below)
// ─────────────────────────────────────────────────────────────
class _StatTab extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _StatTab({
    required this.label,
    required this.value,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  selected ? color.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 11,
                    color: selected ? color : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
