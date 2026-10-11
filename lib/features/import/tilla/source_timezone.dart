import 'package:collection/collection.dart';

import '../../../core/local_date.dart';

const _day = Duration.millisecondsPerDay;

// 余数只能确定模 24 小时的偏移，而真实时区跨 [-12h, +14h]，两端重叠 2 小时。
// 重叠处取人多的一侧：-10（夏威夷）而非 +14，+13、+12（新西兰、汤加）而非
// -11、-12。即结果落在 (-11h, +13h]。
const _westmost = -11 * Duration.millisecondsPerHour;

/// The UTC offset of the device that wrote a Tilla export. Tilla stores
/// dates as the device's local midnight, so the offset decides the day.
class SourceTimezone {
  const SourceTimezone(this.offset, {this.guessed = false});

  /// Infers the offset from [midnights] (timestamps known to be local
  /// midnights): the most common `ms mod 1 day` is midnight in UTC terms.
  /// Without samples, falls back to this machine's offset and is [guessed].
  factory SourceTimezone.infer(Iterable<int> midnights) {
    final counts = <int, int>{};
    for (final ms in midnights) {
      counts.update(ms % _day, (n) => n + 1, ifAbsent: () => 1);
    }
    if (counts.isEmpty) {
      return SourceTimezone(DateTime.now().timeZoneOffset, guessed: true);
    }
    // 众数；并列时取余数较小者，保证结果确定。
    final top = counts.values.max;
    final mode = counts.entries
        .where((e) => e.value == top)
        .map((e) => e.key)
        .min;
    final offset = -mode > _westmost ? -mode : _day - mode;
    return SourceTimezone(Duration(milliseconds: offset));
  }

  final Duration offset;

  /// True when no data pointed at the offset and this machine's was used.
  final bool guessed;

  /// The calendar day (UTC midnight) on which [ms] fell at the source.
  DateTime dayOf(int ms) =>
      DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).add(offset).dateOnly;
}
