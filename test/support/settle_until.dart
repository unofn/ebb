import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets real file IO finish: pumps until [done] and no spinner is left (at
/// most 100 times), then settles.
Future<void> settleUntil(WidgetTester tester, bool Function() done) async {
  final spinner = find.byType(CircularProgressIndicator);
  for (var i = 0; i < 100 && (!done() || spinner.evaluate().isNotEmpty); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

/// [settleUntil] [finder] finds something.
Future<void> settleUntilShown(WidgetTester tester, Finder finder) =>
    settleUntil(tester, () => finder.evaluate().isNotEmpty);
