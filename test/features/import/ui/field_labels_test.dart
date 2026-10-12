import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/features/billing/cycle.dart';
import 'package:ebb/features/import/plan/field_change.dart';
import 'package:ebb/features/import/ui/preview/field_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // 在 App 里由 MaterialApp 的本地化代理加载；纯单测要自己初始化。
  setUpAll(() => initializeDateFormatting('zh'));
  final zh = lookupAppLocalizations(const Locale('zh'));
  String text(ImportField field, Object? old, Object? now) =>
      changeText(zh, FieldChange(field, oldValue: old, newValue: now));

  test('values read as the rest of the app writes them', () {
    expect(
      text(
        ImportField.price,
        (minor: 1399, currency: 'USD'),
        (minor: 1549, currency: 'USD'),
      ),
      '价格 \$13.99 → \$15.49',
    );
    expect(
      text(ImportField.nextDate, utcDate(2026, 3, 2), null),
      '下次扣费 2026年3月2日 → —',
    );
    expect(
      text(
        ImportField.cycle,
        const Cycle(CycleUnit.month, 1),
        const Cycle(CycleUnit.year, 1),
      ),
      '周期 每月 → 每年',
    );
    expect(
      text(
        ImportField.status,
        SubscriptionStatus.active,
        SubscriptionStatus.ending,
      ),
      '状态 生效 → 到期不续',
    );
    expect(
      text(
        ImportField.kind,
        SubscriptionKind.recurring,
        SubscriptionKind.oneTime,
      ),
      '类型 周期订阅 → 一次性',
    );
  });

  test('switches, reminders, colors and times', () {
    expect(text(ImportField.autoRenew, true, false), '自动续费 是 → 否');
    expect(
      text(
        ImportField.reminder,
        (enabled: false, days: null),
        (enabled: true, days: 3),
      ),
      '提醒 不提醒 → 提前 3 天',
    );
    expect(
      text(ImportField.reminder, null, (enabled: true, days: null)),
      '提醒 — → 开启',
    );
    expect(text(ImportField.color, 0x0000FF, 0xE50914), '颜色 #0000FF → #E50914');
    expect(text(ImportField.reminderTime, 540, 75), '提醒时间 09:00 → 01:15');
    expect(text(ImportField.notes, null, '家庭'), '备注 — → 家庭');
  });
}
