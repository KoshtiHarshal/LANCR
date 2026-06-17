// lib/features/notifications/presentation/notifications_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'notifications_provider.dart';

String _timeAgo(String? raw) {
  if (raw == null) return '';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

({IconData icon, Color color}) _styleFor(String type) {
  switch (type) {
    case 'proposal':
      return (icon: Icons.assignment_outlined, color: AppColors.primary);
    case 'accepted':
      return (icon: Icons.check_circle_outline, color: const Color(0xFF2E7D32));
    case 'rejected':
      return (icon: Icons.cancel_outlined, color: const Color(0xFFD94F4F));
    case 'completed':
      return (icon: Icons.verified_outlined, color: const Color(0xFF2E7D32));
    case 'message':
      return (icon: Icons.chat_bubble_outline, color: AppColors.primary);
    default:
      return (icon: Icons.notifications_none_rounded, color: AppColors.primary);
  }
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  void _onTap(BuildContext context, WidgetRef ref, Map<String, dynamic> n) {
    if (n['read'] != true) {
      notificationsRepository
          .markRead(n['id'] as String)
          .then((_) => ref.invalidate(notificationsProvider));
    }
    final data = (n['data'] as Map?) ?? {};
    final type = n['type'] as String?;
    final projectId = data['project_id'] as String?;

    if (type == 'message') {
      context.push('/messages');
    } else if (type == 'proposal' && projectId != null) {
      context.push('/projects/$projectId/proposals');
    } else if (projectId != null) {
      context.push('/projects/$projectId');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () async {
              await notificationsRepository.markAllRead();
              ref.invalidate(notificationsProvider);
            },
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: async.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, _) => Center(
          child: Text('Could not load notifications',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Icon(Icons.notifications_none_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                Center(
                  child: Text("You're all caught up",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final n = items[i];
              final unread = n['read'] != true;
              final style = _styleFor(n['type'] as String? ?? '');
              return InkWell(
                onTap: () => _onTap(context, ref, n),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: unread
                        ? AppColors.primary.withValues(alpha: 0.06)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: unread
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.shadow,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: style.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(style.icon, color: style.color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n['title'] as String? ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if ((n['body'] as String?)?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 2),
                              Text(
                                n['body'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              _timeAgo(n['created_at'] as String?),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4, left: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
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

/// Bell icon with an unread badge — drop into app bars / headers.
class NotificationBell extends ConsumerWidget {
  final Color? color;
  const NotificationBell({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          onPressed: () => context.push('/notifications'),
          icon: Icon(Icons.notifications_none_rounded, color: color),
          tooltip: 'Notifications',
        ),
        if (unread > 0)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFFD94F4F),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}
