import '../../features/subscriptions/domain/money_total.dart';
import '../l10n/app_localizations.dart';
import 'money_text.dart';

/// [total] as one line: 「≈ ¥205.66」 when [converted] (other currencies
/// went into it), then the amounts without a rate (「 + $5.00」).
String totalText(
  AppLocalizations l10n,
  MoneyTotal total, {
  required bool converted,
}) {
  final rest = unconvertedText(l10n, total);
  if (total.minor == 0 && rest.isNotEmpty) return rest;
  final main = moneyText(total.minor, total.currency);
  final sum = converted ? l10n.homeApprox(main) : main;
  return rest.isEmpty ? sum : '$sum + $rest';
}

/// The amounts left out of [total] for want of a rate: 「$20.00、€5.00」;
/// empty when everything converted.
String unconvertedText(AppLocalizations l10n, MoneyTotal total) => [
  for (final MapEntry(key: code, value: minor) in total.unconverted.entries)
    moneyText(minor, code),
].join(l10n.listSeparator);
