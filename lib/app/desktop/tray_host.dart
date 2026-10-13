import 'dart:async';

import 'package:dbus/dbus.dart';

/// Whatever shows tray icons on the desktop. Without one an icon is
/// created but never appears.
abstract interface class TrayHost {
  /// Whether a host is there now, then on each change. An error means
  /// the bus failed.
  Stream<bool> presence();

  Future<void> close();
}

/// The StatusNotifierWatcher on the session bus (KDE, GNOME with the
/// AppIndicator extension, most other panels).
class DBusTrayHost implements TrayHost {
  DBusTrayHost([DBusClient? client]) : _client = client ?? DBusClient.session();

  static const _watcher = 'org.kde.StatusNotifierWatcher';

  final DBusClient _client;

  @override
  Stream<bool> presence() {
    StreamSubscription<bool>? changes;
    late final StreamController<bool> out;
    out = StreamController<bool>(
      // package:dbus 有些错抛在没人等的 future 或 socket 回调里（订阅信号、
      // 认证），try/catch 接不到，整段放进出错区，都当作总线失败交出去。
      onListen: () => runZonedGuarded(() async {
        try {
          // 先查一次把连接建好，再订阅、再查一次，不漏中间的变化。
          await _hasOwner();
          changes = _client.nameOwnerChanged
              .where((e) => e.name == _watcher)
              .map((e) => e.newOwner != null)
              .listen(out.add, onError: out.addError);
          out.add(await _hasOwner());
        } catch (e, stack) {
          out.addError(e, stack);
        }
      }, out.addError),
      onCancel: () => changes?.cancel(),
    );
    return out.stream;
  }

  // 连接卡住（认证没过）时不会报错，给个时限。
  Future<bool> _hasOwner() =>
      _client.nameHasOwner(_watcher).timeout(const Duration(seconds: 5));

  @override
  Future<void> close() => _client.close();
}
