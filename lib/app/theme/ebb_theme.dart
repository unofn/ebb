import 'package:flutter/material.dart';

import 'control_themes.dart';
import 'ebb_colors.dart';
import 'ebb_type.dart';

/// Material 3 themed with the design's tokens; [brightness] picks the set.
ThemeData ebbTheme(Brightness brightness) {
  final c = brightness == Brightness.light ? EbbColors.light : EbbColors.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.surface,
    secondary: c.accent,
    onSecondary: c.surface,
    error: c.danger,
    onError: c.surface,
    surface: c.surface,
    onSurface: c.ink,
    onSurfaceVariant: c.ink2,
    outline: c.lineStrong,
    outlineVariant: c.line,
    inverseSurface: c.ink,
    onInverseSurface: c.bg,
  );
  final text = _textTheme(c);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.bg,
    fontFamily: EbbType.family,
    fontFamilyFallback: EbbType.fallback,
    textTheme: text,
    extensions: [c],
    dividerColor: c.line,
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleMedium,
    ),
    filledButtonTheme: filledButtonTheme(c, text),
    outlinedButtonTheme: outlinedButtonTheme(c, text),
    textButtonTheme: textButtonTheme(c, text),
    switchTheme: switchTheme(c),
    checkboxTheme: checkboxTheme(c),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: c.bg),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextTheme _textTheme(EbbColors c) {
  final body = EbbType.body.copyWith(color: c.ink);
  final small = EbbType.small.copyWith(color: c.ink2);
  final title = body.copyWith(fontWeight: EbbType.strong);
  return TextTheme(
    headlineMedium: EbbType.large.copyWith(color: c.ink),
    titleMedium: title,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: small,
    labelLarge: title,
    labelMedium: small,
    labelSmall: EbbType.badge,
  );
}
