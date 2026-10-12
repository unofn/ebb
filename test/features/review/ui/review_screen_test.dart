import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/local_meta_store.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/data/tables/local_meta.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/app_harness.dart';
import '../../../support/fake_subscription.dart';
import '../../../support/screen_harness.dart';

void main() {
  late AppDatabase db;
  late ScreenCalls calls;
  late Map<String, String> ids;
  late DateTime now;

  setUp(() {
    db = widgetTestDatabase();
    calls = ScreenCalls();
  });

  // 在测试体里写库：setUp 里写会卡住之后界面的写入。
  Future<void> seed() async {
    now = today();
    await RateRepository(db, LocalSettings(db)).save(
      FetchedRates(
        base: 'CNY',
        updatedAt: DateTime.utc(2026),
        rates: {'USD': Decimal.parse('0.125')},
      ),
    );
    Future<String> add(
      String name,
      int price, {
      String currency = 'CNY',
      String? category,
      SubscriptionStatus status = SubscriptionStatus.active,
      String? url,
    }) => SubscriptionRepository(db).create(
      fakeSubscriptionDraft(
        name,
        categoryId: category == null ? null : categoryIdOf(category),
      ).copyWith(
        priceMinor: Value(price),
        currency: Value(currency),
        status: Value(status),
        startDate: Value(now.subtract(const Duration(days: 40))),
        nextDate: Value(now.add(const Duration(days: 5))),
        url: Value(url),
      ),
    );
    ids = {
      'Fake Chat': await add('Fake Chat', 2000, currency: 'USD'),
      'Fake Music': await add('Fake Music', 1500, category: 'audio'),
      'Fake Radio': await add(
        'Fake Radio',
        1200,
        category: 'audio',
        url: 'https://example.com/manage',
      ),
      'Fake Gym': await add(
        'Fake Gym',
        1000,
        status: SubscriptionStatus.paused,
      ),
    };
  }

  Future<void> open(WidgetTester tester) async {
    await seed();
    final router = await pumpScreens(tester, db, calls, location: '/');
    router.push('/review');
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<Subscription> stored(String name) =>
      storedSubscription(db, ids[name]!);

  testWidgets('goes through each one, sums up, and writes on done', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('季度复盘'), findsOneWidget);
    expect(find.text('1 / 4'), findsOneWidget);
    expect(find.text('Fake Chat'), findsOneWidget);
    expect(find.text('≈ ¥160.00'), findsNWidgets(2), reason: 'note, monthly');
    expect(find.text('还没扣过费'), findsOneWidget);

    await tapAndSettle(tester, find.text('不用了'));
    expect(find.text('没有管理链接，可以在编辑里填上'), findsOneWidget);
    await tapAndSettle(tester, find.text('设为到期不续'));

    expect(find.text('2 / 4'), findsOneWidget);
    expect(find.text('Fake Music'), findsOneWidget);
    expect(find.text('音频还有「Fake Radio」，两个都在用吗？'), findsOneWidget);
    await tapAndSettle(tester, find.text('还在用'));

    expect(find.text('Fake Radio'), findsOneWidget);
    await tapAndSettle(tester, find.text('不用了'));
    expect(find.text('去官网或 App Store 关掉自动续费'), findsOneWidget);
    await tapAndSettle(tester, find.text('算了，还在用'));
    await tapAndSettle(tester, find.text('还在用'));

    expect(find.text('Fake Gym'), findsOneWidget);
    expect(find.text('不计入（已暂停）'), findsOneWidget);
    await tapAndSettle(tester, find.text('不用了'));
    await tapAndSettle(tester, find.text('退订并归档'));

    expect(find.text('复盘完成'), findsOneWidget);
    expect(find.text('≈ ¥160.00'), findsOneWidget);
    expect(find.text('月均从 ¥187.00 降到 ¥27.00。'), findsOneWidget);
    expect(find.text('2 个'), findsNWidgets(2));
    expect(find.text('已退订并归档'), findsOneWidget);

    await tapAndSettle(tester, find.text('回到上一个'));
    expect(find.text('4 / 4'), findsOneWidget);
    await tapAndSettle(tester, find.text('还在用'));
    expect(find.text('停掉的订阅'), findsOneWidget);
    expect(find.text('已退订并归档'), findsNothing);

    await tapAndSettle(tester, find.text('完成'));
    expect(find.text('home'), findsOneWidget);
    final chat = await stored('Fake Chat');
    expect(chat.status, SubscriptionStatus.ending);
    expect(chat.endDate, chat.nextDate);
    expect((await stored('Fake Gym')).status, SubscriptionStatus.paused);
    expect((await stored('Fake Music')).status, SubscriptionStatus.active);
    expect(await db.readMeta(LocalMetaKeys.reviewLastCompletedOn), now.isoDate);
    await unmountScreens(tester);
  });

  testWidgets('later leaves without saving anything', (tester) async {
    await open(tester);

    await tapAndSettle(tester, find.text('不用了'));
    await tapAndSettle(tester, find.text('退订并归档'));
    expect(find.text('2 / 4'), findsOneWidget);
    await tapAndSettle(tester, find.text('上一个'));
    expect(find.text('1 / 4'), findsOneWidget);
    await tapAndSettle(tester, find.text('稍后'));

    expect(find.text('home'), findsOneWidget);
    expect((await stored('Fake Chat')).status, SubscriptionStatus.active);
    expect(await db.readMeta(LocalMetaKeys.reviewLastCompletedOn), isNull);
    await unmountScreens(tester);
  });

  testWidgets('a shared one shows my share, the total below', (tester) async {
    now = today();
    await RateRepository(db, LocalSettings(db)).save(
      FetchedRates(
        base: 'CNY',
        updatedAt: DateTime.utc(2026),
        rates: {'USD': Decimal.parse('0.125')},
      ),
    );
    await SubscriptionRepository(db).create(
      fakeSubscriptionDraft('Fake Video').copyWith(
        priceMinor: const Value(1549),
        currency: const Value('USD'),
        myShareMinor: const Value(516),
        nextDate: Value(now.add(const Duration(days: 5))),
      ),
    );
    final router = await pumpScreens(tester, db, calls, location: '/');
    router.push('/review');
    await tester.pumpAndSettle();

    expect(find.text(r'$5.16 / 月', findRichText: true), findsOneWidget);
    expect(find.text(r'≈ ¥41.28 · 总价 $15.49 / 月'), findsOneWidget);
    expect(find.text('≈ ¥41.28'), findsOneWidget, reason: 'monthly');
    await unmountScreens(tester);
  });
}
