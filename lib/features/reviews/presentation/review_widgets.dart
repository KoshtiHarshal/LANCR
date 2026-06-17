// lib/features/reviews/presentation/review_widgets.dart
//
// All review-related UI:
//  - StarRow            : read-only star display
//  - RatingSummary      : average rating + count (profile header)
//  - ReviewsList        : list of reviews received (profile body)
//  - LeaveReviewCard    : CTA shown on a completed project (completion page)
//  - showReviewDialog() : star picker + optional comment + confirm

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../data/reviews_repository.dart';
import 'reviews_provider.dart';

const _amber = Color(0xFFF5A623);

/// Relative time formatting, matching the style used elsewhere in the app.
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

// ─────────────────────────────────────────────────────────────
// Read-only star row (supports fractional ratings)
// ─────────────────────────────────────────────────────────────
class StarRow extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const StarRow({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = _amber,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating - i;
        IconData icon;
        if (filled >= 0.75) {
          icon = Icons.star_rounded;
        } else if (filled >= 0.25) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        return Icon(icon, size: size, color: color);
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Rating summary — average + count
// ─────────────────────────────────────────────────────────────
class RatingSummary extends ConsumerWidget {
  final String userId;

  /// Light colours for placement on a coloured (e.g. teal) background.
  final bool light;

  /// Centre the row (used under a centred name).
  final bool centered;

  const RatingSummary({
    super.key,
    required this.userId,
    this.light = false,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userRatingStatsProvider(userId));
    final primaryText = light ? Colors.white : AppColors.textPrimary;
    final secondaryText =
        light ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary;
    final alignment =
        centered ? MainAxisAlignment.center : MainAxisAlignment.start;

    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        final count = stats['count'] as int? ?? 0;
        final average = (stats['average'] as num?)?.toDouble() ?? 0.0;

        if (count == 0) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignment,
            children: [
              const StarRow(rating: 0, size: 16),
              const SizedBox(width: 8),
              Text(
                'No reviews yet',
                style: TextStyle(color: secondaryText, fontSize: 13),
              ),
            ],
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: alignment,
          children: [
            Text(
              average.toStringAsFixed(1),
              style: TextStyle(
                color: primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            StarRow(rating: average, size: 16),
            const SizedBox(width: 6),
            Text(
              '($count ${count == 1 ? 'review' : 'reviews'})',
              style: TextStyle(color: secondaryText, fontSize: 13),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reviews list — all reviews received by a user
// ─────────────────────────────────────────────────────────────
class ReviewsList extends ConsumerWidget {
  final String userId;
  const ReviewsList({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return reviewsAsync.when(
      loading: () => Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => Text(
        'Could not load reviews.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      data: (reviews) {
        if (reviews.isEmpty) {
          return Text(
            'No reviews yet.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          );
        }
        return Column(
          children: [
            for (var i = 0; i < reviews.length; i++) ...[
              _ReviewTile(review: reviews[i]),
              if (i != reviews.length - 1)
                Divider(color: AppColors.shadow, height: 22),
            ],
          ],
        );
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Map<String, dynamic> review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final reviewer = review['reviewer'] as Map?;
    final name = (reviewer?['name'] as String?) ?? 'LANCR member';
    final avatarUrl = reviewer?['avatar_url'] as String?;
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = (review['comment'] as String?)?.trim();
    final createdLabel = _timeAgo(review['created_at'] as String?);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final reviewerId = review['reviewer_id'] as String?;

    return InkWell(
      onTap: reviewerId == null
          ? null
          : () => context.push('/profile/$reviewerId'),
      borderRadius: BorderRadius.circular(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight,
                backgroundImage:
                avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                child: avatarUrl == null
                    ? Text(
                  initial,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                    if (createdLabel.isNotEmpty)
                      Text(
                        createdLabel,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              StarRow(rating: rating, size: 15),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Leave-review CTA card (shown on a completed project)
// ─────────────────────────────────────────────────────────────
class LeaveReviewCard extends ConsumerWidget {
  final String projectId;
  const LeaveReviewCard({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eligibilityAsync = ref.watch(reviewEligibilityProvider(projectId));

    return eligibilityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (ctx) {
        final canReview = ctx['canReview'] as bool? ?? false;
        final alreadyReviewed = ctx['alreadyReviewed'] as bool? ?? false;
        final revieweeId = ctx['revieweeId'] as String?;
        final revieweeName = ctx['revieweeName'] as String? ?? 'this user';

        if (alreadyReviewed) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: _amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.star_rounded, size: 18, color: _amber),
                SizedBox(width: 8),
                Text(
                  'You\'ve reviewed this project',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }

        if (!canReview || revieweeId == null) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.shadow),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: _amber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.rate_review_outlined,
                        color: _amber, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Leave a Review',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Share your experience working with $revieweeName.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final submitted = await showReviewDialog(
                      context,
                      projectId: projectId,
                      revieweeId: revieweeId,
                      revieweeName: revieweeName,
                    );
                    if (submitted == true) {
                      ref.invalidate(reviewEligibilityProvider(projectId));
                      ref.invalidate(userReviewsProvider(revieweeId));
                      ref.invalidate(userRatingStatsProvider(revieweeId));
                    }
                  },
                  icon: const Icon(Icons.star_rounded, size: 18),
                  label: const Text('Rate & Review'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Review dialog — star picker + optional comment + confirm
// Returns true if a review was submitted.
// ─────────────────────────────────────────────────────────────
Future<bool?> showReviewDialog(
    BuildContext context, {
      required String projectId,
      required String revieweeId,
      required String revieweeName,
    }) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ReviewDialog(
      projectId: projectId,
      revieweeId: revieweeId,
      revieweeName: revieweeName,
    ),
  );
}

class _ReviewDialog extends StatefulWidget {
  final String projectId;
  final String revieweeId;
  final String revieweeName;

  const _ReviewDialog({
    required this.projectId,
    required this.revieweeId,
    required this.revieweeName,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _submitting = false;

  static const _labels = {
    1: 'Poor',
    2: 'Fair',
    3: 'Good',
    4: 'Very good',
    5: 'Excellent',
  };

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) return;
    setState(() => _submitting = true);
    try {
      await reviewsRepository.submitReview(
        projectId: widget.projectId,
        revieweeId: widget.revieweeId,
        rating: _rating,
        comment: _commentController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: const Color(0xFFD94F4F),
            behavior: SnackBarBehavior.floating,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Review ${widget.revieweeName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 17,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Star picker
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final value = i + 1;
              final selected = value <= _rating;
              return IconButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _rating = value),
                iconSize: 36,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                constraints: const BoxConstraints(),
                icon: Icon(
                  selected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: _amber,
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Text(
            _rating == 0 ? 'Tap a star to rate' : _labels[_rating]!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            maxLines: 4,
            maxLength: 500,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Share details about your experience (optional)',
              hintStyle: TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.shadow),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.shadow),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text('Cancel',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: (_rating == 0 || _submitting) ? null : _submit,
          child: _submitting
              ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Colors.white),
          )
              : const Text('Submit'),
        ),
      ],
    );
  }
}