// lib/core/config/router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/onboarding/presentation/role_selection_page.dart';
import '../../features/profiles/presentation/profile_page.dart';
import '../../features/projects/presentation/browse_projects_page.dart';
import '../../features/projects/presentation/client_home_page.dart';
import '../../features/projects/presentation/post_project_page.dart';
import '../../features/profiles/presentation/edit_profile_page.dart';
import '../../features/profiles/presentation/public_profile_page.dart';
import '../../features/projects/presentation/project_detail_page.dart';
import '../../features/proposals/presentation/submit_proposal_page.dart';
import '../../features/proposals/presentation/view_proposals_page.dart';
import '../../features/projects/presentation/client_projects_page.dart';
import '../../features/projects/presentation/project_completion_page.dart';
import '../../features/messages/presentation/conversations_page.dart';
import '../../features/messages/presentation/chat_page.dart';
import '../../features/portfolio/presentation/manage_portfolio_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../presentation/main_shell_page.dart';
import '../../../main.dart';

// ─────────────────────────────────────────────────────────────
// Reusable slide-up page transition
// ─────────────────────────────────────────────────────────────
CustomTransitionPage<void> _slideUpPage({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide up from bottom
      final slideTween = Tween<Offset>(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      // Fade in slightly for polish
      final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
          .chain(CurveTween(curve: const Interval(0.0, 0.4)));

      return FadeTransition(
        opacity: animation.drive(fadeTween),
        child: SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        ),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────
// Splash screen
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
      error: (_, e) {
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
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (auth.isLoading) return null;

      final user = auth.value;
      final location = state.matchedLocation;
      final isAuthRoute = location == '/auth/login' ||
          location == '/auth/register';

      if (user == null) {
        return isAuthRoute ? null : '/auth/login';
      }

      if (isAuthRoute) return '/home';
      return null;
    },
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

      // ── Main shell ─────────────────────────────────────────
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShellPage(),
      ),

      // ── Client ─────────────────────────────────────────────
      GoRoute(
        path: '/client/home',
        builder: (context, state) => const ClientHomePage(),
      ),

      // ── Projects ───────────────────────────────────────────
      GoRoute(
        path: '/projects/post',
        builder: (context, state) => const PostProjectPage(),
      ),
      GoRoute(
        path: '/projects/:id/edit',
        builder: (context, state) => PostProjectPage(
          projectId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        path: '/projects/browse',
        builder: (context, state) => const BrowseProjectsPage(),
      ),
      GoRoute(
        path: '/client/projects',
        builder: (context, state) => const ClientProjectsPage(),
      ),
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
      GoRoute(
        path: '/projects/:id/proposals',
        builder: (context, state) => ViewProposalsPage(
          projectId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/projects/:id/completion',
        builder: (context, state) => ProjectCompletionPage(
          projectId: state.pathParameters['id']!,
        ),
      ),

      // ── Profiles — SLIDE UP transition ─────────────────────
      GoRoute(
        path: '/profile/edit', // ← must stay BEFORE /profile/:id
        pageBuilder: (context, state) => _slideUpPage(
          context: context,
          state: state,
          child: const EditProfilePage(),
        ),
      ),
      GoRoute(
        path: '/profile/me',
        pageBuilder: (context, state) => _slideUpPage(
          context: context,
          state: state,
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: '/profile/:id',
        pageBuilder: (context, state) => _slideUpPage(
          context: context,
          state: state,
          child: PublicProfilePage(
            userId: state.pathParameters['id']!,
          ),
        ),
      ),

      // ── Settings — SLIDE UP transition ─────────────────────
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _slideUpPage(
          context: context,
          state: state,
          child: const SettingsPage(),
        ),
      ),

      // ── Portfolio — SLIDE UP transition ────────────────────
      GoRoute(
        path: '/portfolio/manage',
        pageBuilder: (context, state) => _slideUpPage(
          context: context,
          state: state,
          child: const ManagePortfolioPage(),
        ),
      ),

      // ── Messaging ──────────────────────────────────────────
      GoRoute(
        path: '/messages',
        builder: (context, state) => const ConversationsPage(),
      ),
      GoRoute(
        path: '/messages/:id',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          return ChatPage(
            conversationId: state.pathParameters['id']!,
            otherPersonName: extra['otherPersonName'] as String? ?? '',
            projectTitle: extra['projectTitle'] as String? ?? '',
            projectId: extra['projectId'] as String?,
            proposalId: extra['proposalId'] as String?,
            isClient: extra['isClient'] as bool? ?? false,
          );
        },
      ),
    ],
  );
});
