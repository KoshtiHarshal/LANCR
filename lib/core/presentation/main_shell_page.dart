// lib/core/presentation/main_shell_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/projects/presentation/freelancer_home_page.dart';
import '../../features/projects/presentation/client_home_page.dart';
import '../theme/app_colors.dart';
import '../../main.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Reads the role once from Supabase — cached for the session
final roleProvider = FutureProvider<String?>((ref) async {
  final user = supabase.auth.currentUser;
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

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final roleAsync = ref.watch(roleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Something went wrong')),
      ),
      data: (role) {
        final isClient = role == 'client';

        final pages = isClient
            ? [
          const ClientHomePage(),
          const _PlaceholderPage(label: 'My Projects'),
          const _PlaceholderPage(label: 'Messages'),
          const _PlaceholderPage(label: 'Profile'),
        ]
            : [
          const FreelancerHomePage(),
          const _PlaceholderPage(label: 'Projects'),
          const _PlaceholderPage(label: 'Messages'),
          const _PlaceholderPage(label: 'Profile'),
        ];

        final navItems = isClient
            ? const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ]
            : const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ];

        return Scaffold(
          body: pages[currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (idx) => ref.read(bottomNavIndexProvider.notifier).state = idx,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: navItems,
          ),
        );
      },
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(child: Text('$label tab – coming soon')),
    );
  }
}