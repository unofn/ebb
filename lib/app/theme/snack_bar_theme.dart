import 'package:flutter/material.dart';

import 'ebb_colors.dart';

// 提示条：正文色实底、背景色文字，圆角 10，左右各留 16，浮在底栏上方，
// 不带操作按钮。

SnackBarThemeData snackBarTheme(EbbColors c, TextTheme text) =>
    SnackBarThemeData(
      backgroundColor: c.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: c.bg),
      behavior: SnackBarBehavior.floating,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
    );
