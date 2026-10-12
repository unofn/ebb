import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/enums.dart';
import '../domain/resume_date.dart';

/// One change applied to many subscriptions (batch edit). Absent fields
/// stay as they are on each row.
class SubscriptionBatchEdit {
  const SubscriptionBatchEdit({
    this.categoryId = const Value.absent(),
    this.paymentMethodId = const Value.absent(),
    this.status,
    this.addTagIds = const {},
    this.removeTagIds = const {},
  });

  /// `Value(null)` clears the category.
  final Value<String?> categoryId;

  /// Moves rows to another payment method (e.g. a new card); `Value(null)`
  /// clears it.
  final Value<String?> paymentMethodId;

  /// Recurring rows only; one-time purchases keep theirs.
  final SubscriptionStatus? status;
  final Set<String> addTagIds;
  final Set<String> removeTagIds;

  /// The column changes for [row] on [today]; null when nothing changes.
  /// Dates follow the status, row by row:
  /// - ending: `end_date` = the row's own next date;
  /// - back from paused or archived (to active or ending): the next date
  ///   is [resumeDateOf] (a past one moves to the first charge from
  ///   today), so the time off is not charged;
  /// - active: no end date.
  SubscriptionsCompanion? patchFor(Subscription row, DateTime today) {
    var patch = SubscriptionsCompanion(
      categoryId: _changed(categoryId, row.categoryId),
      paymentMethodId: _changed(paymentMethodId, row.paymentMethodId),
    );
    final to = status;
    if (to != null &&
        to != row.status &&
        row.kind == SubscriptionKind.recurring) {
      final resumes =
          (to == SubscriptionStatus.active ||
              to == SubscriptionStatus.ending) &&
          (row.status == SubscriptionStatus.paused ||
              row.status == SubscriptionStatus.cancelled);
      final next = resumes ? resumeDateOf(row, today) : row.nextDate;
      patch = patch.copyWith(
        status: Value(to),
        nextDate: next == row.nextDate ? const Value.absent() : Value(next),
        endDate: switch (to) {
          SubscriptionStatus.ending => Value(next),
          SubscriptionStatus.active => const Value(null),
          _ => const Value.absent(),
        },
      );
    }
    return patch.toColumns(false).isEmpty ? null : patch;
  }
}

/// [value] when it is present and differs from [current], else absent.
Value<String?> _changed(Value<String?> value, String? current) =>
    value.present && value.value != current ? value : const Value.absent();
