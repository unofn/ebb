import 'dart:developer';

import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Loads the time zone database and sets `tz.local` to the device's zone,
/// so reminders fire at the local wall-clock time across DST changes.
/// An unknown zone keeps UTC and is logged; it does not stop the app.
Future<void> initLocalTimezone() async {
  tz.initializeTimeZones();
  try {
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
  } catch (e, stack) {
    log(
      'local time zone unavailable; using UTC',
      name: 'ebb.reminders',
      error: e,
      stackTrace: stack,
    );
  }
}
