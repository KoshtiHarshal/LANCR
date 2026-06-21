// lib/core/presentation/main_shell_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/projects/presentation/browse_projects_page.dart';
import '../../features/projects/presentation/client_home_page.dart';
import '../../features/projects/presentation/client_projects_page.dart';
import '../../features/projects/presentation/freelancer_home_page.dart';
import '../../features/proposals/presentation/my_proposals_page.dart';
import '../../features/messages/presentation/conversations_page.dart';
import '../theme/app_colors.dart';

// ─────────────────────────────────────────────────────────────
// Bottom nav index state
// ─────────────────────────────────────────────────────────────
class BottomNavNotifier extends Notifier<int> {
  @override
  int build() {
    ref.watch(authProvider.select((auth) => auth.value?.id));
    return 0;
  }

  void setIndex(int index) => state = index;
}

final bottomNavIndexProvider =
NotifierProvider<BottomNavNotifier, int>(BottomNavNotifier.new);

// ─────────────────────────────────────────────────────────────
// Main Shell
// ─────────────────────────────────────────────────────────────
class MainShellPage extends ConsumerStatefulWidget {
  const MainShellPage({super.key});

  @override
  ConsumerState<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends ConsumerState<MainShellPage> {
  // Tracks when back was last pressed — for double-back-to-exit on Home
  DateTime? _lastBackPress;

  Future<bool> _onWillPop(int currentIndex) async {
    // If NOT on Home tab → go to Home tab (index 0)
    if (currentIndex != 0) {
      ref.read(bottomNavIndexProvider.notifier).setIndex(0);
      return false; // don't close app
    }

    // Already on Home tab — double press within 2s to exit
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Press back again to exit',
              style: TextStyle(color: AppColors.background)),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.textPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return false; // don't exit yet
    }

    // Second press within 2s → close app
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final roleAsync = ref.watch(currentUserRoleProvider);

    return roleAsync.when(
      loading: () => Scaffold(
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

        // ── Pages ──────────────────────────────────────────
        // Profile is no longer a tab — it opens from the home header avatar.
        // For clients, "Post" (nav index 1) is a virtual tab that pushes a
        // route instead of swapping a body, so the client pages skip it.
        final pages = isClient
            ? const [
          ClientHomePage(),     // nav 0 - Home
          ClientProjectsPage(), // nav 2 - Projects
          ConversationsPage(),  // nav 3 - Messages
        ]
            : const [
          FreelancerHomePage(), // 0 - Home
          BrowseProjectsPage(), // 1 - Browse
          MyProposalsPage(),    // 2 - Proposals
          ConversationsPage(),  // 3 - Messages
        ];

        // ── Nav items ──────────────────────────────────────
        final navItems = isClient
            ? const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Post',
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

        // Selected index is a NAV index (clients have 4 nav items / 3 pages).
        final safeIndex = currentIndex.clamp(0, navItems.length - 1);

        // Map the selected nav index to the body page.
        final Widget body = isClient
            ? pages[switch (safeIndex) { 2 => 1, 3 => 2, _ => 0 }]
            : pages[safeIndex.clamp(0, pages.length - 1)];

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            await _onWillPop(safeIndex);
          },
          child: Scaffold(
            body: body,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: (idx) {
                // Client "Post" tab pushes the post-project route and keeps
                // the current tab selected.
                if (isClient && idx == 1) {
                  context.push('/projects/post');
                  return;
                }
                ref.read(bottomNavIndexProvider.notifier).setIndex(idx);
              },
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              backgroundColor: AppColors.surface,
              elevation: 8,
              items: navItems,
            ),
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
