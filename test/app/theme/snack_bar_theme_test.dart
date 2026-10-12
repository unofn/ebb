import 'package:ebb/app/theme/ebb_colors.dart';
import 'package:ebb/app/theme/ebb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    test('snack bars follow the board in $brightness', () {
      final theme = ebbTheme(brightness);
      final c = theme.extension<EbbColors>()!;
      final snack = theme.snackBarTheme;
      expect(snack.backgroundColor, c.ink);
      expect(snack.contentTextStyle?.color, c.bg);
      expect(snack.contentTextStyle?.fontSize, 15);
      expect(snack.contentTextStyle?.height, 22 / 15);
      expect(snack.behavior, SnackBarBehavior.floating);
      expect(snack.insetPadding?.left, 16);
      expect(snack.insetPadding?.right, 16);
      expect(
        snack.shape,
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
    });
  }

  testWidgets('a snack bar floats above the bottom bar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ebbTheme(Brightness.light),
        home: Scaffold(
          bottomNavigationBar: const SizedBox(key: Key('bar'), height: 80),
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('已备份 82 个订阅'))),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();

    final snack = tester.getRect(find.byType(Material).last);
    final bar = tester.getRect(find.byKey(const Key('bar')));
    expect(snack.left, 16);
    expect(snack.right, tester.getSize(find.byType(Scaffold)).width - 16);
    expect(snack.bottom, lessThanOrEqualTo(bar.top - 12));
  });
}
