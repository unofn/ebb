import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/storage_providers.dart';
import '../../data/database.dart';
import '../../data/enums.dart';

part 'subscription_groups.g.dart';

/// The home list's sections, in display order.
enum HomeSection { recurring, oneTime, cancelled }

class SubscriptionGroup {
  const SubscriptionGroup(this.section, this.subscriptions);

  final HomeSection section;
  final List<Subscription> subscriptions;
}

HomeSection sectionOf(Subscription s) => s.kind == SubscriptionKind.oneTime
    ? HomeSection.oneTime
    : s.status == SubscriptionStatus.cancelled
    ? HomeSection.cancelled
    : HomeSection.recurring;

/// Subscriptions not deleted, by section and name; empty sections are
/// left out. Updates as the database changes.
// 返回自写的分组类型：riverpod_generator 解析不到 drift 同一轮生成的行类型。
@riverpod
Stream<List<SubscriptionGroup>> subscriptionGroups(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final query = db.select(db.subscriptions)
    ..where((s) => s.deleted.equals(false))
    ..orderBy([(s) => OrderingTerm.asc(s.name)]);
  return query.watch().map((rows) {
    final bySection = groupBy(rows, sectionOf);
    return [
      for (final section in HomeSection.values)
        if (bySection[section] case final subscriptions?)
          SubscriptionGroup(section, subscriptions),
    ];
  });
}
