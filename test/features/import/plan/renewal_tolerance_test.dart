import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/plan/renewal_chains.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_drafts.dart';

void main() {
  final jan1 = utcDate(2025, 1, 1);

  // 月付容差 = max(3, 0.15 × 30.44) ≈ 4.57 天；预期续订日 2/1。
  for (final (start, linked) in [
    (utcDate(2025, 2, 5), true),
    (utcDate(2025, 2, 6), false),
    (utcDate(2025, 1, 28), true),
    (utcDate(2025, 1, 27), false),
  ]) {
    test('monthly successor starting ${start.isoDate} links: $linked', () {
      final drafts = [closedDraft('a', jan1), fakeDraft('b', start: start)];
      expect(findRenewalChains(drafts), hasLength(linked ? 1 : 0));
    });
  }

  test('short cycles get at least 3 days of tolerance', () {
    const weekly = Cycle(CycleUnit.week, 1);
    ImportDraft draft(String id, DateTime start, {bool closed = false}) =>
        fakeDraft(
          id,
          cycle: weekly,
          start: start,
          status: closed
              ? SubscriptionStatus.cancelled
              : SubscriptionStatus.active,
        );
    final a = draft('a', jan1, closed: true);
    expect(
      findRenewalChains([a, draft('b', utcDate(2025, 1, 11))]),
      isNotEmpty,
    );
    expect(findRenewalChains([a, draft('b', utcDate(2025, 1, 12))]), isEmpty);
  });
}
