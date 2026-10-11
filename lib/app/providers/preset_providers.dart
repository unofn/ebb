import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/presets/preset_json.dart';
import '../../features/presets/preset_search.dart';

part 'preset_providers.g.dart';

/// The bundled service presets, loaded once.
@Riverpod(keepAlive: true)
Future<PresetSearch> servicePresets(Ref ref) async {
  final source = await rootBundle.loadString('assets/presets/services.json');
  return PresetSearch(parseServicePresets(source));
}
