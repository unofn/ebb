import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../app/providers/preset_providers.dart';
import 'preset_match.dart';

part 'preset_match_provider.g.dart';

/// Matches subscription names to the bundled presets.
@Riverpod(keepAlive: true)
Future<PresetMatcher> presetMatcher(Ref ref) async =>
    PresetMatcher((await ref.watch(servicePresetsProvider.future)).presets);
