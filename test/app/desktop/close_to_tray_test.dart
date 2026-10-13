import 'dart:async';

import 'package:ebb/app/desktop/close_to_tray.dart';
import 'package:ebb/app/desktop/tray_host.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late _FakeHost host;
  late List<bool> applied;
  late CloseToTray closeToTray;

  setUp(() {
    host = _FakeHost();
    applied = [];
    closeToTray = CloseToTray(host, apply: (hide) async => applied.add(hide))
      ..start();
  });

  test('closing quits until a host shows up', () async {
    host.changes.add(false);
    await pumpEventQueue();
    expect(applied, isEmpty);

    host.changes
      ..add(true)
      ..add(true);
    await pumpEventQueue();
    expect(applied, [true]);
  });

  test('closing quits again when the host goes', () async {
    host.changes
      ..add(true)
      ..add(false);
    await pumpEventQueue();
    expect(applied, [true, false]);
  });

  test('a bus failure means no tray and closes the bus', () async {
    host.changes
      ..add(true)
      ..addError(StateError('bus gone'));
    await pumpEventQueue();
    expect(applied, [true, false]);
    expect(host.closed, 1);

    await closeToTray.stop();
    expect(host.closed, 1, reason: 'closed once');
  });

  test('stop closes the bus', () async {
    await closeToTray.stop();
    expect(host.closed, 1);
  });

  test('stop does not wait on a bus that never answers', () {
    fakeAsync((async) {
      final stuck = _FakeHost(closing: Completer<void>().future);
      var stopped = false;
      (CloseToTray(
        stuck,
        apply: (_) async {},
      )..start()).stop().then((_) => stopped = true);
      async.elapse(const Duration(seconds: 1));
      expect(stopped, isTrue);
    });
  });
}

class _FakeHost implements TrayHost {
  _FakeHost({this.closing});

  final changes = StreamController<bool>();
  final Future<void>? closing;
  var closed = 0;

  @override
  Stream<bool> presence() => changes.stream;

  @override
  Future<void> close() async {
    closed++;
    await closing;
  }
}
