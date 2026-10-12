import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/card_section.dart';
import '../../../app/widgets/option_sheet.dart';
import '../settings_providers.dart';
import '../widgets/settings_row.dart';
import 'notification_row.dart';

const _dayChoices = [0, 1, 2, 3, 5, 7, 14];

/// Default reminder days and time, and whether the system lets Ebb
/// notify at all.
class ReminderSection extends ConsumerWidget {
  const ReminderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final defaults = ref.watch(reminderDefaultsSettingProvider).value;
    final setting = ref.read(reminderDefaultsSettingProvider.notifier);
    return CardSection(
      title: l10n.settingsReminders,
      note: l10n.settingsRemindersNote,
      children: [
        SettingsRow(
          label: l10n.settingsReminderDays,
          value: defaults == null
              ? ''
              : l10n.settingsDaysValue(defaults.daysBefore),
          onTap: defaults == null
              ? null
              : () async {
                  final days = await _pickDays(context, defaults.daysBefore);
                  if (days != null) await setting.setDays(days);
                },
        ),
        SettingsRow(
          label: l10n.settingsReminderTime,
          value: defaults == null
              ? ''
              : _timeText(context, defaults.minuteOfDay),
          onTap: defaults == null
              ? null
              : () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _timeOf(defaults.minuteOfDay),
                    // 和显示一致，按 24 小时制选。
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    ),
                  );
                  if (time != null) {
                    await setting.setTime(time.hour * 60 + time.minute);
                  }
                },
        ),
        const NotificationRow(),
      ],
    );
  }

  Future<int?> _pickDays(BuildContext context, int current) {
    final l10n = context.l10n;
    final choices = {..._dayChoices, current}.toList()..sort();
    return showOptionSheet<int>(
      context,
      title: l10n.settingsReminderDays,
      options: [
        for (final days in choices)
          SheetOption(
            days,
            l10n.settingsDaysValue(days),
            selected: days == current,
          ),
      ],
    );
  }
}

TimeOfDay _timeOf(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

/// 「09:00」: the design writes reminder times in 24 hours.
String _timeText(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context)
        .formatTimeOfDay(_timeOf(minutes), alwaysUse24HourFormat: true);
