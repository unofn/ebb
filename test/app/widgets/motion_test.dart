import 'package:ebb/app/theme/ebb_theme.dart';
import 'package:ebb/app/widgets/budget_meter.dart';
import 'package:ebb/app/widgets/fading_text.dart';
import 'package:ebb/features/budget/domain/budget_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFigures(
    WidgetTester tester, {
    required bool animationsOff,
    required String total,
    required int used,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: ebbTheme(Brightness.light),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: animationsOff),
        child: Column(
          children: [
            FadingText(total, style: const TextStyle()),
            BudgetMeter(status: budgetStatus(used, 1000)!),
          ],
        ),
      ),
    ),
  );

  Duration fade(WidgetTester tester) =>
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration;

  Duration bar(WidgetTester tester) => tester
      .widget<AnimatedFractionallySizedBox>(
        find.byType(AnimatedFractionallySizedBox),
      )
      .duration;

  testWidgets('figures fade and bars settle', (tester) async {
    await pumpFigures(tester, animationsOff: false, total: '¥100', used: 100);
    expect(fade(tester), const Duration(milliseconds: 200));
    expect(bar(tester), const Duration(milliseconds: 300));

    await pumpFigures(tester, animationsOff: false, total: '¥200', used: 950);
    await tester.pump(const Duration(milliseconds: 100));
    // 淡入途中新旧两个值都在。
    expect(find.text('¥100'), findsOneWidget);
    expect(find.text('¥200'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('¥100'), findsNothing);
  });

  testWidgets('no animation when the system turns them off', (tester) async {
    await pumpFigures(tester, animationsOff: true, total: '¥100', used: 100);
    expect(fade(tester), Duration.zero);
    expect(bar(tester), Duration.zero);

    await pumpFigures(tester, animationsOff: true, total: '¥200', used: 950);
    await tester.pump();
    expect(find.text('¥100'), findsNothing);
    expect(find.text('¥200'), findsOneWidget);
  });
}
