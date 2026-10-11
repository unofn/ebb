import '../../features/import/draft/import_warning.dart';
import 'app_localizations.dart';

/// What [warning] means for the user, with its raw value when it has one.
String warningMessage(AppLocalizations l10n, ImportWarning warning) {
  final message = _messageOf(l10n, warning.code);
  final detail = warning.detail;
  return detail == null || detail.isEmpty
      ? message
      : l10n.warningDetail(message, detail);
}

String _messageOf(
  AppLocalizations l10n,
  ImportWarningCode code,
) => switch (code) {
  ImportWarningCode.unsupportedVersion => l10n.warningUnsupportedVersion,
  ImportWarningCode.guessedTimezone => l10n.warningGuessedTimezone,
  ImportWarningCode.invalidRecord => l10n.warningInvalidRecord,
  ImportWarningCode.unknownCurrency => l10n.warningUnknownCurrency,
  ImportWarningCode.invalidDate => l10n.warningInvalidDate,
  ImportWarningCode.invalidColor => l10n.warningInvalidColor,
  ImportWarningCode.unknownBillingCycle => l10n.warningUnknownBillingCycle,
  ImportWarningCode.unknownReminderType => l10n.warningUnknownReminderType,
  ImportWarningCode.unknownPaymentMethod => l10n.warningUnknownPaymentMethod,
  ImportWarningCode.unexpectedPayments => l10n.warningUnexpectedPayments,
  ImportWarningCode.unknownCycleRhythm => l10n.warningUnknownCycleRhythm,
  ImportWarningCode.unexpectedDuration => l10n.warningUnexpectedDuration,
  ImportWarningCode.missingStartDate => l10n.warningMissingStartDate,
  ImportWarningCode.noDates => l10n.warningNoDates,
  ImportWarningCode.expiryAsPurchaseDate => l10n.warningExpiryAsPurchaseDate,
  ImportWarningCode.unknownReminderRhythm => l10n.warningUnknownReminderRhythm,
};
