// lib/core/notifications/push_service.dart
//
// Firebase Cloud Messaging wiring: registers the device token against the
// signed-in user (profiles.fcm_token), shows foreground notifications, and
// keeps the token fresh. Background/killed notifications are delivered and
// displayed by the OS automatically (we send FCM "notification" messages).
//
// The "Push notifications" setting is enforced here: when disabled we clear
// the device token so the server has nothing to push to (in-app notifications
// still work). When enabled we (re)register the token.

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

const _channelId = 'lancr_default';

/// Shared preference key for the push toggle (used by Settings too).
const pushPrefKey = 'pref_push_notifications';

final _local = FlutterLocalNotificationsPlugin();

/// Background isolate handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  // FCM notification messages are auto-displayed by the OS when backgrounded.
}

class PushService {
  /// The conversation currently open on screen (set by ChatPage). Foreground
  /// notifications for this conversation are suppressed so chatting isn't
  /// interrupted.
  static String? activeConversationId;

  static const _mutedKey = 'muted_conversations';
  static final Set<String> _mutedConversations = {};

  static bool isMuted(String conversationId) =>
      _mutedConversations.contains(conversationId);

  static Future<void> setMuted(String conversationId, bool muted) async {
    if (muted) {
      _mutedConversations.add(conversationId);
    } else {
      _mutedConversations.remove(conversationId);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_mutedKey, _mutedConversations.toList());
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(pushPrefKey) ?? true;
  }

  /// Persist the toggle and apply it immediately.
  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(pushPrefKey, value);
    if (value) {
      await registerToken();
    } else {
      await _clearToken();
    }
  }

  static Future<void> init() async {
    const channel = AndroidNotificationChannel(
      _channelId,
      'LANCR notifications',
      description: 'Proposals, messages and project updates',
      importance: Importance.high,
    );
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    final prefs = await SharedPreferences.getInstance();
    _mutedConversations.addAll(prefs.getStringList(_mutedKey) ?? const []);

    // Foreground messages → show a local notification (unless the user is in
    // that chat or has muted it).
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      final convId = message.data['conversation_id'] as String?;
      if (convId != null &&
          (convId == activeConversationId || isMuted(convId))) {
        return;
      }
      _local.show(
        n.hashCode,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            'LANCR notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });

    // Keep the saved token current (only while push is enabled).
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      if (await isEnabled()) await _saveTokenValue(token);
    });

    // Sync token to the current preference whenever a user signs in.
    supabase.auth.onAuthStateChange.listen((state) {
      if (state.session != null) _applyPref();
    });

    if (supabase.auth.currentUser != null) await _applyPref();
  }

  /// Register or clear the token to match the saved preference.
  static Future<void> _applyPref() async {
    if (await isEnabled()) {
      await registerToken();
    } else {
      await _clearToken();
    }
  }

  /// Requests permission and saves the FCM token — unless push is disabled.
  static Future<void> registerToken() async {
    if (!await isEnabled()) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveTokenValue(token);
    } catch (e) {
      debugPrint('PushService.registerToken failed: $e');
    }
  }

  static Future<void> _saveTokenValue(String token) async {
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await supabase
          .from('profiles')
          .update({'fcm_token': token}).eq('id', uid);
    } catch (e) {
      debugPrint('PushService save token failed: $e');
    }
  }

  /// Remove the token so the server stops pushing to this device.
  static Future<void> _clearToken() async {
    final uid = supabase.auth.currentUser?.id;
    if (uid != null) {
      try {
        await supabase
            .from('profiles')
            .update({'fcm_token': null}).eq('id', uid);
      } catch (e) {
        debugPrint('PushService clear token failed: $e');
      }
    }
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}
