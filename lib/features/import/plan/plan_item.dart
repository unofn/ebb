import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/enums.dart';
import '../draft/import_draft.dart';
import '../draft/import_warning.dart';
import 'field_change.dart';

part 'plan_item.freezed.dart';

/// How an item compares with what an earlier import wrote.
enum DiffStatus {
  /// Not imported before.
  create,

  /// Imported before; fields changed or payments are missing.
  update,
  unchanged,

  /// Imported before, then deleted by the user; skipped unless unskipped.
  deletedInDb,
}

/// A payment an item would write, with its deterministic ID.
@freezed
abstract class PlannedPayment with _$PlannedPayment {
  const factory PlannedPayment({
    required String id,
    required DateTime date,
    required int amountMinor,
    required String currency,
    required PaymentOrigin origin,
  }) = _PlannedPayment;
}

/// One subscription the import would write: a single source record, or a
/// merged renewal chain.
@freezed
abstract class PlanItem with _$PlanItem {
  const factory PlanItem({
    /// The first source record's key; stable across chain decisions.
    required String id,

    /// Source records covered, in chain order.
    required List<ImportDraft> sources,

    /// The resulting subscription's fields (the last source record's;
    /// `payments` is unused, see [payments]).
    required ImportDraft body,
    required String subscriptionId,
    String? chainId,
    required DiffStatus diff,
    @Default([]) List<FieldChange> changes,
    @Default([]) List<PlannedPayment> payments,

    /// Payments in [payments] the database does not have yet.
    required int newPaymentCount,

    /// Shares its name with a record from another app.
    @Default(false) bool crossApp,
  }) = _PlanItem;

  const PlanItem._();

  List<ImportWarning> get warnings => [
    for (final source in sources) ...source.warnings,
  ];
}
