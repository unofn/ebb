import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/plan/cross_app_matches.dart';
import 'package:ebb/features/import/plan/existing_snapshot.dart';
import 'package:ebb/features/import/plan/plan_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_drafts.dart';

void main() {
  final smDrafts = [
    fakeDraft('1', name: 'Fake Stream'),
    fakeDraft('2', name: 'Fake Cloud'),
  ];

  test('flags items named like a subscription imported from another app', () {
    final existing = ExistingSnapshot(
      sourceApp: SourceApp.subscriptionManager,
      otherApps: [
        const OtherAppSubscription(
          subscriptionId: 'tilla-sub',
          name: ' FAKE  stream',
          sourceApp: SourceApp.tilla,
        ),
      ],
    );
    final plan = buildPlan(parsedOf(smDrafts), existing);
    expect(plan.crossAppMatches, [
      const CrossAppMatch(
        name: 'fake stream',
        itemIds: ['subscription_manager:1'],
        existingSubscriptionIds: ['tilla-sub'],
      ),
    ]);
    expect(plan.items.map((i) => i.crossApp), [true, false]);
    // 只标记，默认不跳过。
    expect(plan.skippedItemIds, isEmpty);
  });

  test('same-app duplicates are not cross-app matches', () {
    final plan = buildPlan(
      parsedOf([...smDrafts, fakeDraft('3', name: 'Fake Stream')]),
      ExistingSnapshot.empty(SourceApp.subscriptionManager),
    );
    expect(plan.crossAppMatches, isEmpty);
  });

  test('items from two apps in one plan match each other', () {
    final tilla = buildPlan(
      parsedOf([
        fakeDraft('t1', name: 'fake stream', app: SourceApp.tilla),
      ], app: SourceApp.tilla),
      ExistingSnapshot.empty(SourceApp.tilla),
    );
    final sm = buildPlan(
      parsedOf(smDrafts),
      ExistingSnapshot.empty(SourceApp.subscriptionManager),
    );
    expect(findCrossAppMatches([...tilla.items, ...sm.items], const []), [
      const CrossAppMatch(
        name: 'fake stream',
        itemIds: ['tilla:t1', 'subscription_manager:1'],
      ),
    ]);
  });
}
