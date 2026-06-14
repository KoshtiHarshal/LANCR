// lib/features/reviews/presentation/reviews_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/reviews_repository.dart';

/// Whether the current user can review on a given project, who the reviewee
/// is, and whether they've already submitted. Keyed by projectId.
final reviewEligibilityProvider =
FutureProvider.family<Map<String, dynamic>, String>((ref, projectId) {
  return reviewsRepository.getReviewContext(projectId);
});

/// All reviews received by a user (newest first). Keyed by userId.
final userReviewsProvider =
FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return reviewsRepository.fetchUserReviews(userId);
});

/// Average rating + count for a user. Keyed by userId.
/// Returns { average: double, count: int }.
final userRatingStatsProvider =
FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  return reviewsRepository.getUserRatingStats(userId);
});
