// lib/features/messages/presentation/conversations_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import 'messages_provider.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(conversationsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: conversationsAsync.when(
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
                onPressed: () => ref.invalidate(conversationsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 72,
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Conversations appear here once a\nproposal is accepted on a project.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: conversations.length,
              separatorBuilder: (_, index) => const Divider(
                height: 1,
                indent: 72,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final conv = conversations[index];
                final initial = conv.otherPersonName.isNotEmpty
                    ? conv.otherPersonName[0].toUpperCase()
                    : '?';

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      initial,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          conv.otherPersonName,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _timeAgo(conv.lastMessageAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      // Project chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          conv.projectTitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conv.lastMessage ?? 'No messages yet',
                        style: TextStyle(
                          fontSize: 13,
                          color: conv.lastMessage != null
                              ? AppColors.textSecondary
                              : AppColors.textSecondary
                              .withValues(alpha: 0.5),
                          fontStyle: conv.lastMessage == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  onTap: () => context.push(
                    '/messages/${conv.id}',
                    extra: {
                      'otherPersonName': conv.otherPersonName,
                      'projectTitle': conv.projectTitle,
                      'projectId': conv.projectId,
                      'proposalId': conv.proposalId,
                      'isClient': conv.isClient,
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}