import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../fields/date_field.dart';
import '../fields/form_text_field.dart';
import '../fields/labeled_field.dart';
import '../form/error_text.dart';
import '../form/form_binding.dart';
import '../form/form_errors.dart';

// 试用、首期优惠、合租展开后的输入框。

List<Widget> trialFields(BuildContext context, FormBinding binding) {
  final error = binding.errorOf([FormError.trialEndMissing]);
  return [
    LabeledField(
      label: context.l10n.editTrialEnds,
      error: errorText(context.l10n, error),
      child: DateField(
        value: binding.form.trialEndsOn,
        error: error != null,
        onChanged: (date) =>
            binding.update((f) => f.copyWith(trialEndsOn: date)),
      ),
    ),
  ];
}

List<Widget> introFields(BuildContext context, FormBinding binding) {
  final l10n = context.l10n;
  final priceError = binding.errorOf([FormError.introPriceInvalid]);
  final endError = binding.errorOf([
    FormError.introEndMissing,
    FormError.introEndNotAfterStart,
  ]);
  return [
    LabeledField(
      label: l10n.editIntroPrice,
      error: errorText(l10n, priceError),
      child: FormTextField(
        value: binding.form.introPrice,
        number: true,
        decimal: true,
        error: priceError != null,
        onChanged: (text) =>
            binding.update((f) => f.copyWith(introPrice: text)),
      ),
    ),
    LabeledField(
      label: l10n.editIntroEnds,
      error: errorText(l10n, endError),
      child: DateField(
        value: binding.form.introEndsOn,
        error: endError != null,
        onChanged: (date) =>
            binding.update((f) => f.copyWith(introEndsOn: date)),
      ),
    ),
  ];
}

List<Widget> shareFields(BuildContext context, FormBinding binding) {
  final l10n = context.l10n;
  final error = binding.errorOf([
    FormError.shareInvalid,
    FormError.shareOverPrice,
  ]);
  return [
    LabeledField(
      label: l10n.editMyShare,
      error: errorText(l10n, error),
      child: FormTextField(
        value: binding.form.myShare,
        number: true,
        decimal: true,
        error: error != null,
        onChanged: (text) => binding.update((f) => f.copyWith(myShare: text)),
      ),
    ),
  ];
}
