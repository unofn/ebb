import '../draft/source_app.dart';
import 'field_change.dart';

const _shared = {
  ImportField.name,
  ImportField.kind,
  ImportField.price,
  ImportField.cycle,
  ImportField.startDate,
  ImportField.nextDate,
  ImportField.endDate,
  ImportField.endDateUnknown,
  ImportField.status,
  ImportField.autoRenew,
  ImportField.paymentMethod,
  ImportField.color,
  ImportField.notes,
  ImportField.reminder,
};

/// The fields [app]'s export carries. A re-import overwrites only these, so
/// what the user added in Ebb (a Tilla record's description, a
/// SubscriptionManager record's URL) survives.
Set<ImportField> sourceFieldsOf(SourceApp app) => switch (app) {
  SourceApp.tilla => {..._shared, ImportField.url},
  SourceApp.subscriptionManager => {
    ..._shared,
    ImportField.description,
    ImportField.reminderTime,
  },
};
