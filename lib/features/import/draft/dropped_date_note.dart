import '../../../core/local_date.dart';

/// 一次性买断只有购买日：来源里多出的到期日不存为结束日期，写进备注，信息不丢。
String? notesWithDroppedExpiry(String? notes, DateTime? expiry) {
  if (expiry == null) return notes;
  final line = '原到期日 ${expiry.isoDate}';
  return notes == null ? line : '$notes\n$line';
}
