import 'package:flutter/material.dart';

import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';

/// The design's input box: 44 high, radius 10, a hairline that turns
/// accent on focus and danger on error.
InputDecoration fieldDecoration(
  EbbColors c, {
  String? hint,
  bool error = false,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    hintText: hint,
    hintStyle: EbbType.body.copyWith(color: c.ink3),
    isDense: true,
    filled: true,
    fillColor: c.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    enabledBorder: border(error ? c.danger : c.lineStrong),
    focusedBorder: border(error ? c.danger : c.accent),
  );
}

/// The same box around a non-text control (date, picker).
BoxDecoration fieldBox(EbbColors c, {bool error = false}) => BoxDecoration(
  color: c.surface,
  border: Border.all(color: error ? c.danger : c.lineStrong),
  borderRadius: BorderRadius.circular(10),
);
