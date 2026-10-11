import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/missing_rows.dart';
import '../domain/payment_run.dart';

/// Payment rows; writes go through `db.writer`.
class PaymentRepository {
  PaymentRepository(this._db);

  final AppDatabase _db;

  /// Non-deleted payments of [subscriptionId], newest first.
  Stream<List<Payment>> watchFor(String subscriptionId) =>
      (_db.select(_db.payments)
            ..where(
              (p) => p.subscriptionId.equals(subscriptionId) & p.deleted.not(),
            )
            ..orderBy([
              (p) => OrderingTerm.desc(p.paidOn),
              (p) => OrderingTerm.desc(p.id),
            ]))
          .watch();

  /// IDs of every payment of [subscriptionId], deleted ones included, so
  /// generated payments the user deleted are not generated again.
  Future<Set<String>> idsFor(String subscriptionId) async {
    final id = _db.payments.id;
    final query = _db.selectOnly(_db.payments)
      ..addColumns([id])
      ..where(_db.payments.subscriptionId.equals(subscriptionId));
    return {for (final row in await query.get()) row.read(id)!};
  }

  /// Inserts the [payments] whose ID has no row yet (deleted rows count);
  /// returns how many it inserted.
  Future<int> insertNew(Iterable<PaymentsCompanion> payments) =>
      _db.transaction(
        () => _db.insertMissing(_db.payments, {
          for (final payment in payments) payment.id.value: payment,
        }),
      );

  /// Writes an engine [run] for subscription [subscriptionId]: its new
  /// payments (existing IDs skipped, deleted ones stay deleted) and the
  /// subscription patch, together.
  Future<int> record(String subscriptionId, PaymentRun run) =>
      _db.transaction(() async {
        final inserted = await insertNew(run.payments);
        if (run.patch case final patch?) {
          await _db.writer.update(_db.subscriptions, subscriptionId, patch);
        }
        return inserted;
      });

  /// Writes a run the user confirmed (mark paid) for [subscriptionId]:
  /// its payments overwrite rows with the same ID and revive deleted ones,
  /// unlike [record]; plus the subscription patch, together.
  Future<void> recordManual(String subscriptionId, PaymentRun run) =>
      _db.transaction(() async {
        for (final payment in run.payments) {
          await _db.writer.upsert(
            _db.payments,
            payment.copyWith(deleted: const Value(false)),
          );
        }
        if (run.patch case final patch?) {
          await _db.writer.update(_db.subscriptions, subscriptionId, patch);
        }
      });

  Future<void> delete(String id) => _db.writer.delete(_db.payments, id);
}
