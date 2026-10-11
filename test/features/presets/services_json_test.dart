import 'dart:io';

import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/presets/preset_icons.dart';
import 'package:ebb/features/presets/preset_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final presets = parseServicePresets(
    File('assets/presets/services.json').readAsStringSync(),
  );

  test('parses every preset', () {
    expect(presets, hasLength(greaterThan(90)));
  });

  test('ids are unique lowercase slugs', () {
    final ids = presets.map((p) => p.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[a-z0-9_]+$')));
    }
  });

  test('categories are built-in keys', () {
    final keys = builtInCategories.values.expand((k) => k).toSet();
    for (final p in presets) {
      expect(keys, contains(p.category), reason: p.id);
    }
  });

  test('every icon has a glyph and every glyph is used', () {
    final used = {for (final p in presets) ?p.icon};
    expect(used, presetIcons.keys.toSet());
  });

  test('names are filled and manage links are https', () {
    for (final p in presets) {
      expect(p.nameZh.trim(), isNotEmpty, reason: p.id);
      expect(p.nameEn.trim(), isNotEmpty, reason: p.id);
      if (p.manageUrl case final url?) {
        expect(Uri.parse(url).scheme, 'https', reason: p.id);
      }
    }
  });
}
