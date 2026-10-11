import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/plan/renewal_chains.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_drafts.dart';

List<List<String>> chainIds(List<RenewalChain> chains) => [
  for (final chain in chains) [for (final m in chain.members) m.sourceId],
];

void main() {
  final jan1 = utcDate(2025, 1, 1);

  test('an active record does not chain to the next one', () {
    final drafts = [
      fakeDraft('a', start: jan1),
      fakeDraft('b', start: utcDate(2025, 2, 1)),
    ];
    expect(findRenewalChains(drafts), isEmpty);
  });

  test('an active record in the middle ends the chain there', () {
    final drafts = [
      closedDraft('a', utcDate(2024, 12, 1)),
      fakeDraft('b', start: jan1),
      fakeDraft('c', start: utcDate(2025, 2, 1)),
    ];
    expect(chainIds(findRenewalChains(drafts)), [
      ['a', 'b'],
    ]);
  });

  test("only the earlier record's cycle decides the gap", () {
    final monthlyThenYearly = [
      closedDraft('a', jan1),
      fakeDraft('b', cycle: yearly, start: utcDate(2025, 2, 1)),
    ];
    expect(findRenewalChains(monthlyThenYearly), hasLength(1));

    final yearlyThenMonthly = [
      fakeDraft(
        'a',
        cycle: yearly,
        start: jan1,
        status: SubscriptionStatus.cancelled,
      ),
      fakeDraft('b', start: utcDate(2025, 2, 1)),
    ];
    expect(findRenewalChains(yearlyThenMonthly), isEmpty);
  });

  test('chains three yearly renewals in start order, input order aside', () {
    ImportDraft year(String id, DateTime start, {bool closed = true}) =>
        fakeDraft(
          id,
          cycle: yearly,
          start: start,
          status: closed
              ? SubscriptionStatus.cancelled
              : SubscriptionStatus.active,
        );
    final drafts = [
      year('c', utcDate(2025, 1, 1), closed: false),
      year('a', utcDate(2023, 1, 1)),
      year('b', utcDate(2024, 1, 20)),
    ];
    final chains = findRenewalChains(drafts);
    expect(chainIds(chains), [
      ['a', 'b', 'c'],
    ]);
    expect(chains.single.id, 'subscription_manager:a');
  });

  test('needs the same normalized name and source', () {
    final next = utcDate(2025, 2, 1);
    expect(
      findRenewalChains([
        closedDraft('a', jan1),
        fakeDraft('b', name: '  FAKE  stream ', start: next),
      ]),
      hasLength(1),
    );
    expect(
      findRenewalChains([
        closedDraft('a', jan1),
        fakeDraft('b', name: 'Other', start: next),
      ]),
      isEmpty,
    );
    expect(
      findRenewalChains([
        closedDraft('a', jan1),
        fakeDraft('b', app: SourceApp.tilla, start: next),
      ]),
      isEmpty,
    );
  });

  test('skips one-time records and records without a start date', () {
    final drafts = [
      closedDraft('a', jan1),
      fakeDraft('b', noStart: true),
      fakeDraft('c', kind: SubscriptionKind.oneTime, cycle: null, start: jan1),
    ];
    expect(findRenewalChains(drafts), isEmpty);
  });
}
