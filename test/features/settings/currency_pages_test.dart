import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/app_harness.dart';
import '../../support/fake_subscription.dart';
import '../../support/screen_harness.dart';

void main() {
  late AppDatabase db;
  late ScreenCalls calls;

  setUp(() {
    db = widgetTestDatabase();
    calls = ScreenCalls();
  });

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// CNY rates with USD at 7.10 (1 CNY = 0.1408450704 USD), and
  /// subscriptions billed in [currencies].
  Future<void> seed(List<String> currencies) async {
    final settings = LocalSettings(db);
    await RateRepository(db, settings).save(
      FetchedRates(
        base: 'CNY',
        updatedAt: DateTime.utc(2026, 10, 12),
        rates: {
          'USD': Decimal.parse('0.1408450704'),
          'EUR': Decimal.parse('0.13'),
        },
      ),
    );
    for (final currency in currencies) {
      await SubscriptionRepository(db).create(
        fakeSubscriptionDraft('Fake $currency')
            .copyWith(currency: Value(currency)),
      );
    }
  }

  testWidgets('manual rate: set as base units per unit, then cleared', (
    tester,
  ) async {
    await seed(['USD', 'GBP', 'CNY']);
    await pumpScreens(tester, db, calls);
    expect(find.textContaining('今天'), findsOneWidget);

    await tapAndSettle(tester, find.text('手动汇率'));
    expect(find.text('1 USD = 7.10 CNY'), findsOneWidget);
    expect(find.text('暂无汇率'), findsOneWidget, reason: 'GBP not cached');
    expect(find.text('没有汇率的币种，要等联网获取到汇率后才能手动设置。'), findsOneWidget);
    expect(find.text('CNY'), findsNothing, reason: 'the base needs no rate');

    await tapAndSettle(tester, find.text('1 USD = 7.10 CNY'));
    await tester.enterText(find.byType(TextField), '0');
    await tapAndSettle(tester, find.text('保存'));
    expect(find.text('请输入大于 0 的数字'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '7.2');
    await tapAndSettle(tester, find.text('保存'));
    expect(find.text('1 USD = 7.20 CNY'), findsOneWidget);
    expect(find.text('手动'), findsOneWidget);
    final rates = await RateRepository(db, LocalSettings(db)).current('CNY');
    expect(rates.convertMinor(100, 'USD', 'CNY'), 720);

    await tapAndSettle(tester, find.byTooltip('返回'));
    expect(find.text('USD 7.20'), findsOneWidget);

    await tapAndSettle(tester, find.text('USD 7.20'));
    await tapAndSettle(tester, find.text('1 USD = 7.20 CNY'));
    await tapAndSettle(tester, find.text('清除手动汇率'));
    expect(find.text('1 USD = 7.10 CNY'), findsOneWidget);
    expect(find.text('手动'), findsNothing);
    await unmountScreens(tester);
  });

  testWidgets('without foreign currencies there is nothing to convert', (
    tester,
  ) async {
    await seed(['CNY']);
    await pumpScreens(tester, db, calls, location: '/settings/rates');

    expect(find.text('订阅都用基准货币，不需要汇率。'), findsOneWidget);
    await unmountScreens(tester);
  });

  testWidgets('base currency: searched, picked, shown back on settings', (
    tester,
  ) async {
    await seed(['USD']);
    await pumpScreens(tester, db, calls);

    await tapAndSettle(tester, find.text('基准货币'));
    expect(find.text('常用'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget, reason: 'CNY');

    await tester.enterText(find.byType(TextField), 'euro');
    await tester.pumpAndSettle();
    expect(find.text('USD'), findsNothing);
    await tester.enterText(find.byType(TextField), 'us');
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('USD'));

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(await LocalSettings(db).baseCurrency(), 'USD');
    await unmountScreens(tester);
  });
}
