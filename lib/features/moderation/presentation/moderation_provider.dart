// lib/features/moderation/presentation/moderation_provider.dart
//
// Trust & safety: reporting and blocking. Reports are insert-only (reviewed
// out-of-band). Blocks are owner-managed and used to hide a blocked user's
// content from the blocker (conversations, browse).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../main.dart';

/// Ids the current user has blocked — used to filter their content out.
final blockedUserIdsProvider = FutureProvider<Set<String>>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return <String>{};
  try {
    final rows = await supabase
        .from('blocked_users')
        .select('blocked_id')
        .eq('blocker_id', userId);
    return (rows as List).map((e) => e['blocked_id'] as String).toSet();
  } catch (_) {
    return <String>{};
  }
});

/// Blocked users with their profile (name, avatar) attached — for the
/// "Blocked accounts" management screen. blocked_id references auth.users, so
/// profile names are batch-fetched (can't be embedded via the FK).
final blockedUsersDetailProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return [];
  final rows = await supabase
      .from('blocked_users')
      .select('blocked_id, created_at')
      .eq('blocker_id', userId)
      .order('created_at', ascending: false);
  final list = (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
  final ids =
      list.map((e) => e['blocked_id'] as String?).whereType<String>().toList();
  if (ids.isEmpty) return list;
  try {
    final profiles = await supabase
        .from('profiles')
        .select('id, name, avatar_url')
        .inFilter('id', ids);
    final byId = {for (final p in (profiles as List)) p['id'] as String: p};
    for (final r in list) {
      r['profile'] = byId[r['blocked_id']];
    }
  } catch (_) {}
  return list;
});

/// Submit a report against a user and/or a project.
Future<void> submitReport({
  String? reportedUserId,
  String? reportedProjectId,
  required String reason,
  String? details,
}) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) throw Exception('Not signed in');
  final trimmed = details?.trim();
  final payload = <String, dynamic>{
    'reporter_id': me,
    'reason': reason,
  };
  if (reportedUserId != null) payload['reported_user_id'] = reportedUserId;
  if (reportedProjectId != null) {
    payload['reported_project_id'] = reportedProjectId;
  }
  if (trimmed != null && trimmed.isNotEmpty) payload['details'] = trimmed;
  await supabase.from('reports').insert(payload);
}

/// Block a user (idempotent — ignores duplicate-key).
Future<void> blockUser(String userId) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null || me == userId) return;
  await supabase.from('blocked_users').upsert(
    {'blocker_id': me, 'blocked_id': userId},
    onConflict: 'blocker_id,blocked_id',
    ignoreDuplicates: true,
  );
}

/// Unblock a user.
Future<void> unblockUser(String userId) async {
  final me = supabase.auth.currentUser?.id;
  if (me == null) return;
  await supabase
      .from('blocked_users')
      .delete()
      .eq('blocker_id', me)
      .eq('blocked_id', userId);
}
