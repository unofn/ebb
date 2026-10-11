import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/presets/preset_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads a full preset', () {
    final [p] = parseServicePresets('''
      [{"id": "fake_stream", "name": {"zh": "假视频", "en": "Fake Stream"},
        "aliases": ["假视"], "color": "#e50914", "icon": "fakestream",
        "category": "video", "manageUrl": "https://example.com/account",
        "cycle": "month_1"}]
    ''');
    expect(p.id, 'fake_stream');
    expect(p.nameFor('zh'), '假视频');
    expect(p.nameFor('en'), 'Fake Stream');
    expect(p.aliases, ['假视']);
    expect(p.color, 0xFFE50914);
    expect(p.icon, 'fakestream');
    expect(p.manageUrl, 'https://example.com/account');
    expect(p.cycle, const Cycle(CycleUnit.month, 1));
  });

  test('optional fields default to empty or null', () {
    final [p] = parseServicePresets('''
      [{"id": "fake", "name": {"zh": "假", "en": "Fake"}, "color": "#000000",
        "icon": null, "category": "other", "manageUrl": null}]
    ''');
    expect(p.aliases, isEmpty);
    expect(p.icon, isNull);
    expect(p.manageUrl, isNull);
    expect(p.cycle, isNull);
  });

  test('rejects a bad color, a bad cycle or a missing field', () {
    const base =
        '"id": "x", "name": {"zh": "x", "en": "x"}, "category": "other"';
    for (final bad in [
      '[{$base, "color": "red"}]',
      '[{$base, "color": "#000000", "cycle": "month"}]',
      '[{"id": "x", "color": "#000000", "category": "other"}]',
      '{}',
    ]) {
      expect(
        () => parseServicePresets(bad),
        throwsFormatException,
        reason: bad,
      );
    }
  });
}
