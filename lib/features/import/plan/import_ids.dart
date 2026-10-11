import '../../../core/ids.dart';
import '../../../core/local_date.dart';
import '../draft/import_draft.dart';
import '../draft/source_app.dart';

// 导入写出的每一行都用确定性 ID：同一来源记录重复导入落到同一行。

/// `<app>:<sourceId>`, the identity of a source record.
String sourceKeyOf(ImportDraft draft) =>
    '${draft.sourceApp.key}:${draft.sourceId}';

/// The subscription a source record (or a chain starting with it) becomes.
String importedSubscriptionId(ImportDraft draft) =>
    stableId(sourceKeyOf(draft));

String importLinkId(ImportDraft draft) =>
    stableId('${sourceKeyOf(draft)}:link');

/// The payment [draft] produced on [date] (date-only).
String importedPaymentId(ImportDraft draft, DateTime date) =>
    stableId('${sourceKeyOf(draft)}:payment:${date.isoDate}');

String importedIconId(ImportDraft draft) =>
    stableId('${sourceKeyOf(draft)}:icon');

String importedPaymentMethodId(SourceApp app, DraftPaymentMethod method) =>
    stableId('${app.key}:payment_method:${method.sourceKey}');
