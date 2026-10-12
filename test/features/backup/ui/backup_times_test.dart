import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/features/backup/ui/backup_times.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('zh'));
  // 本地时间构造：结果不随运行机器的时区变。
  final now = DateTime(2026, 10, 12, 20);

  setUpAll(() => initializeDateFormatting('zh'));

  test('last backup: the time today, else the day', () {
    expect(
      lastBackupText(l10n, 'zh', DateTime(2026, 10, 12, 18, 2), now),
      '今天 18:02',
    );
    expect(lastBackupText(l10n, 'zh', DateTime(2026, 10, 1, 9), now), '10月1日');
    expect(
      lastBackupText(l10n, 'zh', DateTime(2025, 12, 30, 9), now),
      '2025年12月30日',
    );
  });

  test('automatic saves: day and time', () {
    expect(
      savedAtText(l10n, 'zh', DateTime(2026, 10, 8, 21, 5), now),
      '10月8日 21:05',
    );
    expect(
      savedAtText(l10n, 'zh', DateTime(2026, 10, 12, 9, 12), now),
      '今天 09:12',
    );
  });

  test('the confirm dialog: ISO-like, local time', () {
    expect(backupStampText(DateTime(2026, 10, 1, 14, 20)), '2026-10-01 14:20');
  });
}
