import 'package:flutter/material.dart';

import '../theme/ebb_colors.dart';
import '../theme/ebb_type.dart';

/// One line of an option sheet: a choice, or with no [value] a group
/// heading.
class SheetOption<T> {
  const SheetOption(
    this.value,
    this.label, {
    this.hint,
    this.danger = false,
    this.selected = false,
  });

  const SheetOption.heading(this.label)
    : value = null,
      hint = null,
      danger = false,
      selected = false;

  final T? value;
  final String label;
  final String? hint;

  /// Destructive choices are in the danger color.
  final bool danger;

  /// The current value gets a check mark.
  final bool selected;
}

/// A [SheetOption] in the sheet: tapping a choice closes the sheet with
/// its value; a heading is a small title.
class SheetOptionTile<T> extends StatelessWidget {
  const SheetOptionTile(this.option, {super.key});

  final SheetOption<T> option;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = option.value;
    if (value == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(
          option.label,
          style: EbbType.small.copyWith(
            color: c.ink2,
            fontWeight: EbbType.strong,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _texts(c)),
                if (option.selected)
                  Icon(Icons.check, size: 20, color: c.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _texts(EbbColors c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 2,
    children: [
      Text(
        option.label,
        style: EbbType.body.copyWith(color: option.danger ? c.danger : c.ink),
      ),
      if (option.hint case final hint?)
        Text(hint, style: EbbType.small.copyWith(color: c.ink2)),
    ],
  );
}
