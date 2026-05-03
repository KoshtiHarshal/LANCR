import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart'; // for global `supabase` accessor

// ─────────────────────────────────────────────
// Stream-based provider — auto-updates on login/logout
// Used in router.dart SplashPage to redirect users
// ─────────────────────────────────────────────
final authProvider = StreamProvider<User?>((ref) {
  return supabase.auth.onAuthStateChange
      .map((event) => event.session?.user);
});

// ─────────────────────────────────────────────
// Notifier — handles login / register / logout actions
// ─────────────────────────────────────────────
class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // On app start, return current session user (if any)
    return supabase.auth.currentUser;
  }

  Future<void> login(String email, String password) async {
    print('AUTH: login called for $email');
    state = const AsyncLoading();
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('AUTH: login success for ${res.user?.email}');
      state = AsyncData(res.user);
    } catch (e, st) {
      print('AUTH: login error = $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String email, String password, String role) async {
    print('AUTH: register called for $email / $role');
    state = const AsyncLoading();
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        // Insert profile row into our profiles table
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': email,
          'role': role,
          'profile_completed': false,
        });
        print('AUTH: register success for ${user.email}');
        state = AsyncData(user);
      } else {
        // Supabase email confirmation enabled — user is null until confirmed
        print('AUTH: register success — awaiting email confirmation');
        state = const AsyncData(null);
      }
    } catch (e, st) {
      print('AUTH: register error = $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    print('AUTH: logout');
    await supabase.auth.signOut();
    state = const AsyncData(null);
  }
}

final authNotifierProvider =
AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());