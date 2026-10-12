import 'package:pub_semver/pub_semver.dart';

/// The newest published release on GitHub, as cached in `update_latest`.
class LatestRelease {
  const LatestRelease({required this.version, this.note, required this.url});

  final Version version;

  /// The first line of the release notes, Markdown marks removed; null
  /// when the notes are empty.
  final String? note;

  /// The release page.
  final Uri url;

  /// Whether this is strictly newer than [current] (e.g. `0.1.4`); false
  /// when [current] does not parse.
  bool isNewerThan(String current) {
    try {
      return version > Version.parse(current);
    } on FormatException {
      return false;
    }
  }

  Map<String, Object?> toJson() => {
    'version': '$version',
    'note': note,
    'url': '$url',
  };

  /// Null when [json] is not what [toJson] wrote.
  static LatestRelease? fromJson(Object? json) {
    if (json case {
      'version': final String version,
      'note': final String? note,
      'url': final String url,
    }) {
      try {
        return LatestRelease(
          version: Version.parse(version),
          note: note,
          url: Uri.parse(url),
        );
      } on FormatException {
        return null;
      }
    }
    return null;
  }
}
