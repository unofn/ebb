import 'package:freezed_annotation/freezed_annotation.dart';

part 'import_warning.freezed.dart';

/// Why an import needs the user's attention. Codes are not localized here;
/// the UI maps each to a message.
enum ImportWarningCode {
  // 文件级
  /// Tilla `version` ≠ 4 or SubscriptionManager `appVersion` ≠ 79.
  unsupportedVersion,

  /// Tilla: no recurring dates to infer the export time zone; used local.
  guessedTimezone,

  // 两个来源共用
  /// A record could not be read and was skipped.
  invalidRecord,
  unknownCurrency,
  invalidDate,
  invalidColor,

  // Tilla
  unknownBillingCycle,
  unknownReminderType,

  /// `paymentMethodId` not found in `paymentMethods`.
  unknownPaymentMethod,

  /// `payments` is non-empty; its structure is unknown, so it is ignored.
  unexpectedPayments,

  // SubscriptionManager
  unknownCycleRhythm,

  /// `duration` ≠ -1.
  unexpectedDuration,

  /// Recurring without `firstBillingDate`: no payments, no next date.
  missingStartDate,

  /// One-time with neither `firstBillingDate` nor `expiringDate`.
  noDates,

  /// One-time with only `expiringDate`, used as the purchase date.
  expiryAsPurchaseDate,

  /// A notification whose rhythm is not "N days before" (6).
  unknownReminderRhythm,
}

@freezed
abstract class ImportWarning with _$ImportWarning {
  /// [sourceId] is null for file-level warnings; [detail] is the raw value.
  const factory ImportWarning(
    ImportWarningCode code, {
    String? sourceId,
    String? detail,
  }) = _ImportWarning;
}
