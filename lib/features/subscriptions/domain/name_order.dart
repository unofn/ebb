import '../../import/plan/normalize_name.dart';

/// Orders names as people read them: case, full-width forms and spacing
/// ignored ([normalizeName]), the raw name breaking ties. Chinese stays in
/// code-point order (no pinyin).
int compareNames(String a, String b) =>
    switch (normalizeName(a).compareTo(normalizeName(b))) {
      0 => a.compareTo(b),
      final order => order,
    };
