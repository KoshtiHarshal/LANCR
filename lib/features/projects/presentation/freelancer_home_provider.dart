// lib/features/projects/presentation/freelancer_home_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Active projects (accepted proposals with project data) ──
final activeProjectsProvider =
FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return [];

  final res = await Supabase.instance.client
      .from('proposals')
      .select('id, bid_amount, project_id, projects(id, title, description, budget_min, budget_max, duration, status)')
      .eq('freelancer_id', uid)
      .eq('status', 'accepted')
      .order('created_at', ascending: false);

  return List<Map<String, dynamic>>.from(res as List);
});

// ── Stats: total, active, completed, earnings ───────────────
final proposalStatsProvider =
FutureProvider<({int total, int active, int completed, double earnings})>((ref) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return (total: 0, active: 0, completed: 0, earnings: 0.0);

  final res = await Supabase.instance.client
      .from('proposals')
      .select('status, bid_amount')
      .eq('freelancer_id', uid);

  final list = List<Map<String, dynamic>>.from(res as List);
  final total = list.length;
  final active = list.where((p) => p['status'] == 'accepted').length;
  final completed = list.where((p) => p['status'] == 'completed').length;
  final earnings = list
      .where((p) => p['status'] == 'completed')
      .fold<double>(0.0, (sum, p) {
    final amt = p['bid_amount'];
    return sum + (amt is num ? amt.toDouble() : 0.0);
  });

  return (total: total, active: active, completed: completed, earnings: earnings);
});