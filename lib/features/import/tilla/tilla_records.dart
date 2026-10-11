import '../draft/import_warning.dart';
import 'tilla_fields.dart';
import 'tilla_json.dart';

// 逐条读取原始列表：坏的一条记一条 invalidRecord，不影响其他条。

/// The root object; throws [FormatException] if its own fields are mistyped.
TillaExport readTillaExport(Map<String, dynamic> json) {
  try {
    return TillaExport.fromJson(json);
  } on TypeError catch (e) {
    throw FormatException('Not a Tilla export: $e');
  }
}

/// Subscriptions that deserialize; the rest become warnings in [warnings].
List<TillaSubscription> readTillaSubscriptions(
  List<dynamic> raw,
  List<ImportWarning> warnings,
) {
  final records = <TillaSubscription>[];
  for (final item in raw) {
    try {
      records.add(TillaSubscription.fromJson(item as Map<String, dynamic>));
    } catch (e) {
      final uuid = item is Map ? item['uuid'] : null;
      warnings.add(invalidTillaRecord(uuid is String ? uuid : null, e));
    }
  }
  return records;
}

/// Payment method titles by uuid; methods missing either are left out, so
/// subscriptions pointing at them get `unknownPaymentMethod`.
Map<String, String> readTillaMethodNames(List<dynamic> raw) {
  final names = <String, String>{};
  for (final item in raw) {
    try {
      final method = TillaPaymentMethod.fromJson(item as Map<String, dynamic>);
      final title = nonBlank(method.title);
      if (method.uuid != null && title != null) names[method.uuid!] = title;
    } catch (_) {
      // 读不出的支付方式等同于不存在。
    }
  }
  return names;
}

ImportWarning invalidTillaRecord(String? uuid, Object error) => ImportWarning(
  ImportWarningCode.invalidRecord,
  sourceId: nonBlank(uuid),
  detail: '$error',
);
