import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/services/api_providers.dart';
import 'package:lancr_app/core/models/user.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() =>
      _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  String _selectedRole = 'freelancer';
  bool _loading = false;

  Future<void> _saveRole() async {
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.put('/users/me/profile', data: {
        'role': _selectedRole,
        'profileCompleted': true,
      });

      // update auth user locally
      final user = User.fromJson(res.data['user']);
      ref.read(authProvider.notifier).setUser(user);

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose your role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hi ${user?.email ?? ''}, how will you use Lancr?'),
            const SizedBox(height: 24),
            RadioListTile<String>(
              value: 'freelancer',
              groupValue: _selectedRole,
              title: const Text('Freelancer'),
              subtitle: const Text('Find projects and clients'),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            RadioListTile<String>(
              value: 'client',
              groupValue: _selectedRole,
              title: const Text('Client'),
              subtitle: const Text('Post projects and hire talent'),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 24),
            _loading
                ? const CircularProgressIndicator()
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveRole,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}