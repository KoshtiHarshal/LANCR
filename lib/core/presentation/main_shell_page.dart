// lib/core/presentation/main_shell_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/projects/presentation/browse_projects_page.dart';
import '../../features/projects/presentation/client_home_page.dart';
import '../../features/projects/presentation/client_projects_page.dart';
import '../../features/projects/presentation/freelancer_home_page.dart';
import '../../features/proposals/presentation/my_proposals_page.dart';
import '../../features/messages/presentation/conversations_page.dart';
import '../theme/app_colors.dart';
import '../../main.dart';
import '../../features/profiles/presentation/profile_page.dart';

// ─────────────────────────────────────────────────────────────
// Bottom nav index state
// ─────────────────────────────────────────────────────────────
class BottomNavNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) => state = index;
}

final bottomNavIndexProvider =
NotifierProvider<BottomNavNotifier, int>(BottomNavNotifier.new);

// ─────────────────────────────────────────────────────────────
// Role provider
// ─────────────────────────────────────────────────────────────
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

// ─────────────────────────────────────────────────────────────
// Main Shell
// ─────────────────────────────────────────────────────────────
class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final roleAsync = ref.watch(roleProvider);

    return roleAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (e, s) => const Scaffold(
        body: Center(child: Text('Something went wrong')),
      ),
      data: (role) {
        final isClient = role == 'client';

        // ── Pages ─────────────────────────────────────────
        final pages = isClient
            ? [
          const ClientHomePage(),     // 0 - Home
          const ClientProjectsPage(), // 1 - My Projects
          const ConversationsPage(),  // 2 - Messages
          const ProfilePage(),        // 3 - Profile
        ]
            : [
          const FreelancerHomePage(), // 0 - Home
          const BrowseProjectsPage(), // 1 - Browse
          const MyProposalsPage(),    // 2 - Proposals
          const ConversationsPage(),  // 3 - Messages
          // Profile removed — accessed via avatar in AppBar
        ];

        // ── Nav items ─────────────────────────────────────
        final navItems = isClient
            ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ]
            : const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            activeIcon: Icon(Icons.send),
            label: 'Proposals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
        ];

        // Guard: clamp index so switching roles never overflows
        final safeIndex = currentIndex.clamp(0, pages.length - 1);

        return Scaffold(
          body: pages[safeIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: safeIndex,
            onTap: (idx) =>
                ref.read(bottomNavIndexProvider.notifier).setIndex(idx),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            backgroundColor: AppColors.surface,
            elevation: 8,
            items: navItems,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Placeholder page (fallback — kept for future use)
// ─────────────────────────────────────────────────────────────
class PlaceholderPage extends StatelessWidget {
  final String label;
  const PlaceholderPage({required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              '$label – coming soon',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}