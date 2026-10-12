import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../domain/name_order.dart';
import 'subscription_entry.dart';

/// Non-deleted subscriptions (only [id] when given) with their category,
/// payment method and tags, by name ([compareNames]); updates when any of
/// those tables change.
Stream<List<SubscriptionEntry>> watchEntries(AppDatabase db, {String? id}) {
  final s = db.subscriptions;
  final c = db.categories;
  final m = db.paymentMethods;
  final link = db.subscriptionTags;
  final t = db.tags;
  final query =
      db.select(s).join([
          leftOuterJoin(c, c.id.equalsExp(s.categoryId) & c.deleted.not()),
          leftOuterJoin(m, m.id.equalsExp(s.paymentMethodId) & m.deleted.not()),
          leftOuterJoin(
            link,
            link.subscriptionId.equalsExp(s.id) & link.deleted.not(),
          ),
          leftOuterJoin(t, t.id.equalsExp(link.tagId) & t.deleted.not()),
        ])
        ..where(s.deleted.not())
        ..orderBy([
          OrderingTerm.asc(s.name),
          OrderingTerm.asc(s.id),
          OrderingTerm.asc(t.name),
        ]);
  if (id != null) query.where(s.id.equals(id));
  // 一个订阅有几个标签就有几行；按订阅聚合，保持查询的顺序。
  return query.watch().map((rows) {
    final entries = <String, SubscriptionEntry>{};
    for (final row in rows) {
      final sub = row.readTable(s);
      final tag = row.readTableOrNull(t);
      final entry = entries[sub.id] ??= SubscriptionEntry(
        sub,
        category: row.readTableOrNull(c),
        paymentMethod: row.readTableOrNull(m),
        tags: [],
      );
      if (tag != null) entry.tags.add(tag);
    }
    // SQL 的排序区分大小写；按读者习惯再排一次。
    return entries.values.toList()
      ..sort((a, b) => compareNames(a.subscription.name, b.subscription.name));
  });
}
