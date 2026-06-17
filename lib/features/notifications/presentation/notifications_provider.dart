// lib/features/notifications/presentation/notifications_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart';

/// The current user's notifications (most recent 50).
///
/// Data is fetched over REST (always reliable). A Realtime channel is opened
/// purely as a *refresh trigger* — when this user's notifications change we
/// re-fetch. If Realtime ever fails, the list still loads from REST and is
/// refreshed by the explicit invalidations after mark-read actions.
final notificationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return const [];

  final channel = supabase.channel('notif:$userId');
  channel
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (_) => ref.invalidateSelf(),
      )
      .subscribe();
  ref.onDispose(() => supabase.removeChannel(channel));

  final rows = await supabase
      .from('notifications')
      .select('id, type, title, body, data, read, created_at')
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .limit(50);
  return (rows as List).map((e) => Map<String, dynamic>.from(e)).toList();
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
