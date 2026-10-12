import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/calendar/domain/calendar_charge.dart';
import '../../features/calendar/domain/charges_in_month.dart';
import '../../features/home/home_view.dart';
import 'payment_providers.dart';

part 'calendar_providers.g.dart';

/// The charges in [year]-[month] by day of month, as seen on [today].
@riverpod
Future<Map<int, List<CalendarCharge>>> calendarCharges(
  Ref ref,
  DateTime today,
  int year,
  int month,
) async {
  final entries = await ref.watch(subscriptionEntriesProvider.future);
  final payments = await ref.watch(allPaymentsProvider.future);
  return chargesInMonth(
    year,
    month,
    payments: payments,
    subs: [for (final entry in entries) entry.subscription],
    today: today,
  );
}
