import 'package:ebb/app/widgets/empty_state.dart';
import 'package:ebb/data/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  testWidgets('an empty tab says what would be there', (tester) async {
    await seedSubscriptions(tester, db, [seedable('Stream')]);
    await pumpEbb(tester, db);

    await tester.tap(find.text('已归档'));
    await tester.pumpAndSettle();
    expect(find.text('没有已归档的订阅'), findsOneWidget);
    expect(find.text('退订后归档的订阅会放在这里，可以随时恢复'), findsOneWidget);
    expect(find.text('Stream'), findsNothing);

    await tester.tap(find.text('一次性'));
    await tester.pumpAndSettle();
    expect(find.text('没有一次性买断'), findsOneWidget);
    expect(find.text('永久会员、软件授权这类只付一次的，会放在这里'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('a search without matches says what is searched', (tester) async {
    await seedSubscriptions(tester, db, [seedable('Stream')]);
    await pumpEbb(tester, db);

    await tester.tap(find.byTooltip('搜索'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nothing');
    await tester.pumpAndSettle();
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text('没有匹配的订阅'), findsOneWidget);
    expect(find.text('换个词试试，可以搜名称、品类或标签'), findsOneWidget);
    await unmountEbb(tester);
  });
}
