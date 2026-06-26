import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/router.dart';
import 'core/notifications/push_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/config/env.dart';

// Global Supabase client — accessible anywhere via `supabase`
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
  );

  try {
    await Firebase.initializeApp();

    // Route uncaught Flutter + async errors to Crashlytics for production
    // crash visibility.
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await PushService.init();
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }

  runApp(const ProviderScope(child: LancrApp()));
}

class LancrApp extends ConsumerStatefulWidget {
  const LancrApp({super.key});

  @override
  ConsumerState<LancrApp> createState() => _LancrAppState();
}

class _LancrAppState extends ConsumerState<LancrApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Repaint when the OS theme changes while in System mode, and refresh the
    // routed pages so screens already in the stack pick up the new colours.
    setState(() {});
    themeRefreshNotifier.value++;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final platformDark = WidgetsBinding
            .instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    AppColors.isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    // J5: AppColors tokens are static runtime getters (no InheritedWidget), so
    // pages already in the navigator stack don't repaint on a theme flip. The
    // router (see routerProvider) listens to themeModeProvider and refreshes the
    // route stack, which rebuilds every on-screen page with the new colours.
    return MaterialApp.router(
      title: 'LANCR',
      theme: AppTheme.theme,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}