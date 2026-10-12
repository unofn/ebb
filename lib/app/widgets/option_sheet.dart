import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';
import 'sheet_option.dart';

export 'sheet_option.dart';

/// A bottom sheet titled [title] listing [options], with an optional
/// [note] under the title and [foot] under the options; resolves to the
/// picked value, null when dismissed.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  String? note,
  String? foot,
}) {
  final c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    // 盖住底栏和侧栏，和画板一样占满屏幕底部。
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: c.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.8,
    ),
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.lineStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              title,
              style: EbbType.body.copyWith(
                color: c.ink,
                fontWeight: EbbType.strong,
              ),
            ),
          ),
          if (note != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(note, style: EbbType.small.copyWith(color: c.ink2)),
            ),
          for (final option in options) SheetOptionTile(option),
          if (foot != null)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(foot, style: EbbType.small.copyWith(color: c.ink2)),
              ),
            ),
        ],
      ),
    ),
  );
}
