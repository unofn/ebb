import 'package:flutter/material.dart';

import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import 'field_decoration.dart';

/// A text input that shows [value] and reports edits; when [value] changes
/// from elsewhere (a preset fills the name) the text follows.
class FormTextField extends StatefulWidget {
  const FormTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
    this.error = false,
    this.number = false,
    this.decimal = false,
    this.maxLines = 1,
    this.focusNode,
    this.keyboardType,
    this.bare = false,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool error;

  /// Tabular digits and a number keyboard ([decimal] allows a point).
  final bool number;
  final bool decimal;
  final int maxLines;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;

  /// No box: right-aligned text inside a list row.
  final bool bare;

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(FormTextField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = EbbType.body.copyWith(color: c.ink);
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? 2 : null,
      style: widget.number ? style.tabular : style,
      keyboardType: widget.number
          ? TextInputType.numberWithOptions(decimal: widget.decimal)
          : widget.keyboardType,
      textAlign: widget.bare ? TextAlign.end : TextAlign.start,
      decoration: widget.bare
          ? InputDecoration.collapsed(
              hintText: widget.hint,
              hintStyle: style.copyWith(color: c.ink3),
            )
          : fieldDecoration(c, hint: widget.hint, error: widget.error),
    );
  }
}
