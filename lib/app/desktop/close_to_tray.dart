import 'dart:async';
import 'dart:developer';

import 'tray_host.dart';

/// Turns hide-on-close on while a [TrayHost] is there and off when it
/// goes, so a hidden window always has a tray icon to come back from. A
/// bus failure counts as no host and ends the watch.
class CloseToTray {
  CloseToTray(this._host, {required this._apply});

  final TrayHost _host;

  /// Sets whether closing the window hides it.
  final Future<void> Function(bool hide) _apply;

  StreamSubscription<bool>? _presence;
  bool _hide = false;
  // 窗口调用一个接一个地排队，宿主来回变时不交错。
  Future<void> _applied = Future.value();

  void start() {
    _presence = _host.presence().listen(
      _set,
      onError: (Object e, StackTrace stack) {
        log(
          'tray host check failed',
          name: 'ebb.tray',
          error: e,
          stackTrace: stack,
        );
        _set(false);
        unawaited(stop());
      },
    );
  }

  /// Stops watching and lets go of the bus, waiting a second at most.
  Future<void> stop() async {
    final presence = _presence;
    if (presence == null) return;
    _presence = null;
    // 总线坏了时退订、断开都可能等不到回复，不能让退出卡在这里。
    try {
      await Future.wait([presence.cancel(), _host.close()])
          .timeout(const Duration(seconds: 1));
    } catch (e, stack) {
      log(
        'tray host close failed',
        name: 'ebb.tray',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _set(bool hide) {
    if (hide == _hide) return;
    _hide = hide;
    log(hide ? 'tray host up' : 'no tray host', name: 'ebb.tray');
    _applied = _applied
        .then((_) => _apply(hide))
        .catchError(
          (Object e, StackTrace stack) => log(
            'hide-on-close failed',
            name: 'ebb.tray',
            error: e,
            stackTrace: stack,
          ),
        );
  }
}
