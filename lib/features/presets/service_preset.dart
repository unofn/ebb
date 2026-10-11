import 'package:freezed_annotation/freezed_annotation.dart';

import '../billing/cycle.dart';

part 'service_preset.freezed.dart';

/// A known service the add form can start from: name, brand look, category
/// and where to manage it. Read-only; ships in `assets/presets/`.
@freezed
abstract class ServicePreset with _$ServicePreset {
  const factory ServicePreset({
    /// Permanent slug, e.g. `netflix`.
    required String id,
    required String nameZh,
    required String nameEn,

    /// Other names people search by: nicknames, old names, plan names.
    @Default(<String>[]) List<String> aliases,

    /// Brand color as ARGB, e.g. `0xFFE50914`.
    required int color,

    /// Simple Icons slug, or null when the brand has no icon there.
    String? icon,

    /// One of the built-in category keys.
    required String category,

    /// The page where the user manages or cancels; null when only the app
    /// can do it.
    String? manageUrl,

    /// The usual billing cycle, only where nearly everyone pays that way.
    Cycle? cycle,
  }) = _ServicePreset;

  const ServicePreset._();

  /// The display name for [languageCode] (`zh` or anything else → English).
  String nameFor(String languageCode) => languageCode == 'zh' ? nameZh : nameEn;
}
