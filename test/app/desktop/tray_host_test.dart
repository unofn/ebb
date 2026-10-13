import 'dart:io';

import 'package:dbus/dbus.dart';
import 'package:ebb/app/desktop/tray_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const watcher = 'org.kde.StatusNotifierWatcher';

  test('follows the watcher coming and going on the bus', () async {
    final server = DBusServer();
    addTearDown(server.close);
    final address = await server.listenAddress(
      DBusAddress.unix(dir: Directory.systemTemp),
    );
    final host = DBusTrayHost(DBusClient(address));
    addTearDown(host.close);
    final seen = <bool>[];
    final presence = host.presence().listen(seen.add);
    addTearDown(presence.cancel);
    await _until(() => seen.isNotEmpty);
    expect(seen, [false]);

    final panel = DBusClient(address);
    await panel.requestName(watcher);
    await _until(() => seen.length == 2);
    expect(seen, [false, true]);

    await panel.close();
    await _until(() => seen.length == 3);
    expect(seen, [false, true, false]);
    // package:dbus 在 macOS 上做不了认证。
  }, skip: !Platform.isLinux);

  test('no bus is an error on the stream', () async {
    final address = DBusAddress.unix(
      path: '${Directory.systemTemp.path}/ebb-no-such-bus',
    );
    final host = DBusTrayHost(DBusClient(address));
    await expectLater(host.presence(), emitsError(isA<SocketException>()));
  });
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
