import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/subscriptions/domain/duplicates.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_subscription.dart';

void main() {
  final today = utcDate(2026, 10, 12);

  Subscription inCategory(String id, String? categoryId) =>
      fakeSubscription(id: id).copyWith(categoryId: Value(categoryId));

  test('two or more counted subscriptions in one category', () {
    final groups = duplicateGroups([
      inCategory('netflix', 'video'),
      inCategory('spotify', 'audio'),
      inCategory('iqiyi', 'video'),
      inCategory('loose-1', null),
      inCategory('loose-2', null),
    ], today: today);
    expect(groups.single.categoryId, 'video');
    expect(groups.single.subscriptions.map((s) => s.id), ['netflix', 'iqiyi']);
    expect(groups.single.key, duplicateKey('video', ['iqiyi', 'netflix']));
  });

  test('rows not counted toward the monthly average do not pair up', () {
    final groups = duplicateGroups([
      inCategory('netflix', 'video'),
      inCategory(
        'trial',
        'video',
      ).copyWith(trialEndsOn: Value(utcDate(2026, 11, 1))),
      inCategory('paused', 'video').copyWith(status: SubscriptionStatus.paused),
      inCategory('ending', 'video').copyWith(status: SubscriptionStatus.ending),
      inCategory('work', 'video').copyWith(reimbursed: true),
      inCategory('once', 'video').copyWith(kind: SubscriptionKind.oneTime),
    ], today: today);
    expect(groups, isEmpty);
  });

  test('a dismissed group stays hidden until its members change', () {
    final pair = [inCategory('netflix', 'video'), inCategory('iqiyi', 'video')];
    final dismissed = {
      duplicateKey('video', ['netflix', 'iqiyi']),
    };
    expect(duplicateGroups(pair, today: today, dismissed: dismissed), isEmpty);
    final grown = [...pair, inCategory('youku', 'video')];
    expect(
      duplicateGroups(grown, today: today, dismissed: dismissed).single.key,
      isNot(dismissed.single),
    );
  });

  test('the key ignores member order and depends on the category', () {
    expect(
      duplicateKey('video', ['a', 'b']),
      duplicateKey('video', ['b', 'a']),
    );
    expect(
      duplicateKey('video', ['a', 'b']),
      isNot(duplicateKey('audio', ['a', 'b'])),
    );
  });
}
