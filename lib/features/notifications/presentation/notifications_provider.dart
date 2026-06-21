// lib/features/notifications/presentation/notifications_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';
import '../../auth/presentation/auth_provider.dart';

/// The current user's notifications (most recent 50), live.
///
/// Uses Supabase `.stream()` — the same realtime pattern as the messages
/// feature — so new rows and read-state changes arrive instantly without a
/// manual channel or app restart. The stream emits the current snapshot on
/// first listen, then pushes every subsequent change.
final notificationsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  // Watch auth so the stream (re)subscribes once the session is available and
  // when the signed-in user changes.
  final userId = ref.watch(authProvider).value?.id;
  if (userId == null) return Stream.value(const []);

  return supabase
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50)
      .map((rows) => rows.map((e) => Map<String, dynamic>.from(e)).toList());
});

/// Count of unread notifications (drives the bell dot).
final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => n['read'] != true).length,
    orElse: () => 0,
  );
});

class NotificationsRepository {
  Future<void> markRead(String id) async {
    await supabase.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;
    await supabase
        .from('notifications')
        .update({'read': true})
        .eq('user_id', userId)
        .eq('read', false);
  }
}

final notificationsRepository = NotificationsRepository();
