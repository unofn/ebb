import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import 'sm_json.dart';

/// `java.util.Calendar` field constants used as `cycleRhythm`: YEAR, MONTH,
/// WEEK_OF_YEAR, WEEK_OF_MONTH, DATE, DAY_OF_YEAR.
const _unitOfRhythm = {
  1: CycleUnit.year,
  2: CycleUnit.month,
  3: CycleUnit.week,
  4: CycleUnit.week,
  5: CycleUnit.day,
  6: CycleUnit.day,
};

/// The billing cycle of [cycle], or null when it is missing, has an unknown
/// rhythm or a non-positive count.
Cycle? smCycle(SmCycle? cycle) {
  final unit = _unitOfRhythm[cycle?.cycleRhythm];
  if (cycle == null || unit == null || cycle.cycleDuration <= 0) return null;
  return Cycle(unit, cycle.cycleDuration);
}

/// The raw cycle for warning details, e.g. `rhythm 7 × 1`.
String describeSmCycle(SmCycle? cycle) => cycle == null
    ? 'missing'
    : 'rhythm ${cycle.cycleRhythm} × ${cycle.cycleDuration}';
