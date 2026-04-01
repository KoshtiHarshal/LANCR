import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/models/user.dart';
import '../../../core/services/api_providers.dart';

final authProvider =
AsyncNotifierProvider<AuthNotifier, User?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<User?> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<User?> build() async {
    // On app start, try to fetch current user
    final token = await _storage.read(key: 'auth_token');
    if (token == null) return null;

    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get('/auth/me');
      return User.fromJson(res.data);
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = res.data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);

      final user = User.fromJson(res.data['user']);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String email, String password, String role) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.post('/auth/register', data: {
        'email': email,
        'password': password,
        'role': role,
      });

      final token = res.data['token'] as String;
      await _storage.write(key: 'auth_token', value: token);

      final user = User.fromJson(res.data['user']);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    state = const AsyncData(null);
  }
}