import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../data/database.dart';
import 'detail_line.dart';
import 'detail_providers.dart';

/// 「提前 3 天 · 09:00」, the defaults filling in what the subscription
/// leaves unset; 「不提醒」 when off.
class DetailReminderLine extends ConsumerWidget {
  const DetailReminderLine({super.key, required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DetailLine(context.l10n.detailReminder, value: _text(context, ref));
  }

  String _text(BuildContext context, WidgetRef ref) {
    final s = subscription;
    if (!s.reminderEnabled) return context.l10n.detailReminderOff;
    final defaults = ref.watch(reminderDefaultsProvider).value;
    final days = s.reminderDays ?? defaults?.daysBefore;
    final minutes = s.reminderTime ?? defaults?.minuteOfDay;
    if (days == null || minutes == null) return '';
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: true,
    );
    return '${context.l10n.reminderBefore(days)} · $time';
  }
}
