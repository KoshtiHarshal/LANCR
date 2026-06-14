// lib/features/projects/presentation/project_completion_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../reviews/data/reviews_repository.dart';
import '../../reviews/presentation/reviews_provider.dart';
import '../../reviews/presentation/review_widgets.dart';
import 'project_completion_provider.dart';

class ProjectCompletionPage extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectCompletionPage({super.key, required this.projectId});

  @override
  ConsumerState<ProjectCompletionPage> createState() =>
      _ProjectCompletionPageState();
}

class _ProjectCompletionPageState
    extends ConsumerState<ProjectCompletionPage> {
  bool _completing = false;

  Future<void> _markComplete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mark as Completed?',
          style: TextStyle(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: const Text(
          'This will mark the project as completed. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _completing = true);
    try {
      await completeProject(projectId: widget.projectId);
      if (!mounted) return;

      // Invalidate providers so lists refresh
      ref.invalidate(projectDetailProvider(widget.projectId));
      ref.invalidate(acceptedFreelancerProvider(widget.projectId));
      ref.invalidate(reviewEligibilityProvider(widget.projectId));

      // Show success screen, then prompt for a review
      await _showSuccessBanner();
      if (mounted) await _maybePromptReview();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: const Color(0xFFD94F4F),
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  /// After completion, offer the current user (client or freelancer) the
  /// chance to review their counterpart.
  Future<void> _maybePromptReview() async {
    final reviewCtx =
    await reviewsRepository.getReviewContext(widget.projectId);
    if (!mounted) return;

    final canReview = reviewCtx['canReview'] as bool? ?? false;
    final revieweeId = reviewCtx['revieweeId'] as String?;
    final revieweeName = reviewCtx['revieweeName'] as String? ?? 'this user';
    if (!canReview || revieweeId == null) return;

    final submitted = await showReviewDialog(
      context,
      projectId: widget.projectId,
      revieweeId: revieweeId,
      revieweeName: revieweeName,
    );
    if (submitted == true && mounted) {
      ref.invalidate(reviewEligibilityProvider(widget.projectId));
      ref.invalidate(userReviewsProvider(revieweeId));
      ref.invalidate(userRatingStatsProvider(revieweeId));
    }
  }

  Future<void> _showSuccessBanner() {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  size: 40, color: Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Project Completed! 🎉',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Great work! The project has been marked as completed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync =
    ref.watch(projectDetailProvider(widget.projectId));
    final freelancerAsync =
    ref.watch(acceptedFreelancerProvider(widget.projectId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Project Details'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: projectAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style:
              const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (project) {
          if (project == null) {
            return const Center(
                child: Text('Project not found.',
                    style: TextStyle(color: AppColors.textSecondary)));
          }

          final status = project['status'] as String? ?? 'open';
          final isCompleted = status == 'completed';
          final isClosed = status == 'closed';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Status Banner ────────────────────────
                _StatusBanner(status: status),
                const SizedBox(height: 20),

                // ── Project Info Card ────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['title'] ?? 'Untitled Project',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        project['description'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              size: 16, color: AppColors.primary),
                          Text(
                            '\$${project['budget_min']} – \$${project['budget_max']}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Hired Freelancer Card ─────────────────
                if (isClosed || isCompleted)
                  freelancerAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary)),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (data) {
                      if (data == null) return const SizedBox.shrink();
                      final profile = data['profiles'] as Map<String, dynamic>?
                          ?? data['freelancer'] as Map<String, dynamic>?;
                      final name =
                          profile?['name'] ?? 'Freelancer';
                      final headline =
                      profile?['headline'] as String?;
                      final bidAmount = data['bid_amount'];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hired Freelancer',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _SectionCard(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primaryLight,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : 'F',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: AppColors.textPrimary,
                                          )),
                                      if (headline != null &&
                                          headline.isNotEmpty)
                                        Text(headline,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '\$$bidAmount',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),

                // ── Mark Complete Button ──────────────────
                if (isClosed && !isCompleted)
                  SizedBox(
                    width: double.infinity,
                    child: _completing
                        ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary))
                        : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _markComplete,
                      icon: const Icon(Icons.check_circle_outline,
                          size: 20),
                      label: const Text(
                        'Mark as Completed',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                if (isCompleted) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color:
                      const Color(0xFF2E7D32).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF2E7D32)
                              .withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_outlined,
                            size: 18, color: Color(0xFF2E7D32)),
                        SizedBox(width: 8),
                        Text(
                          'Project Completed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Leave a Review CTA ────────────────────
                  LeaveReviewCard(projectId: widget.projectId),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Status Banner
// ─────────────────────────────────────────────────────────────
class _StatusBanner extends StatelessWidget {
  final String status;
  const _StatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;
    String sublabel;

    switch (status) {
      case 'completed':
        color = const Color(0xFF2E7D32);
        icon = Icons.verified_outlined;
        label = 'Completed';
        sublabel = 'This project has been successfully completed.';
        break;
      case 'closed':
        color = AppColors.primary;
        icon = Icons.lock_outline;
        label = 'In Progress';
        sublabel = 'A freelancer has been hired. Mark complete when done.';
        break;
      default:
        color = const Color(0xFFF59E0B);
        icon = Icons.hourglass_empty_outlined;
        label = 'Open';
        sublabel = 'Waiting for proposals from freelancers.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: color)),
                Text(sublabel,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Section Card wrapper
// ─────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.shadow),
      ),
      child: child,
    );
  }
}