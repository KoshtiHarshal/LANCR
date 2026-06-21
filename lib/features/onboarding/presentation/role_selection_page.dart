import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../main.dart';

class RoleSelectionPage extends ConsumerStatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  ConsumerState<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends ConsumerState<RoleSelectionPage> {
  String _selectedRole = 'freelancer';
  bool _loading = false;

  Future<void> _saveRole() async {
    setState(() => _loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      // Save the chosen role and mark onboarding complete so the user is
      // never sent back to role selection again.
      await supabase.from('profiles').update({
        'role': _selectedRole,
        'profile_completed': true,
      }).eq('id', user.id);

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save role: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = supabase.auth.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi ${email.split('@').first} 👋',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How will you use Lancr?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 36),

              // Role cards
              _RoleCard(
                title: 'Freelancer',
                subtitle: 'Find projects and work with clients',
                icon: Icons.work_outline,
                selected: _selectedRole == 'freelancer',
                onTap: () => setState(() => _selectedRole = 'freelancer'),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                title: 'Client',
                subtitle: 'Post projects and hire talent',
                icon: Icons.business_center_outlined,
                selected: _selectedRole == 'client',
                onTap: () => setState(() => _selectedRole = 'client'),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: _loading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
                    : ElevatedButton(
                  onPressed: _saveRole,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.shadow,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              selected ? AppColors.primary : AppColors.shadow,
              child: Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}