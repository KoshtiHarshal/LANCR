// lib/features/reviews/data/reviews_repository.dart
// Central repository for all review-related Supabase calls.
// UI providers import from here instead of calling supabase directly.
//
// NOTE: reviews.reviewer_id / reviewee_id reference auth.users, not profiles,
// so PostgREST cannot auto-embed the profile row. We resolve names with a
// manual lookup against `profiles` (whose id == auth.users.id).

import '../../../main.dart';

class ReviewsRepository {
  /// Determines whether the current user may leave a review on [projectId],
  /// who the reviewee is, and whether a review was already submitted.
  ///
  /// Returns a map with keys:
  ///  - canReview (bool)        : eligible and not yet reviewed
  ///  - alreadyReviewed (bool)  : eligible but already submitted
  ///  - revieweeId (String?)    : the user being reviewed
  ///  - revieweeName (String?)  : display name of the reviewee
  ///  - role (String?)          : current user's side — 'client' or 'freelancer'
  ///  - projectTitle (String?)
  Future<Map<String, dynamic>> getReviewContext(String projectId) async {
    final result = <String, dynamic>{
      'canReview': false,
      'alreadyReviewed': false,
      'revieweeId': null,
      'revieweeName': null,
      'role': null,
      'projectTitle': null,
    };

    final me = supabase.auth.currentUser?.id;
    if (me == null) return result;

    try {
    // 1. Project must exist and be completed.
    final project = await supabase
        .from('projects')
        .select('id, status, client_id, title')
        .eq('id', projectId)
        .maybeSingle();
    if (project == null) return result;

    result['projectTitle'] = project['title'];
    if (project['status'] != 'completed') return result;

    final clientId = project['client_id'] as String?;

    // 2. Find the hired freelancer for this project.
    final accepted = await supabase
        .from('proposals')
        .select('freelancer_id')
        .eq('project_id', projectId)
        .inFilter('status', ['accepted', 'completed'])
        .maybeSingle();
    final freelancerId = accepted?['freelancer_id'] as String?;

    // 3. Work out which side the current user is on and who they review.
    String? revieweeId;
    if (me == clientId) {
      revieweeId = freelancerId;
      result['role'] = 'client';
    } else if (me == freelancerId) {
      revieweeId = clientId;
      result['role'] = 'freelancer';
    } else {
      return result; // not a participant
    }
    if (revieweeId == null) return result;
    result['revieweeId'] = revieweeId;

    // 4. Reviewee display name.
    final profile = await supabase
        .from('profiles')
        .select('name')
        .eq('id', revieweeId)
        .maybeSingle();
    result['revieweeName'] = (profile?['name'] as String?) ?? 'this user';

    // 5. Already reviewed by this user on this project?
    final existing = await supabase
        .from('reviews')
        .select('id')
        .eq('project_id', projectId)
        .eq('reviewer_id', me)
        .maybeSingle();

    final alreadyReviewed = existing != null;
    result['alreadyReviewed'] = alreadyReviewed;
    result['canReview'] = !alreadyReviewed;
    return result;
    } catch (_) {
      // Best-effort: never surface an error from eligibility lookup
      // (e.g. transient network) as a failure of the action that called us.
      return result;
    }
  }

  /// Inserts a review. RLS enforces reviewer_id == auth.uid().
  Future<void> submitReview({
    required String projectId,
    required String revieweeId,
    required int rating,
    String? comment,
  }) async {
    final me = supabase.auth.currentUser!.id;
    final trimmed = comment?.trim();
    await supabase.from('reviews').insert({
      'project_id': projectId,
      'reviewer_id': me,
      'reviewee_id': revieweeId,
      'rating': rating,
      if (trimmed != null && trimmed.isNotEmpty) 'comment': trimmed,
    });
  }

  /// All reviews received by [userId], newest first, each with the
  /// reviewer's profile attached under the `reviewer` key.
  Future<List<Map<String, dynamic>>> fetchUserReviews(String userId) async {
    final rows = await supabase
        .from('reviews')
        .select('id, rating, comment, created_at, reviewer_id, project_id')
        .eq('reviewee_id', userId)
        .order('created_at', ascending: false);

    final result = <Map<String, dynamic>>[];
    for (final row in (rows as List)) {
      final r = Map<String, dynamic>.from(row);
      final reviewerId = r['reviewer_id'] as String?;
      if (reviewerId != null) {
        try {
          final profile = await supabase
              .from('profiles')
              .select('name, headline, avatar_url')
              .eq('id', reviewerId)
              .maybeSingle();
          r['reviewer'] = profile;
        } catch (_) {
          r['reviewer'] = null;
        }
      }
      result.add(r);
    }
    return result;
  }

  /// Average rating + count of reviews received by [userId].
  /// Reads the denormalized columns on `profiles` (kept current by a DB
  /// trigger), so this is a single-row lookup rather than a full scan.
  /// Returns { average: double, count: int }.
  Future<Map<String, dynamic>> getUserRatingStats(String userId) async {
    final profile = await supabase
        .from('profiles')
        .select('rating_avg, rating_count')
        .eq('id', userId)
        .maybeSingle();

    if (profile == null) {
      return {'average': 0.0, 'count': 0};
    }
    return {
      'average': (profile['rating_avg'] as num?)?.toDouble() ?? 0.0,
      'count': (profile['rating_count'] as num?)?.toInt() ?? 0,
    };
  }
}

final reviewsRepository = ReviewsRepository();