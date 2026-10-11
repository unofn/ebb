import 'package:collection/collection.dart';

import '../../../data/database.dart';
import '../draft/source_app.dart';
import 'existing_snapshot.dart';

/// Reads what planning an import from [app] needs; the plan's only
/// database access.
Future<ExistingSnapshot> loadExisting(AppDatabase db, SourceApp app) async {
  final links = await (db.select(
    db.importLinks,
  )..where((l) => l.deleted.equals(false))).get();
  final own = {
    for (final l in links)
      if (l.sourceApp == app.key) l.sourceId: l.subscriptionId,
  };
  final ownIds = own.values.toSet();
  final otherAppOf = {
    for (final l in links)
      if (l.sourceApp != app.key && !ownIds.contains(l.subscriptionId))
        l.subscriptionId: SourceApp.values.firstWhereOrNull(
          (a) => a.key == l.sourceApp,
        ),
  };
  final rows = await (db.select(
    db.subscriptions,
  )..where((s) => s.id.isIn({...ownIds, ...otherAppOf.keys}))).get();
  final ownRows = {
    for (final s in rows)
      if (ownIds.contains(s.id)) s.id: s,
  };
  return ExistingSnapshot(
    sourceApp: app,
    links: own,
    subscriptions: ownRows,
    paymentIds: await _paymentIdsOf(db, ownIds),
    paymentMethodNames: await _paymentMethodNames(
      db,
      ownRows.values.map((s) => s.paymentMethodId).nonNulls.toSet(),
    ),
    otherApps: [
      for (final s in rows)
        if (otherAppOf[s.id] case final other? when !s.deleted)
          OtherAppSubscription(
            subscriptionId: s.id,
            name: s.name,
            sourceApp: other,
          ),
    ],
  );
}

Future<Set<String>> _paymentIdsOf(
  AppDatabase db,
  Set<String> subscriptionIds,
) async {
  final id = db.payments.id;
  final query = db.selectOnly(db.payments)
    ..addColumns([id])
    ..where(db.payments.subscriptionId.isIn(subscriptionIds));
  return {for (final row in await query.get()) row.read(id)!};
}

Future<Map<String, String>> _paymentMethodNames(
  AppDatabase db,
  Set<String> ids,
) async {
  final rows = await (db.select(
    db.paymentMethods,
  )..where((m) => m.id.isIn(ids))).get();
  return {for (final m in rows) m.id: m.name};
}
