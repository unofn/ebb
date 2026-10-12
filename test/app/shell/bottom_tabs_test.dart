import 'package:ebb/app/l10n/l10n.dart';
import 'package:ebb/app/shell/bottom_tabs.dart';
import 'package:ebb/app/theme/ebb_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 360 宽的窄屏、英文、两倍字号：四个 tab 不溢出。
  for (final (locale, scale) in [
    (const Locale('en'), 1.0),
    (const Locale('en'), 2.0),
    (const Locale('zh'), 2.0),
  ]) {
    testWidgets('fits at 360 wide in $locale × $scale', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: ebbTheme(Brightness.light),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: Scaffold(
              bottomNavigationBar: BottomTabs(selected: 2, onSelected: (_) {}),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Icon), findsNWidgets(4));
    });
  }
}
