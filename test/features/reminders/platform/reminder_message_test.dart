import 'package:ebb/app/l10n/app_localizations.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/reminders/platform/reminder_message.dart';
import 'package:ebb/features/reminders/platform/reminder_payload.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final zh = lookupAppLocalizations(const Locale('zh'));
  final en = lookupAppLocalizations(const Locale('en'));
  PlannedReminder reminder(
    ReminderKind kind, {
    int days = 3,
    int? amount = 1500,
    bool canMarkPaid = false,
  }) => PlannedReminder(
    id: 7,
    subscriptionId: 'sub-1',
    kind: kind,
    fireAt: DateTime(2026, 10, 17, 9),
    name: 'Netflix',
    eventDate: utcDate(2026, 10, 20),
    daysBefore: days,
    amountMinor: amount,
    currency: 'CNY',
    canMarkPaid: canMarkPaid,
  );
  List<String> texts(PlannedReminder r, AppLocalizations l10n) {
    final message = ReminderMessage.of(r, l10n);
    return [message.title, message.body];
  }

  test('renewal, in Chinese and English', () {
    final renewal = reminder(ReminderKind.renewal);
    expect(texts(renewal, zh), ['Netflix 即将扣费', '3 天后扣费 ¥15.00']);
    expect(texts(renewal, en), ['Netflix renews soon', '¥15.00 due in 3 days']);
    final tomorrow = reminder(ReminderKind.renewal, days: 1, amount: null);
    expect(texts(tomorrow, zh).last, '明天扣费');
  });

  test('ending, trial and intro', () {
    expect(texts(reminder(ReminderKind.ending, days: 0), zh), [
      'Netflix 即将到期',
      '今天到期，不再续费',
    ]);
    expect(texts(reminder(ReminderKind.trial), zh).last, '试用 3 天后到期，不取消会自动扣费');
    expect(
      texts(reminder(ReminderKind.intro, amount: 3000), zh).last,
      '首期优惠 3 天后结束，之后 ¥30.00',
    );
  });

  test('「已付款」 only for a manual renewal; payload names the day', () {
    final manual = ReminderMessage.of(
      reminder(ReminderKind.renewal, canMarkPaid: true),
      zh,
    );
    expect(manual.buttons, [
      (id: ReminderActions.markPaid, label: '已付款'),
      (id: ReminderActions.manage, label: '管理订阅'),
    ]);
    expect(manual.canMarkPaid, isTrue);
    expect(manual.payload.eventDate, utcDate(2026, 10, 20));

    final auto = ReminderMessage.of(reminder(ReminderKind.renewal), zh);
    expect(auto.buttons.map((b) => b.id), [ReminderActions.manage]);
  });
}
