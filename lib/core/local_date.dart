import 'package:clock/clock.dart';
import 'package:intl/intl.dart';

// 纯日期一律表示为当天的 UTC 00:00，只读写 UTC 年月日，不做时区换算。

/// The calendar day [year]-[month]-[day] as a date-only value.
DateTime utcDate(int year, int month, int day) =>
    DateTime.utc(year, month, day);

/// Today on the user's calendar: the y/m/d of `clock.now()` in its own zone.
DateTime today() {
  final now = clock.now();
  return utcDate(now.year, now.month, now.day);
}

// 固定 en_US：ISO 日期与语言无关，也不依赖 Intl.defaultLocale 的初始化。
final _isoDate = DateFormat('yyyy-MM-dd', 'en_US');

/// Parses `YYYY-MM-DD` into a date-only value; throws [FormatException].
DateTime parseIsoDate(String text) => _isoDate.parseStrict(text.trim(), true);

extension DateOnly on DateTime {
  /// This UTC value truncated to its calendar day.
  DateTime get dateOnly {
    assert(isUtc, 'date-only values must be UTC');
    return utcDate(year, month, day);
  }

  /// `YYYY-MM-DD` of this UTC value.
  String get isoDate {
    assert(isUtc, 'date-only values must be UTC');
    return _isoDate.format(this);
  }
}
