// lib/features/messages/presentation/chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/notifications/push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../reviews/presentation/review_widgets.dart';
import '../../reviews/presentation/reviews_provider.dart';
import 'messages_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherPersonName;
  final String? otherPersonId;
  final String projectTitle;
  final String? projectId;
  final String? proposalId;
  final bool isClient;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherPersonName,
    this.otherPersonId,
    required this.projectTitle,
    this.projectId,
    this.proposalId,
    this.isClient = false,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  RealtimeChannel? _projectChannel;

  @override
  void initState() {
    super.initState();
    // Suppress push/local notifications for the chat we're viewing.
    PushService.activeConversationId = widget.conversationId;

    // Make the "Leave a review" card appear live: when the client completes
    // the project, the freelancer (sitting in this chat) sees the project row
    // update via realtime, so we refresh review eligibility immediately.
    final projectId = widget.projectId;
    if (projectId != null) {
      WidgetsBinding.instance.addObserver(this);
      _projectChannel = supabase
          .channel('chat_project_$projectId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'projects',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'id',
              value: projectId,
            ),
            callback: (_) {
              if (mounted) {
                ref.invalidate(reviewEligibilityProvider(projectId));
              }
            },
          )
          .subscribe();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cheap fallback in case a realtime event was missed while backgrounded.
    final projectId = widget.projectId;
    if (state == AppLifecycleState.resumed && projectId != null) {
      ref.invalidate(reviewEligibilityProvider(projectId));
    }
  }

  @override
  void dispose() {
    if (PushService.activeConversationId == widget.conversationId) {
      PushService.activeConversationId = null;
    }
    if (_projectChannel != null) {
      WidgetsBinding.instance.removeObserver(this);
      supabase.removeChannel(_projectChannel!);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openProfile() async {
    final id = widget.otherPersonId;
    if (id != null) context.push('/profile/$id');
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Clear chat?',
            style: TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text('This permanently deletes all messages in this chat.',
            style: TextStyle(color: AppColors.textSecondary)),
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await clearChat(widget.conversationId);
      // Force the stream to re-fetch so the cleared chat updates immediately.
      ref.invalidate(messagesProvider(widget.conversationId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear chat: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final myId = supabase.auth.currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: _openProfile,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.otherPersonName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (widget.otherPersonId != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textSecondary),
                  ],
                ],
              ),
              if (widget.projectTitle.isNotEmpty)
                Text(
                  widget.projectTitle,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'profile') _openProfile();
              if (value == 'clear') _clearChat();
            },
            itemBuilder: (_) => [
              if (widget.otherPersonId != null)
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [
                    Icon(Icons.person_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('View profile'),
                  ]),
                ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(children: [
                  Icon(Icons.delete_sweep_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Clear chat'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Leave-review banner (shows for whichever party is eligible) ──
          if (widget.projectId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LeaveReviewCard(projectId: widget.projectId!),
            ),

          // ── Messages list ───────────────────────────
          Expanded(
            child: messagesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style:
                    TextStyle(color: AppColors.textSecondary)),
              ),
              data: (messages) {
                _scrollToBottom();
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            size: 56,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet.\nSay hello! 👋',
                          textAlign: TextAlign.center,
                          style:
                          TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg['sender_id'] == myId;
                    final createdAt = msg['created_at'] != null
                        ? DateTime.parse(msg['created_at']).toLocal()
                        : null;
                    return _MessageBubble(
                      content: msg['content'],
                      isMe: isMe,
                      time: createdAt,
                    );
                  },
                );
              },
            ),
          ),

          // ── Input bar ───────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                          : const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ──────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final DateTime? time;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    this.time,
  });

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (time != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(time!),
                style: TextStyle(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}