import '../../../../../app/l10n/l10n.dart';
import 'form_errors.dart';

/// The message under a field for [error]; null when there is none.
String? errorText(AppLocalizations l10n, FormError? error) => switch (error) {
  null => null,
  FormError.nameMissing => l10n.editErrorName,
  FormError.priceInvalid ||
  FormError.introPriceInvalid ||
  FormError.shareInvalid => l10n.editErrorAmount,
  FormError.cycleCountInvalid => l10n.editErrorCount,
  FormError.startDateMissing ||
  FormError.trialEndMissing ||
  FormError.introEndMissing => l10n.editErrorDate,
  FormError.introEndNotAfterStart => l10n.editErrorIntroEnd,
  FormError.shareOverPrice => l10n.editErrorShareOverPrice,
  FormError.reminderDaysInvalid => l10n.editErrorDays,
};
