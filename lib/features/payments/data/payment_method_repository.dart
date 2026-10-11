import 'package:drift/drift.dart';

import '../../../core/ids.dart';
import '../../../data/database.dart';

/// Payment methods for settings and the edit form.
class PaymentMethodRepository {
  PaymentMethodRepository(this._db);

  final AppDatabase _db;

  /// Non-deleted payment methods by name.
  Stream<List<PaymentMethod>> watchAll() =>
      (_db.select(_db.paymentMethods)
            ..where((m) => m.deleted.not())
            ..orderBy([(m) => OrderingTerm.asc(m.name)]))
          .watch();

  /// Adds a payment method; returns its ID.
  Future<String> create(String name, {String? note}) async {
    final id = newId();
    await _db.writer.insert(
      _db.paymentMethods,
      PaymentMethodsCompanion.insert(id: id, name: name, note: Value(note)),
    );
    return id;
  }

  /// Writes the present columns of [patch] (name, note).
  Future<void> update(String id, PaymentMethodsCompanion patch) =>
      _db.writer.update(_db.paymentMethods, id, patch);

  /// Non-deleted subscriptions paid with [id], to confirm a delete.
  Future<List<Subscription>> subscriptionsUsing(String id) => (_db.select(
    _db.subscriptions,
  )..where((s) => s.paymentMethodId.equals(id) & s.deleted.not())).get();

  /// Soft-deletes [id]; its subscriptions switch to [replaceWith] (none
  /// when null).
  Future<void> delete(String id, {String? replaceWith}) =>
      _db.transaction(() async {
        for (final sub in await subscriptionsUsing(id)) {
          await _db.writer.update(
            _db.subscriptions,
            sub.id,
            SubscriptionsCompanion(paymentMethodId: Value(replaceWith)),
          );
        }
        await _db.writer.delete(_db.paymentMethods, id);
      });
}
