import '../import/plan/normalize_name.dart';
import 'service_preset.dart';

/// Presets with their names and aliases normalized once, for typing-speed
/// search.
class PresetSearch {
  PresetSearch(this.presets)
    : _keys = [
        for (final p in presets)
          [p.nameZh, p.nameEn, ...p.aliases].map(normalizeName).toList(),
      ];

  final List<ServicePreset> presets;
  final List<List<String>> _keys;

  /// Presets whose name or an alias contains [query] (NFKC, case-folded).
  /// Those where a name starts with it come first; otherwise file order.
  /// A blank query returns every preset.
  List<ServicePreset> search(String query) {
    final q = normalizeName(query);
    if (q.isEmpty) return presets;
    final starts = <ServicePreset>[];
    final contains = <ServicePreset>[];
    for (final (i, keys) in _keys.indexed) {
      if (keys.any((k) => k.startsWith(q))) {
        starts.add(presets[i]);
      } else if (keys.any((k) => k.contains(q))) {
        contains.add(presets[i]);
      }
    }
    return [...starts, ...contains];
  }
}
