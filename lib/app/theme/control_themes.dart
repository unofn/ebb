import 'package:flutter/material.dart';

import 'ebb_colors.dart';

// 主按钮用正文色实底，强调色只留给选中与进度。手机触控目标 44。

const _size = Size(0, 44);
const _padding = EdgeInsets.symmetric(horizontal: 18);
final _shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

FilledButtonThemeData filledButtonTheme(EbbColors c, TextTheme text) =>
    FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.bg,
        disabledBackgroundColor: c.surface2,
        disabledForegroundColor: c.ink3,
        minimumSize: _size,
        padding: _padding,
        shape: _shape,
        textStyle: text.labelLarge,
      ),
    );

OutlinedButtonThemeData outlinedButtonTheme(EbbColors c, TextTheme text) =>
    OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: c.surface,
        foregroundColor: c.ink,
        disabledForegroundColor: c.ink3,
        side: BorderSide(color: c.lineStrong),
        minimumSize: _size,
        padding: _padding,
        shape: _shape,
        textStyle: text.labelLarge,
      ),
    );

TextButtonThemeData textButtonTheme(EbbColors c, TextTheme text) =>
    TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.accent,
        minimumSize: _size,
        textStyle: text.labelLarge,
      ),
    );

SwitchThemeData switchTheme(EbbColors c) => SwitchThemeData(
  thumbColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.selected) ? c.surface : c.ink3,
  ),
  trackColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.selected) ? c.accent : c.surface2,
  ),
  trackOutlineColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.selected) ? c.accent : c.lineStrong,
  ),
);

CheckboxThemeData checkboxTheme(EbbColors c) => CheckboxThemeData(
  fillColor: WidgetStateProperty.resolveWith(
    (s) => s.contains(WidgetState.selected) ? c.accent : null,
  ),
  checkColor: WidgetStatePropertyAll(c.surface),
  side: BorderSide(color: c.lineStrong, width: 1.5),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
);
