import '../../../core/money.dart';
import '../../../data/enums.dart';
import '../draft/dropped_date_note.dart';
import '../draft/import_draft.dart';
import '../draft/import_warning.dart';
import '../draft/source_app.dart';
import 'tilla_context.dart';
import 'tilla_fields.dart';
import 'tilla_json.dart';
import 'tilla_schedule.dart';

/// Maps one Tilla record to a draft. Throws [FormatException] when it lacks
/// what a draft needs (uuid, price, currency, billingDate).
ImportDraft mapTillaSubscription(TillaSubscription s, TillaContext context) {
  final id = nonBlank(s.uuid) ?? (throw const FormatException('no uuid'));
  final price = s.price ?? (throw const FormatException('no price'));
  final rawCurrency =
      nonBlank(s.currency) ?? (throw const FormatException('no currency'));
  final billingDate =
      s.billingDate ?? (throw const FormatException('no billingDate'));

  final warnings = <ImportWarning>[];
  void warn(ImportWarningCode code, Object? detail) => warnings.add(
    ImportWarning(code, sourceId: id, detail: detail?.toString()),
  );

  final oneTime = s.isOneTime ?? false;
  final cycle = oneTime ? null : parseBillingCycle(s.billingCycle);
  if (!oneTime && cycle == null) {
    warn(ImportWarningCode.unknownBillingCycle, s.billingCycle);
  }
  final currency = normalizeCurrency(rawCurrency);
  if (!isKnownCurrency(currency)) {
    warn(ImportWarningCode.unknownCurrency, rawCurrency);
  }
  final enabled = s.isReminderEnabled ?? false;
  final reminderDays = parseReminderDays(s.reminderType);
  if (enabled && reminderDays == null) {
    warn(ImportWarningCode.unknownReminderType, s.reminderType);
  }
  final methodId = nonBlank(s.paymentMethodId);
  final methodName = context.methodNames[methodId];
  if (methodId != null && methodName == null) {
    warn(ImportWarningCode.unknownPaymentMethod, methodId);
  }
  if (!oneTime && s.nextBillDate == null) {
    warn(ImportWarningCode.invalidDate, 'nextBillDate');
  }
  final sourcePayments = s.payments ?? const [];
  if (sourcePayments.isNotEmpty) {
    warn(ImportWarningCode.unexpectedPayments, sourcePayments.length);
  }

  DateTime? dayOf(num? ms) =>
      ms == null ? null : context.zone.dayOf(ms.toInt());
  final start = dayOf(billingDate)!;
  final next = oneTime ? null : dayOf(s.nextBillDate);
  // 一次性买断只有购买日；来源里的结束日期写进备注。
  final sourceEnd = dayOf(s.endDate);
  final end = oneTime ? null : sourceEnd;
  final priceMinor = toMinor(price, currency);
  final category = s.categoryId?.toInt();

  return ImportDraft(
    sourceApp: SourceApp.tilla,
    sourceId: id,
    name: s.title?.trim() ?? '',
    kind: oneTime ? SubscriptionKind.oneTime : SubscriptionKind.recurring,
    priceMinor: priceMinor,
    currency: currency,
    cycle: cycle,
    startDate: start,
    nextDate: next,
    endDate: end,
    status: tillaStatus(s.isSuspended ?? false, end, context.today),
    autoRenew: !oneTime && s.paymentTracking == 'AUTO',
    sourceCategoryId: category == null || category == -1 ? null : '$category',
    paymentMethod: methodName == null
        ? null
        : DraftPaymentMethod(sourceKey: methodId!, name: methodName),
    color: parseColor(s.color?.toInt()),
    iconPng: decodeIcon(s.icon),
    url: nonBlank(s.link),
    notes: notesWithDroppedExpiry(
      nonBlank(s.notes),
      oneTime ? sourceEnd : null,
    ),
    reminderEnabled: enabled,
    reminderDays: reminderDays,
    payments: [
      for (final date in tillaPaymentDates(
        start,
        cycle: cycle,
        next: next,
        end: end,
        oneTime: oneTime,
        today: context.today,
      ))
        DraftPayment(
          date: date,
          amountMinor: priceMinor,
          currency: currency,
          origin: PaymentOrigin.backfilled,
        ),
    ],
    warnings: warnings,
  );
}
