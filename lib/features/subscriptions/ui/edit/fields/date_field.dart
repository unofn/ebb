import 'package:flutter/material.dart';

import '../../../../../core/local_date.dart';
import 'tap_field.dart';

/// A date-only value (UTC midnight) shown as `YYYY-MM-DD`, picked with the
/// Material date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.error = false,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool error;

  Future<void> _pick(BuildContext context) async {
    // 选择器用本机日期；只取年月日，换回 UTC 午夜，不做时区换算。
    final shown = value ?? today();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(shown.year, shown.month, shown.day),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onChanged(utcDate(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) => TapField(
    text: value?.isoDate,
    placeholder: 'YYYY-MM-DD',
    error: error,
    onTap: () => _pick(context),
  );
}
