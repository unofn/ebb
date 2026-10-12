import '../../../core/local_date.dart';
import '../../home/home_view.dart';
import '../../subscriptions/data/subscription_entry.dart';
import '../domain/calendar_charge.dart';
import '../../subscriptions/domain/money_total.dart';
import '../domain/charge_total.dart';

/// What both calendar layouts draw: the month shown, the selected day,
/// that month's charges and the subscriptions behind them.
class CalendarData {
  CalendarData({
    required this.month,
    required this.selected,
    required this.today,
    required this.charges,
    required this.view,
    this.dropped,
  }) : _entries = {for (final e in view.entries) e.id: e};

  /// The first of the month shown (date-only).
  final DateTime month;

  /// Date-only, within [month].
  final DateTime selected;
  final DateTime today;

  /// By day of month.
  final Map<int, List<CalendarCharge>> charges;
  final HomeView view;

  /// The subscription archived with 「没续费」 on [selected], to say so.
  final String? dropped;
  final Map<String, SubscriptionEntry> _entries;

  String get base => view.baseCurrency;

  List<CalendarCharge> on(int day) => charges[day] ?? const [];

  Iterable<CalendarCharge> get all => charges.values.expand((list) => list);

  Iterable<CalendarCharge> ofKind(ChargeKind kind) =>
      all.where((c) => c.kind == kind);

  SubscriptionEntry? entryOf(CalendarCharge charge) =>
      _entries[charge.subscriptionId];

  bool get showsToday => month.year == today.year && month.month == today.month;

  bool get atToday => selected == today;

  /// Count and base-currency sum of [charges].
  ({int count, MoneyTotal total, bool converted}) totalOf(
    Iterable<CalendarCharge> charges,
  ) => chargeTotal(charges, base, view.rates);
}

/// The first of the month [delta] months from [month].
DateTime shiftMonth(DateTime month, int delta) =>
    utcDate(month.year, month.month + delta, 1);
