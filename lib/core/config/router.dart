// lib/core/router/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/onboarding/presentation/role_selection_page.dart';
import '../../features/projects/presentation/browse_projects_page.dart';
import '../../features/projects/presentation/client_home_page.dart';
import '../../features/projects/presentation/post_project_page.dart';
import '../../features/projects/presentation/project_detail_page.dart';
import '../../features/projects/presentation/submit_proposal_page.dart';
import '../presentation/main_shell_page.dart';
import '../../../main.dart';

// ─────────────────────────────────────────────────────────────
// Splash / entry screen
// ─────────────────────────────────────────────────────────────
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    auth.when(
      data: (user) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!context.mounted) return;

          if (user == null) {
            context.go('/auth/login');
            return;
          }

          try {
            final profile = await supabase
                .from('profiles')
                .select('profile_completed')
                .eq('id', user.id)
                .single();

            if (!context.mounted) return;

            if (profile['profile_completed'] == true) {
              context.go('/home');
            } else {
              context.go('/onboarding/role');
            }
          } catch (_) {
            if (context.mounted) context.go('/onboarding/role');
          }
        });
      },
      loading: () {},
      error: (_, __) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.go('/auth/login');
        });
      },
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEDE8E1),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Lancr',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF00A19B),
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(color: Color(0xFF00A19B)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────
final routerProvider = Provider((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [

      // ── Auth & Onboarding ──────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/onboarding/role',
        builder: (context, state) => const RoleSelectionPage(),
      ),

      // ── Main shell (bottom nav) ────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShellPage(),
      ),

      // ── Client ────────────────────────────────────────────
      GoRoute(
        path: '/client/home',
        builder: (context, state) => const ClientHomePage(),
      ),

      // ── Projects ──────────────────────────────────────────
      GoRoute(
        path: '/projects/post',
        builder: (context, state) => const PostProjectPage(),
      ),
      GoRoute(
        path: '/projects/browse',
        builder: (context, state) => const BrowseProjectsPage(),
      ),

      // ✅ Single correct /projects/:id route (duplicate removed)
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) => ProjectDetailPage(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/submit-proposal',
        builder: (context, state) => SubmitProposalPage(
          projectId: state.pathParameters['id']!,
        ),
      ),

      // Placeholder — View Proposals page (coming next)
      GoRoute(
        path: '/projects/:id/proposals',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Proposals')),
          body: Center(
            child: Text(
              'Proposals — coming soon\n(project: ${state.pathParameters['id']})',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ],
  );
});