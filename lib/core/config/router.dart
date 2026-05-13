import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/onboarding/presentation/role_selection_page.dart';
import '../presentation/main_shell_page.dart';
import '../../../main.dart';
import '../../features/projects/presentation/client_home_page.dart';
import '../../features/projects/presentation/post_project_page.dart';

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

          // Check profile_completed from Supabase profiles table
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
            // Profile row doesn't exist yet → go to onboarding
            if (context.mounted) context.go('/onboarding/role');
          }
        });
      },
      loading: () {},
      error: (e, _) {
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
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
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainShellPage(),
      ),
      GoRoute(
        path: '/client/home',
        builder: (context, state) => const ClientHomePage(),
      ),
      GoRoute(
        path: '/projects/post',
        builder: (context, state) => const PostProjectPage(),
      ),
    ],
  );
});