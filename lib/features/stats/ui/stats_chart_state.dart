import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'stats_chart_state.g.dart';

/// Which twelve months the chart shows.
enum SpendRange { past, future }

/// The chart's range and the month picked in it (null: none, the average
/// shows); switching the range clears the pick.
@Riverpod(keepAlive: true)
class StatsChartState extends _$StatsChartState {
  @override
  ({SpendRange range, int? selected}) build() =>
      (range: SpendRange.past, selected: null);

  void showRange(SpendRange range) => state = (range: range, selected: null);

  /// Picks month [index], or clears it when it is already picked.
  void toggle(int index) => state = (
    range: state.range,
    selected: state.selected == index ? null : index,
  );
}
