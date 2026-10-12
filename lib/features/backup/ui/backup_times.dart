import 'package:intl/intl.dart';

import '../../../app/format/date_text.dart';
import '../../../app/l10n/app_localizations.dart';
import '../../../core/local_date.dart';

// 备份时间是时刻，按本机时区显示；[now] 由界面传入 clock.now()。

/// The settings row's last backup: 「今天 18:02」 on the device's today,
/// else the day alone, 「10月1日」.
String lastBackupText(
  AppLocalizations l10n,
  String locale,
  DateTime at,
  DateTime now,
) {
  final local = at.toLocal();
  if (_sameDay(local, now.toLocal())) {
    return l10n.backupToday(DateFormat.Hm(locale).format(local));
  }
  return dayText(locale, _day(local), _day(now.toLocal()));
}

/// An automatic save in the restore sheet: 「10月8日 21:05」, today
/// 「今天 21:05」.
String savedAtText(
  AppLocalizations l10n,
  String locale,
  DateTime at,
  DateTime now,
) {
  final local = at.toLocal();
  final time = DateFormat.Hm(locale).format(local);
  if (_sameDay(local, now.toLocal())) return l10n.backupToday(time);
  return '${dayText(locale, _day(local), _day(now.toLocal()))} $time';
}

/// The confirm dialog's 「2026-10-01 14:20」, the same in every language.
String backupStampText(DateTime at) =>
    DateFormat('yyyy-MM-dd HH:mm', 'en_US').format(at.toLocal());

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _day(DateTime local) => utcDate(local.year, local.month, local.day);
