import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/router.dart';
import 'core/theme/app_theme.dart';
import 'core/config/env.dart';

// Global Supabase client — accessible anywhere via `supabase`
final supabase = Supabase.instance.client;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: LancrApp()));
}

class LancrApp extends ConsumerWidget {
  const LancrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Lancr',
      theme: AppTheme.theme,
      routerConfig: ref.watch(routerProvider), // ✅ single clean watch
      debugShowCheckedModeBanner: false,
    );
  }
}