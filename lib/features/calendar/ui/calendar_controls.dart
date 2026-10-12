/// What the calendar layouts can ask the screen to do.
class CalendarControls {
  const CalendarControls({
    required this.select,
    required this.showMonth,
    required this.shiftMonth,
    required this.goToday,
    required this.dropped,
  });

  /// Selects a date-only day of the month shown.
  final void Function(DateTime day) select;

  /// Shows the month starting on [first] (swiped to); nothing when it is
  /// already shown.
  final void Function(DateTime first) showMonth;

  /// Shows the month [delta] months away.
  final void Function(int delta) shiftMonth;
  final void Function() goToday;

  /// [name] was archived with 「没续费」.
  final void Function(String name) dropped;
}
