import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../core/local_date.dart';
import '../../../reminders/domain/planned_reminder.dart';
import 'form/edit_form.dart';
import 'form/form_rows.dart';

part 'edit_start.g.dart';

/// What the form opens with.
class EditStart {
  const EditStart(this.form, this.reminders);

  final EditForm form;

  /// The defaults from settings, for hints and blank reminder fields.
  final ReminderDefaults reminders;
}

/// The form for subscription [subscriptionId], or a new one when null;
/// null when the subscription no longer exists. Read once: later writes
/// (automatic payments) must not reset what the user is typing.
@riverpod
Future<EditStart?> editStart(Ref ref, String? subscriptionId) async {
  final settings = ref.watch(localSettingsProvider);
  final reminders = ReminderDefaults(
    daysBefore: await settings.reminderDays(),
    minuteOfDay: await settings.reminderTime(),
  );
  if (subscriptionId == null) {
    final currency = await settings.baseCurrency();
    return EditStart(newForm(currency: currency, today: today()), reminders);
  }
  final repository = ref.watch(subscriptionRepositoryProvider);
  final entry = await repository.watch(subscriptionId).first;
  if (entry == null) return null;
  final tagIds = {for (final tag in entry.tags) tag.id};
  final form = formOf(entry.subscription, tagIds).settled(today());
  return EditStart(form, reminders);
}
