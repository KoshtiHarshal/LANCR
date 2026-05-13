// lib/features/profiles/presentation/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart';

/// Fetches the full profile row for the current user from Supabase.
/// Used by both FreelancerHomePage and ClientHomePage.
final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  try {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();
    return data;
  } catch (_) {
    return null;
  }
});