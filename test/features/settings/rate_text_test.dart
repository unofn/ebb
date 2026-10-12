import 'package:decimal/decimal.dart';
import 'package:ebb/app/l10n/app_localizations.dart';
import 'package:ebb/features/settings/rate_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('zh'));

  test('shows base units per unit with 2 to 4 significant decimals', () {
    expect(baseUnitsText(Decimal.parse('0.1408450704')), '7.10');
    expect(baseUnitsText(Decimal.parse('0.125')), '8.00');
    expect(baseUnitsText(Decimal.parse('21.3')), '0.04695');
    expect(baseUnitsText(Decimal.parse('3')), '0.3333');
  });

  test('a typed rate round-trips through storage', () {
    final stored = perBaseOf(Decimal.parse('7.2'));
    expect(baseUnitsText(stored), '7.20');
  });

  test('fetch time: 「今天」 on the same local day, else the date', () {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    final fetched = DateTime(2026, 10, 12, 8, 2).toUtc();
    expect(
      fetchedText(l10n, 'zh', fetched, DateTime(2026, 10, 12, 20)),
      '今天 08:02',
    );
    expect(
      fetchedText(l10n, 'zh', fetched, DateTime(2026, 10, 14, 9)),
      '10月12日 08:02',
    );
  });
}
