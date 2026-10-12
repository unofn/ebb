import '../import/plan/normalize_name.dart';
import 'service_preset.dart';

/// Presets with their names and aliases normalized once, for typing-speed
/// search.
class PresetSearch {
  PresetSearch(this.presets)
    : _names = [
        for (final p in presets) [p.nameZh, p.nameEn].map(normalizeName),
      ],
      _aliases = [for (final p in presets) p.aliases.map(normalizeName)];

  final List<ServicePreset> presets;
  final List<Iterable<String>> _names;
  final List<Iterable<String>> _aliases;

  /// Presets whose name or an alias contains [query] (NFKC, case-folded),
  /// best first: a name starting with it, an alias starting with it, a
  /// name containing it, an alias containing it; file order within each.
  /// A blank query returns every preset.
  List<ServicePreset> search(String query) {
    final q = normalizeName(query);
    if (q.isEmpty) return presets;
    final tiers = List.generate(4, (_) => <ServicePreset>[]);
    for (final (i, preset) in presets.indexed) {
      final tier = switch ((_names[i], _aliases[i])) {
        (final n, _) when n.any((k) => k.startsWith(q)) => 0,
        (_, final a) when a.any((k) => k.startsWith(q)) => 1,
        (final n, _) when n.any((k) => k.contains(q)) => 2,
        (_, final a) when a.any((k) => k.contains(q)) => 3,
        _ => null,
      };
      if (tier != null) tiers[tier].add(preset);
    }
    return tiers.expand((tier) => tier).toList();
  }
}
