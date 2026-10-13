import 'dart:async';
import 'dart:io';

import 'package:ebb/app/l10n/app_localizations.dart';
import 'package:ebb/features/reminders/platform/notification_setup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final zh = lookupAppLocalizations(const Locale('zh'));

  Future<List<Object>> init(FlutterLocalNotificationsPlugin plugin) async {
    final errors = <Object>[];
    await initNotifications(
      plugin,
      l10n: zh,
      onResponse: ({actionId, payload}) async {},
      onError: (e, _) => errors.add(e),
    );
    await pumpEventQueue();
    return errors;
  }

  test('an error the plugin leaves behind after init is caught', () async {
    expect(await init(_FakePlugin(leak: true)), [isA<SocketException>()]);
  });

  test('a failing init is caught and init still completes', () async {
    expect(await init(_FakePlugin(fail: true)), [isA<StateError>()]);
  });

  test('a working plugin reports nothing', () async {
    expect(await init(_FakePlugin()), isEmpty);
  });
}

/// The Linux plugin without a session bus: init returns, but the bus
/// connection package:dbus starts for its signals fails in a future
/// nobody awaits.
class _FakePlugin implements FlutterLocalNotificationsPlugin {
  _FakePlugin({this.leak = false, this.fail = false});

  final bool leak;
  final bool fail;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    if (fail) throw StateError('init failed');
    if (leak) {
      unawaited(
        Future<void>(() => throw const SocketException('no session bus')),
      );
    }
    return true;
  }

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() => null;

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
