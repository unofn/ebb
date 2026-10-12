import 'package:drift/drift.dart';

import '../../../../../data/database.dart';
import '../../../../../data/enums.dart';
import 'amount_input.dart';
import 'edit_form.dart';

/// A blank form for a new subscription in [currency], starting [today];
/// reminders are on (imports leave them off, the table's default).
EditForm newForm({required String currency, required DateTime today}) =>
    EditForm(currency: currency, startDate: today).settled(today);

/// The form for the stored [sub] linked to [tagIds].
EditForm formOf(Subscription sub, Set<String> tagIds) {
  String amount(int? minor) =>
      minor == null ? '' : minorInput(minor, sub.currency);
  return EditForm(
    name: sub.name,
    plan: sub.description ?? '',
    kind: sub.kind,
    currency: sub.currency,
    price: amount(sub.priceMinor),
    cycleUnit: sub.cycleUnit ?? CycleUnit.month,
    cycleCount: '${sub.cycleCount ?? 1}',
    startDate: sub.startDate,
    nextDate: sub.nextDate,
    // 归档、暂停的行没有下次扣费是正常的，不替它算。
    nextDateFollows:
        sub.nextDate == null && sub.status == SubscriptionStatus.active,
    autoRenew: sub.autoRenew,
    trial: sub.trialEndsOn != null,
    trialEndsOn: sub.trialEndsOn,
    intro: sub.introPriceMinor != null,
    introPrice: amount(sub.introPriceMinor),
    introEndsOn: sub.introEndsOn,
    shared: sub.myShareMinor != null,
    myShare: amount(sub.myShareMinor),
    reimbursed: sub.reimbursed,
    reminder: sub.reminderEnabled,
    reminderDays: sub.reminderDays?.toString() ?? '',
    reminderTime: sub.reminderTime,
    categoryId: sub.categoryId,
    tagIds: tagIds,
    paymentMethodId: sub.paymentMethodId,
    account: sub.account ?? '',
    url: sub.url ?? '',
    notes: sub.notes ?? '',
    color: sub.color,
    colorChosen: sub.color != null,
  );
}

/// Every column the form owns, from a valid [form]. Fields that do not
/// apply (switched off, or recurring-only on a one-time buy) are written
/// as null; status and end date are left out.
SubscriptionsCompanion columnsOf(EditForm form) {
  final recurring = form.recurring;
  final reminder = recurring && form.reminder;
  final intro = recurring && form.intro;
  String? text(String value) => value.trim().isEmpty ? null : value.trim();
  return SubscriptionsCompanion(
    name: Value(form.name.trim()),
    description: Value(text(form.plan)),
    kind: Value(form.kind),
    priceMinor: Value(form.priceMinor!),
    currency: Value(form.currency),
    cycleUnit: Value(recurring ? form.cycleUnit : null),
    cycleCount: Value(recurring ? form.cycle!.count : null),
    startDate: Value(form.startDate),
    nextDate: Value(recurring ? form.nextDate : null),
    autoRenew: Value(recurring && form.autoRenew),
    categoryId: Value(form.categoryId),
    paymentMethodId: Value(form.paymentMethodId),
    account: Value(text(form.account)),
    color: Value(form.color),
    url: Value(text(form.url)),
    notes: Value(text(form.notes)),
    reminderEnabled: Value(reminder),
    reminderDays: Value(
      reminder ? int.tryParse(form.reminderDays.trim()) : null,
    ),
    reminderTime: Value(reminder ? form.reminderTime : null),
    trialEndsOn: Value(recurring && form.trial ? form.trialEndsOn : null),
    introPriceMinor: Value(
      intro ? parseMinor(form.introPrice, form.currency) : null,
    ),
    introEndsOn: Value(intro ? form.introEndsOn : null),
    myShareMinor: Value(
      form.shared ? parseMinor(form.myShare, form.currency) : null,
    ),
    reimbursed: Value(form.reimbursed),
  );
}
