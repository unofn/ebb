import 'package:flutter/material.dart';

import '../theme/dialog_theme.dart';
import '../theme/ebb_colors.dart';

/// A dialog with one text field. Resolves to the entered text (trimmed),
/// to `''` when the user picks [clearLabel], or to null when cancelled.
/// [validate] returns the error to show, or null when the text is fine.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String? Function(String text)? validate,
  TextInputType? keyboardType,
  String? clearLabel,
}) => showDialog<String>(
  context: context,
  builder: (context) => _TextPrompt(
    title: title,
    label: label,
    initial: initial,
    validate: validate ?? (_) => null,
    keyboardType: keyboardType,
    clearLabel: clearLabel,
  ),
);

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    required this.initial,
    required this.validate,
    this.keyboardType,
    this.clearLabel,
  });

  final String title, label, initial;
  final String? Function(String text) validate;
  final TextInputType? keyboardType;
  final String? clearLabel;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    final error = widget.validate(text);
    if (error != null) return setState(() => _error = error);
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    return AlertDialog(
      contentPadding: dialogContentPadding,
      buttonPadding: dialogButtonPadding,
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(labelText: widget.label, errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        if (widget.clearLabel case final clear?)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: context.colors.ink2),
            onPressed: () => Navigator.of(context).pop(''),
            child: Text(clear),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(material.cancelButtonLabel),
        ),
        TextButton(onPressed: _submit, child: Text(material.saveButtonLabel)),
      ],
    );
  }
}
