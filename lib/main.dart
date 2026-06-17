import 'package:firebase_core/firebase_core.dart';
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
    await PushService.init();
  } catch (e) {
    debugPrint('Push init skipped: $e');
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
    // Repaint when the OS theme changes while in System mode.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(themeModeProvider);
    final platformDark = WidgetsBinding
            .instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    AppColors.isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);

    return MaterialApp.router(
      title: 'LANCR',
      theme: AppTheme.theme,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}