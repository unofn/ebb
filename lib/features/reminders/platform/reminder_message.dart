import '../../../app/format/money_text.dart';
import '../../../app/l10n/app_localizations.dart';
import '../domain/planned_reminder.dart';
import 'reminder_payload.dart';

/// A button on a reminder notification.
typedef ReminderButton = ({String id, String label});

/// A [PlannedReminder] as the notification shows it, in one language.
class ReminderMessage {
  const ReminderMessage({
    required this.title,
    required this.body,
    required this.payload,
    required this.buttons,
  });

  /// The text from [l10n]; 「已付款」 only for a manual renewal.
  factory ReminderMessage.of(PlannedReminder reminder, AppLocalizations l10n) {
    final name = reminder.name;
    final days = reminder.daysBefore;
    final amount = switch (reminder.amountMinor) {
      final minor? => moneyText(minor, reminder.currency),
      null => null,
    };
    final (title, body) = switch (reminder.kind) {
      ReminderKind.renewal => (
        l10n.reminderRenewalTitle(name),
        amount == null
            ? l10n.reminderRenewalBodyNoAmount(days)
            : l10n.reminderRenewalBody(days, amount),
      ),
      ReminderKind.ending => (
        l10n.reminderEndingTitle(name),
        l10n.reminderEndingBody(days),
      ),
      ReminderKind.trial => (
        l10n.reminderTrialTitle(name),
        l10n.reminderTrialBody(days),
      ),
      ReminderKind.intro => (
        l10n.reminderIntroTitle(name),
        amount == null
            ? l10n.reminderIntroBodyNoAmount(days)
            : l10n.reminderIntroBody(days, amount),
      ),
    };
    return ReminderMessage(
      title: title,
      body: body,
      payload: ReminderPayload.of(reminder),
      buttons: [
        if (reminder.canMarkPaid)
          (id: ReminderActions.markPaid, label: l10n.reminderMarkPaid),
        (id: ReminderActions.manage, label: l10n.reminderManage),
      ],
    );
  }

  final String title, body;
  final ReminderPayload payload;

  /// In display order.
  final List<ReminderButton> buttons;

  bool get canMarkPaid =>
      buttons.any((button) => button.id == ReminderActions.markPaid);
}
