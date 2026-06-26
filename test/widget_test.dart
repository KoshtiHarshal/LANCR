// Smoke tests for derived providers (no network — providers are overridden).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lancr_app/features/proposals/presentation/my_proposals_provider.dart';

void main() {
  test('myProposalStatsProvider counts by status and still counts archived',
      () async {
    final container = ProviderContainer(
      overrides: [
        myProposalsProvider.overrideWith((ref) async => [
              {'status': 'pending', 'archived': false},
              {'status': 'accepted', 'archived': false},
              // archived completed must STILL be counted (stats are frozen).
              {'status': 'completed', 'archived': true},
              {'status': 'completed', 'archived': false},
              {'status': 'rejected', 'archived': false},
            ]),
      ],
    );
    addTearDown(container.dispose);

    // Resolve the future the stats provider derives from.
    await container.read(myProposalsProvider.future);
    final stats = container.read(myProposalStatsProvider);

    expect(stats['total'], 5);
    expect(stats['pending'], 1);
    expect(stats['accepted'], 1);
    expect(stats['completed'], 2); // includes the archived one
    expect(stats['rejected'], 1);
  });

  test('myProposalStatsProvider is all-zero while loading', () {
    final container = ProviderContainer(
      overrides: [
        // Never completes → provider stays in loading.
        myProposalsProvider.overrideWith((ref) => Completer<
            List<Map<String, dynamic>>>().future),
      ],
    );
    addTearDown(container.dispose);

    final stats = container.read(myProposalStatsProvider);
    expect(stats['total'], 0);
    expect(stats['completed'], 0);
  });
}
