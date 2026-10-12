import 'package:flutter/material.dart';

import 'tap_field.dart';

/// Minutes after midnight shown as `HH:mm`, picked with the Material time
/// picker; [fallback] shows (lighter) while [value] is null.
class TimeField extends StatelessWidget {
  const TimeField({
    super.key,
    required this.value,
    required this.fallback,
    required this.onChanged,
  });

  final int? value;
  final int fallback;
  final ValueChanged<int> onChanged;

  Future<void> _pick(BuildContext context) async {
    final minutes = value ?? fallback;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (picked != null) onChanged(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) => TapField(
    text: value == null ? null : clockText(value!),
    placeholder: clockText(fallback),
    onTap: () => _pick(context),
  );
}

/// `09:00` for 540.
String clockText(int minutes) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(minutes ~/ 60)}:${two(minutes % 60)}';
}
