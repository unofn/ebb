import 'package:unorm_dart/unorm_dart.dart' as unorm;

final _whitespace = RegExp(r'\s+');

/// [name] reduced for same-name matching: NFKC (full-width ASCII becomes
/// half-width, `ﬁ` becomes `fi`, …), trimmed, inner whitespace collapsed,
/// lowercased.
String normalizeName(String name) =>
    unorm.nfkc(name).trim().replaceAll(_whitespace, ' ').toLowerCase();
