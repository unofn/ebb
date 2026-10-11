import 'package:drift/drift.dart';

import '../../../data/database.dart';
import '../draft/import_draft.dart';
import '../plan/field_change.dart';
import '../plan/source_fields.dart';

/// [body]'s source fields as subscription columns; fields its app does not
/// export stay absent, so an update leaves them as the user set them.
SubscriptionsCompanion subscriptionColumns(
  ImportDraft body, {
  required String? paymentMethodId,
}) {
  final fields = sourceFieldsOf(body.sourceApp);
  Value<T> from<T>(ImportField field, T value) =>
      fields.contains(field) ? Value(value) : Value<T>.absent();
  return SubscriptionsCompanion(
    name: from(ImportField.name, body.name),
    description: from(ImportField.description, body.description),
    kind: from(ImportField.kind, body.kind),
    priceMinor: from(ImportField.price, body.priceMinor),
    currency: from(ImportField.price, body.currency),
    cycleUnit: from(ImportField.cycle, body.cycle?.unit),
    cycleCount: from(ImportField.cycle, body.cycle?.count),
    startDate: from(ImportField.startDate, body.startDate),
    nextDate: from(ImportField.nextDate, body.nextDate),
    endDate: from(ImportField.endDate, body.endDate),
    endDateUnknown: from(ImportField.endDateUnknown, body.endDateUnknown),
    status: from(ImportField.status, body.status),
    autoRenew: from(ImportField.autoRenew, body.autoRenew),
    paymentMethodId: from(ImportField.paymentMethod, paymentMethodId),
    color: from(ImportField.color, body.color),
    url: from(ImportField.url, body.url),
    notes: from(ImportField.notes, body.notes),
    reminderEnabled: from(ImportField.reminder, body.reminderEnabled),
    reminderDays: from(ImportField.reminder, body.reminderDays),
    reminderTime: from(ImportField.reminderTime, body.reminderTime),
  );
}
