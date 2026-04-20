import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/models/user.dart';
import '../../../core/services/api_providers.dart';

/// Global auth state: current [User] or null.
final authProvider =
AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  void setUser(User user) {
    state = AsyncData(user);
  }

  @override
  Future<User?> build() async {
    // Called when ProviderScope is created (app start)
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      print('AUTH: no token on startup');
      return null;
    }

    try {
      print('AUTH: fetching /auth/me on startup');
      final api = ref.read(apiServiceProvider);
      final res = await api.get('/auth/me');
      final user = User.fromJson(res.data['user']);
      print('AUTH: /auth/me success for ${user.email}');
      return user;
    } catch (e) {
      print('AUTH: /auth/me failed: $e, clearing token');
      await _storage.delete(key: 'auth_token');
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    print('AUTH: login called with $email');
    state = const AsyncLoading();
    try {
      final api = ref.read(apiServiceProvider);
      print('AUTH: calling POST /auth/login');
      final res = await api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = res.data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);

      final user = User.fromJson(res.data['user']);
      print('AUTH: login success for ${user.email}');
      state = AsyncData(user);
    } catch (e, st) {
      print('AUTH: login error = $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String email, String password, String role) async {
    print('AUTH: register called with $email / $role');
    state = const AsyncLoading();
    try {
      final api = ref.read(apiServiceProvider);
      print('AUTH: calling POST /auth/register');
      final res = await api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'role': role,
      });

      final token = res.data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);

      final user = User.fromJson(res.data['user']);
      print('AUTH: register success for ${user.email}');
      state = AsyncData(user);
    } catch (e, st) {
      print('AUTH: register error = $e');
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    print('AUTH: logout');
    await _storage.delete(key: 'auth_token');
    state = const AsyncData(null);
  }
}