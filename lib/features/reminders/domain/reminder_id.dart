import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../core/local_date.dart';
import 'planned_reminder.dart';

/// A notification ID that is the same on every run and device: the first
/// 31 bits of SHA-1 over subscription, kind and day (platform IDs are
/// signed 32-bit ints; `String.hashCode` is not stable across runs).
int reminderId(String subscriptionId, ReminderKind kind, DateTime eventDate) {
  final key = '$subscriptionId:${kind.name}:${eventDate.isoDate}';
  final bytes = sha1.convert(utf8.encode(key)).bytes;
  final value = bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3];
  return value & 0x7fffffff;
}
