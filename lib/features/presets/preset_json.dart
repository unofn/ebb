import 'dart:convert';

import '../../data/enums.dart';
import '../billing/cycle.dart';
import 'service_preset.dart';

final _hexColor = RegExp(r'^#([0-9A-Fa-f]{6})$');
final _cycle = RegExp(r'^(day|week|month|year)_([1-9]\d*)$');

/// Reads `services.json`: a list of presets. Throws [FormatException] on
/// anything malformed, so a broken asset fails tests rather than the form.
List<ServicePreset> parseServicePresets(String source) {
  final list = jsonDecode(source);
  if (list is! List) throw const FormatException('Expected a list of presets');
  return [for (final item in list) _preset(item)];
}

ServicePreset _preset(Object? item) {
  if (item case {
    'id': String id,
    'name': {'zh': String nameZh, 'en': String nameEn},
    'color': String color,
    'category': String category,
  }) {
    return ServicePreset(
      id: id,
      nameZh: nameZh,
      nameEn: nameEn,
      aliases: [...?(item['aliases'] as List?)?.cast<String>()],
      color: _parseColor(color, id),
      icon: item['icon'] as String?,
      category: category,
      manageUrl: item['manageUrl'] as String?,
      cycle: _parseCycle(item['cycle'] as String?, id),
    );
  }
  throw FormatException('Preset is missing id, name, color or category', item);
}

/// `#RRGGBB` → opaque ARGB.
int _parseColor(String hex, String id) {
  final match = _hexColor.firstMatch(hex);
  if (match == null) throw FormatException('Bad color in $id', hex);
  return 0xFF000000 | int.parse(match[1]!, radix: 16);
}

/// `month_1` → every 1 month.
Cycle? _parseCycle(String? text, String id) {
  if (text == null) return null;
  final match = _cycle.firstMatch(text);
  if (match == null) throw FormatException('Bad cycle in $id', text);
  return Cycle(CycleUnit.values.byName(match[1]!), int.parse(match[2]!));
}
