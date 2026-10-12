import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/calendar_providers.dart';
import '../../../app/widgets/content_width.dart';
import '../../../core/local_date.dart';
import '../../home/home_view.dart';
import 'calendar_controls.dart';
import 'calendar_data.dart';
import 'phone_calendar.dart';
import 'wide_calendar.dart';

/// The calendar tab: a month of paid, awaiting and expected charges and
/// the selected day's list; a wider layout from 840.
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selected = today();

  /// The subscription just archived with 「没续费」, until another day or
  /// month is picked.
  String? _dropped;

  DateTime get _month => utcDate(_selected.year, _selected.month, 1);

  void _select(DateTime day) => setState(() {
    _selected = day;
    _dropped = null;
  });

  /// The new month opens on today when it holds today, else on the 1st.
  void _showMonth(DateTime first) {
    if (first == _month) return;
    final now = today();
    final holdsToday = now.year == first.year && now.month == first.month;
    _select(holdsToday ? now : first);
  }

  late final _controls = CalendarControls(
    select: _select,
    showMonth: _showMonth,
    shiftMonth: (delta) => _showMonth(shiftMonth(_month, delta)),
    goToday: () => _select(today()),
    dropped: (name) => setState(() => _dropped = name),
  );

  @override
  Widget build(BuildContext context) {
    final now = today();
    final month = _month;
    final view = ref.watch(homeViewProvider).value;
    // 换月时新的一月还在算：先画空格子，不让整页闪成转圈。
    final charges =
        ref
            .watch(calendarChargesProvider(now, month.year, month.month))
            .value ??
        const {};
    if (view == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final data = CalendarData(
      month: month,
      selected: _selected,
      today: now,
      charges: charges,
      view: view,
      dropped: _dropped,
    );
    final wide = MediaQuery.sizeOf(context).width >= wideLayoutFrom;
    return Scaffold(
      body: SafeArea(
        child: wide
            ? WideCalendar(data: data, controls: _controls)
            : PhoneCalendar(data: data, controls: _controls),
      ),
    );
  }
}
