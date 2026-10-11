import 'package:intl/intl.dart';

// 纯日期是 UTC 00:00，DateFormat 按 UTC 字段格式化，不做时区换算。

/// 「10月15日」 within [today]'s year, else 「2027年3月12日」.
String dayText(String locale, DateTime date, DateTime today) =>
    date.year == today.year
    ? DateFormat.MMMd(locale).format(date)
    : DateFormat.yMMMd(locale).format(date);

/// 「2027年3月12日」.
String fullDayText(String locale, DateTime date) =>
    DateFormat.yMMMd(locale).format(date);

/// 「2026年6月」.
String monthText(String locale, DateTime date) =>
    DateFormat.yMMM(locale).format(date);
