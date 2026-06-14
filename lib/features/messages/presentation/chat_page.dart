// lib/features/messages/presentation/chat_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../main.dart';
import '../../projects/presentation/proposals_provider.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/presentation/reviews_provider.dart';
import '../../reviews/presentation/review_widgets.dart';
import 'messages_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherPersonName;
  final String projectTitle;
  final String? projectId;    // ← NEW
  final String? proposalId;   // ← NEW
  final bool isClient;        // ← NEW

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.otherPersonName,
    required this.projectTitle,
    this.projectId,
    this.proposalId,
    this.isClient = false,
  });

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;
  bool _completing = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  // ── Mark project as complete ─────────────────────────────
  Future<void> _markComplete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mark as Complete?',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        content: const Text(
          'This will mark the project as completed. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Complete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _completing = true);
    try {
      await completeProject(
        projectId: widget.projectId!,
        proposalId: widget.proposalId!,
      );
      if (mounted) {
        ref.invalidate(reviewEligibilityProvider(widget.projectId!));
        await _showCompletionSuccess();
        if (mounted) await _maybePromptReview();
        if (mounted) Navigator.pop(context); // go back from chat
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  /// After completion, offer the client the chance to review the freelancer.
  Future<void> _maybePromptReview() async {
    final projectId = widget.projectId;
    if (projectId == null) return;

    final reviewCtx = await reviewsRepository.getReviewContext(projectId);
    if (!mounted) return;

    final canReview = reviewCtx['canReview'] as bool? ?? false;
    final revieweeId = reviewCtx['revieweeId'] as String?;
    final revieweeName = reviewCtx['revieweeName'] as String? ?? 'this user';
    if (!canReview || revieweeId == null) return;

    final submitted = await showReviewDialog(
      context,
      projectId: projectId,
      revieweeId: revieweeId,
      revieweeName: revieweeName,
    );
    if (submitted == true && mounted) {
      ref.invalidate(reviewEligibilityProvider(projectId));
      ref.invalidate(userReviewsProvider(revieweeId));
      ref.invalidate(userRatingStatsProvider(revieweeId));
    }
  }

  Future<void> _showCompletionSuccess() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: Color(0xFF2E7D32), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              '🎉 Project Completed!',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Great work! The project has been marked as completed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Done',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.conversationId));
    final myId = supabase.auth.currentUser!.id;

    final canComplete = widget.isClient &&
        widget.projectId != null &&
        widget.proposalId != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.otherPersonName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (widget.projectTitle.isNotEmpty)
              Text(
                widget.projectTitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          if (canComplete)
            _completing
                ? const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: AppColors.primary, strokeWidth: 2),
              ),
            )
                : TextButton.icon(
              onPressed: _markComplete,
              icon: const Icon(Icons.task_alt_outlined,
                  size: 16, color: AppColors.primary),
              label: const Text('Complete',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
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
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text(e.toString(),
                    style:
                    const TextStyle(color: AppColors.textSecondary)),
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
                        const Text(
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
                      decoration: const BoxDecoration(
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