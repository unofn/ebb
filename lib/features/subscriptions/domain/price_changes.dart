import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import 'amount_due.dart';

part 'price_changes.freezed.dart';

/// A run of payments at one amount, starting [from].
@freezed
abstract class PriceSegment with _$PriceSegment {
  const factory PriceSegment({
    required DateTime from,
    required int amountMinor,
    required String currency,

    /// Change from the previous segment in percent (+12.5 = 12.5 % more);
    /// null for the first one or across currencies.
    double? changePercent,

    /// Not paid yet: the current price differs from the last payment and
    /// applies from the next charge.
    @Default(false) bool fromNextCharge,
  }) = _PriceSegment;
}

/// [sub]'s price history: [payments] (deleted ones ignored) by date, a new
/// segment wherever the amount or currency changes, then a next-charge
/// segment when what [sub] would charge next differs from the last
/// payment. Empty without payments.
List<PriceSegment> priceChanges(
  Subscription sub,
  Iterable<Payment> payments,
  DateTime today,
) {
  final paid = payments.where((p) => !p.deleted).toList()
    ..sort((a, b) => a.paidOn.compareTo(b.paidOn));
  final segments = <PriceSegment>[];
  void add(DateTime from, int amount, String currency, {bool next = false}) {
    final last = segments.lastOrNull;
    if (last != null &&
        last.amountMinor == amount &&
        last.currency == currency) {
      return;
    }
    segments.add(
      PriceSegment(
        from: from,
        amountMinor: amount,
        currency: currency,
        changePercent: last == null || last.currency != currency
            ? null
            : _percent(last.amountMinor, amount),
        fromNextCharge: next,
      ),
    );
  }

  for (final p in paid) {
    add(p.paidOn, p.amountMinor, p.currency.toUpperCase());
  }
  if (segments.isEmpty) return segments;
  final nextOn = sub.nextDate ?? today;
  if (amountFor(sub, nextOn) case final amount?) {
    add(nextOn, amount, sub.currency.toUpperCase(), next: true);
  }
  return segments;
}

double? _percent(int from, int to) =>
    from == 0 ? null : (to - from) * 100 / from;
