import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/calendar/ui/calendar_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import 'home_seed.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = widgetTestDatabase());

  final video = Value(categoryIdOf('video'));

  testWidgets('same-category subscriptions get a hint until dismissed', (
    tester,
  ) async {
    await seedSubscriptions(tester, db, [
      seedable('Flix').copyWith(categoryId: video),
      seedable('Stream').copyWith(categoryId: video),
    ]);
    await pumpEbb(tester, db);

    expect(find.text('你有 2 个视频订阅'), findsOneWidget);
    expect(find.text('Flix、Stream'), findsOneWidget);

    await tester.tap(find.byTooltip('不再提示'));
    await settleWrites(tester);
    expect(find.text('你有 2 个视频订阅'), findsNothing);
    final dismissed = await tester.runAsync(
      () => LocalSettings(db).dismissedDuplicates(),
    );
    expect(dismissed, hasLength(1));
    await unmountEbb(tester);
  });

  testWidgets('the budget bar under the yearly line, by level', (tester) async {
    await seedSubscriptions(tester, db, [seedable('Stream')]);
    await pumpEbb(tester, db);
    expect(find.textContaining('预算'), findsNothing, reason: 'none set');
    await unmountEbb(tester);

    await tester.runAsync(() => LocalSettings(db).setBudgetMonthlyMinor(4000));
    await pumpEbb(tester, db);
    expect(find.text('预算 ¥40 · 已用 30%'), findsOneWidget);
    await unmountEbb(tester);

    await tester.runAsync(() => LocalSettings(db).setBudgetMonthlyMinor(1000));
    await pumpEbb(tester, db);
    expect(find.text('超出 ¥2.00'), findsOneWidget);
    await unmountEbb(tester);
  });

  testWidgets('four tabs: the calendar is the second', (tester) async {
    await seedSubscriptions(tester, db, [seedable('Stream')]);
    await pumpEbb(tester, db);

    for (final label in ['首页', '日历', '统计', '设置']) {
      expect(find.text(label), findsWidgets);
    }
    await tester.tap(find.text('日历'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarScreen), findsOneWidget);
    await unmountEbb(tester);
  });
}
