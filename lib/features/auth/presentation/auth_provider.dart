// lib/features/auth/presentation/auth_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../main.dart';

final authProvider = StreamProvider<User?>((ref) {
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return null;

  try {
    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();
    return data['role'] as String?;
  } catch (_) {
    return null;
  }
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    return supabase.auth.currentUser;
  }

  Future<void> login(String email, String password) async {
    debugPrint('AUTH: login called for $email');
    state = const AsyncLoading();
    try {
      final res = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('AUTH: login success for ${res.user?.email}');
      state = AsyncData(res.user);
    } catch (e, st) {
      debugPrint('AUTH: login error = $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String email, String password, String role) async {
    debugPrint('AUTH: register called for $email / $role');
    state = const AsyncLoading();
    try {
      final res = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = res.user;
      if (user != null) {
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': email,
          'role': role,
          'profile_completed': false,
        });
        debugPrint('AUTH: register success for ${user.email}');
        state = AsyncData(user);
      } else {
        debugPrint('AUTH: register success — awaiting email confirmation');
        state = const AsyncData(null);
      }
    } catch (e, st) {
      debugPrint('AUTH: register error = $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    debugPrint('AUTH: logout');
    state = const AsyncLoading();
    try {
      await supabase.auth.signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final authNotifierProvider =
AsyncNotifierProvider<AuthNotifier, User?>(() => AuthNotifier());
