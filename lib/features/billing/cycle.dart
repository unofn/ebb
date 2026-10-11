import 'package:freezed_annotation/freezed_annotation.dart';

import '../../data/database.dart';
import '../../data/enums.dart';

part 'cycle.freezed.dart';

/// Average days per unit (Gregorian year = 365.2425 days).
const _daysPerUnit = {
  CycleUnit.day: 1.0,
  CycleUnit.week: 7.0,
  CycleUnit.month: 365.2425 / 12,
  CycleUnit.year: 365.2425,
};

/// A billing period: every [count] [unit]s.
@freezed
abstract class Cycle with _$Cycle {
  @Assert('count > 0', 'count must be positive')
  const factory Cycle(CycleUnit unit, int count) = _Cycle;

  const Cycle._();

  /// Average length in days, for tolerances and estimates (not scheduling).
  double get approxDays => _daysPerUnit[unit]! * count;
}

extension SubscriptionCycle on Subscription {
  /// The billing cycle, or null when the row has none (one-time or unknown).
  Cycle? get cycle => switch ((cycleUnit, cycleCount)) {
    (final unit?, final count?) when count > 0 => Cycle(unit, count),
    _ => null,
  };
}
