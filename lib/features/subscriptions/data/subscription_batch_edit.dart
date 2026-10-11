import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../../../data/enums.dart';

/// One change applied to many subscriptions (batch edit). Absent fields
/// stay as they are on each row.
class SubscriptionBatchEdit {
  const SubscriptionBatchEdit({
    this.categoryId = const Value.absent(),
    this.status,
    this.addTagIds = const {},
    this.removeTagIds = const {},
  });

  /// `Value(null)` clears the category.
  final Value<String?> categoryId;
  final SubscriptionStatus? status;
  final Set<String> addTagIds;
  final Set<String> removeTagIds;

  /// The column changes; null when only tags change.
  SubscriptionsCompanion? get patch => !categoryId.present && status == null
      ? null
      : SubscriptionsCompanion(
          categoryId: categoryId,
          status: Value.absentIfNull(status),
        );
}
