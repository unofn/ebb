import 'package:ebb/features/import/plan/category_choice.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/plan/existing_snapshot.dart';
import 'package:ebb/features/import/plan/import_ids.dart';
import 'package:ebb/features/import/plan/import_plan.dart';
import 'package:ebb/features/import/plan/plan_builder.dart';
import 'package:ebb/features/import/plan/plan_decisions.dart';
import 'package:ebb/features/import/plan/plan_item.dart';
import 'package:ebb/features/import/plan/plan_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_drafts.dart';

const _app = SourceApp.subscriptionManager;

void main() {
  final a = closedDraft('a', utcDate(2025, 1, 1), price: 1200);
  final b = fakeDraft(
    'b',
    start: utcDate(2025, 2, 1),
    paidUntil: utcDate(2025, 4, 1),
    labels: ['Video', 'Family'],
  );
  final other = fakeDraft('x', name: 'Fake Cloud', labels: ['Work']).copyWith(
    warnings: [const ImportWarning(ImportWarningCode.unexpectedDuration)],
  );
  final parsed = parsedOf([b, other, a]).copyWith(
    fileWarnings: [const ImportWarning(ImportWarningCode.unsupportedVersion)],
  );
  ImportPlan plan() => buildPlan(parsed, ExistingSnapshot.empty(_app));

  test('merges a chain by default into one item with the first id', () {
    final items = plan().items;
    expect(items.map((i) => i.id), [
      'subscription_manager:a',
      'subscription_manager:x',
    ]);
    final chain = items.first;
    expect(chain.subscriptionId, importedSubscriptionId(a));
    expect(chain.sources.map((s) => s.sourceId), ['a', 'b']);
    expect(chain.body.priceMinor, 1500);
    expect(chain.diff, DiffStatus.create);
    expect(chain.payments.map((p) => p.amountMinor), [1200, 1500, 1500]);
    expect(chain.newPaymentCount, 3);
    expect(plan().chains.single.id, chain.chainId);
  });

  test('splitting a chain imports its records as they are; merging undoes', () {
    final split = plan().splitChain('subscription_manager:a');
    expect(split.items.map((i) => i.id), [
      'subscription_manager:b',
      'subscription_manager:x',
      'subscription_manager:a',
    ]);
    expect(split.items.last.payments, hasLength(1));
    expect(split.items.last.body.endDateUnknown, isTrue);
    expect(split.mergeChain('subscription_manager:a'), plan());
  });

  test('skip and unskip by item id', () {
    final skipped = plan().skip('subscription_manager:x');
    expect(skipped.skippedItemIds, {'subscription_manager:x'});
    expect(skipped.subscriptionCount, 1);
    expect(skipped.unskip('subscription_manager:x').skippedItemIds, isEmpty);
  });

  test('starts with every source category and label unmapped', () {
    final tilla = buildPlan(
      parsedOf(
        [fakeDraft('t', app: SourceApp.tilla, sourceCategoryId: '3')],
        app: SourceApp.tilla,
        sourceCategories: {'3': 1},
      ),
      ExistingSnapshot.empty(SourceApp.tilla),
    );
    const undecided = CategoryChoice.undecided();
    expect(tilla.categoryMapping, {'3': undecided});
    expect(plan().labelCategoryMapping, {
      'Video': undecided,
      'Family': undecided,
      'Work': undecided,
    });
  });

  test('the category comes from the source category, else the first '
      'mapped label', () {
    final mapped = plan()
        .mapLabel('Family', const CategoryChoice.category('video'))
        .mapLabel('Work', const CategoryChoice.category('cloud'));
    final chain = mapped.items.first.body;
    expect(mapped.categoryKeyFor(chain), 'video');
    final tillaBody = fakeDraft('t', sourceCategoryId: '3', labels: ['Work']);
    expect(mapped.categoryKeyFor(tillaBody), 'cloud');
    expect(
      mapped
          .mapCategory('3', const CategoryChoice.category('gaming'))
          .categoryKeyFor(tillaBody),
      'gaming',
    );
  });

  test('「no category」 is a decision but maps nothing, like undecided', () {
    final body = fakeDraft('t', sourceCategoryId: '3', labels: ['Work']);
    final none = plan()
        .mapCategory('3', const CategoryChoice.none())
        .mapLabel('Work', const CategoryChoice.category('cloud'));
    expect(none.categoryMapping['3'], const CategoryChoice.none());
    expect(none.categoryMapping['3'], isNot(const CategoryChoice.undecided()));
    expect(none.categoryKeyFor(body), 'cloud', reason: 'falls to the label');
    expect(
      plan().mapCategory('3', const CategoryChoice.none()).categoryKeyFor(body),
      isNull,
    );
  });

  test('summarizes the plan for the preview header', () {
    final p = plan();
    expect(p.sourceRecordCount, 3);
    expect(p.subscriptionCount, 2);
    expect(p.countsByDiff, {DiffStatus.create: 2});
    expect(p.countsByStatus, {SubscriptionStatus.active: 2});
    expect(p.paymentsToAdd, 4);
    expect(p.warningCount, 2);
  });

  test('a chain whose records were imported apart before is split', () {
    final existing = ExistingSnapshot(
      sourceApp: _app,
      links: {'a': 'sub-a', 'b': 'sub-b'},
    );
    final p = buildPlan(parsed, existing);
    expect(p.splitChainIds, {'subscription_manager:a'});
    expect(p.items, hasLength(3));
  });
}
