// lib/features/portfolio/presentation/portfolio_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/portfolio_repository.dart';

/// Portfolio items for a given user (freelancer), newest first.
final portfolioProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  return portfolioRepository.fetchPortfolio(userId);
});
