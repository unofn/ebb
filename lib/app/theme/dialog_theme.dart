import 'package:flutter/material.dart';

import 'ebb_colors.dart';

// 对话框：白底（深色为 surface）细描边，粗体标题、次色正文，按钮靠右。
// 标题与正文、正文与按钮的间距 AlertDialog 主题管不到，由各对话框传入
// 下面两个常量。

/// Under the title 12, above the buttons 16.
const dialogContentPadding = EdgeInsets.fromLTRB(24, 12, 24, 16);

/// Makes the gap between buttons 4.
const dialogButtonPadding = EdgeInsets.symmetric(horizontal: 4);

DialogThemeData dialogTheme(EbbColors c, TextTheme text) => DialogThemeData(
  backgroundColor: c.surface,
  surfaceTintColor: Colors.transparent,
  elevation: 8,
  shadowColor: Colors.black.withValues(alpha: 0.18),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: c.line),
  ),
  titleTextStyle: text.titleMedium,
  contentTextStyle: text.bodyMedium?.copyWith(color: c.ink2),
  // 按钮自带 12 的左右内边距，右边再留 12，文字与正文右缘对齐；按钮的
  // 点按范围比 44 高出 4，底部少留 2，看上去仍是 12。
  actionsPadding: const EdgeInsets.fromLTRB(24, 0, 12, 10),
  insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
  // 手机上撑满两侧留白后的宽度，宽屏不超过 400。
  constraints: const BoxConstraints(minWidth: 320, maxWidth: 400),
);
