import 'amount_input.dart';
import 'edit_form.dart';

/// What keeps the form from saving; each belongs to one field.
enum FormError {
  nameMissing,
  priceInvalid,
  cycleCountInvalid,
  startDateMissing,
  trialEndMissing,
  introPriceInvalid,
  introEndMissing,
  introEndNotAfterStart,
  shareInvalid,
  shareOverPrice,
  reminderDaysInvalid,
}

/// The problems in [form]; empty when it can be saved. Fields that do not
/// apply to it are not checked.
Set<FormError> formErrors(EditForm form) {
  final price = form.priceMinor;
  final recurring = form.recurring;
  final start = form.startDate;
  return {
    if (form.name.trim().isEmpty) FormError.nameMissing,
    if (price == null || price < 0) FormError.priceInvalid,
    if (start == null) FormError.startDateMissing,
    if (recurring) ...{
      if (form.cycle == null) FormError.cycleCountInvalid,
      if (form.trial && form.trialEndsOn == null) FormError.trialEndMissing,
      if (form.intro) ..._introErrors(form),
      if (form.reminder && !_isDays(form.reminderDays))
        FormError.reminderDaysInvalid,
    },
    if (form.shared) ..._shareErrors(form, price),
  };
}

Set<FormError> _introErrors(EditForm form) {
  final price = parseMinor(form.introPrice, form.currency);
  final end = form.introEndsOn;
  final start = form.startDate;
  return {
    if (price == null || price < 0) FormError.introPriceInvalid,
    if (end == null) FormError.introEndMissing,
    if (end != null && start != null && !end.isAfter(start))
      FormError.introEndNotAfterStart,
  };
}

Set<FormError> _shareErrors(EditForm form, int? price) {
  final share = parseMinor(form.myShare, form.currency);
  return {
    if (share == null || share < 0) FormError.shareInvalid,
    if (share != null && price != null && share > price)
      FormError.shareOverPrice,
  };
}

/// Blank (the default) or a whole number of days, 0 or more.
bool _isDays(String text) =>
    text.trim().isEmpty || (int.tryParse(text.trim()) ?? -1) >= 0;
