// 临时：渲染 M3 截图给设计对照，出完图删除，不提交。
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/providers/preset_providers.dart';
import 'package:ebb/app/router/route_paths.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/data/seed/categories.dart';
import 'package:ebb/features/calendar/ui/phone_day_cell.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/presets/preset_json.dart';
import 'package:ebb/features/presets/preset_search.dart';
import 'package:ebb/features/rates/data/rate_fetch_result.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_seed.dart';
import '../support/app_harness.dart';
import '../support/fake_subscription.dart';

const _out =
    '/private/tmp/claude-501/-Users-tianyang-Code-unofn-ebb/7e6e4eeb-04dc-4ae0-9edd-10fafec639f5/scratchpad/render/m3';
const _phone = Size(390, 844);
const _desktop = Size(1280, 800);

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    loader.addFont(
        Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
  }
  await loader.load();
}

Subscription _sub(String name, int price, String category,
        {String currency = 'CNY',
        CycleUnit unit = CycleUnit.month,
        bool autoRenew = true,
        required DateTime next}) =>
    fakeSubscription(
      id: 'r-$name',
      name: name,
      priceMinor: price,
      currency: currency,
      cycleUnit: unit,
      startDate: utcDate(next.year - 1, next.month, next.day),
      nextDate: next,
      autoRenew: autoRenew,
    ).copyWith(categoryId: Value(categoryIdOf(category)));

final _pendingDay = inDays(-2);

Future<void> _seed(WidgetTester tester, AppDatabase db) =>
    tester.runAsync(() async {
      final repo = SubscriptionRepository(db);
      final subs = [
        _sub('ChatGPT Plus', 2000, 'ai_assistant',
            currency: 'USD', next: inDays(3)),
        _sub('Keep 会员', 2500, 'health', next: inDays(6))
            .copyWith(trialEndsOn: Value(inDays(6))),
        _sub('哔哩哔哩大会员', 14800, 'video',
            unit: CycleUnit.year, next: inDays(8)),
        _sub('Netflix 标准', 1549, 'video', currency: 'USD', next: inDays(10))
            .copyWith(myShareMinor: const Value(516)),
        _sub('iCloud+ 200GB', 2100, 'storage', next: inDays(16)),
        _sub('中国移动', 5800, 'telecom', next: inDays(20)),
        _sub('腾讯视频 VIP', 2500, 'video',
            autoRenew: false, next: _pendingDay),
      ];
      for (final s in subs) {
        await repo.create(
            s.toCompanion(false).copyWith(updatedAt: const Value.absent()));
      }
      final t = today();
      await PaymentRepository(db).insertNew([
        for (var m = 0; m < 12; m++)
          for (final s in [subs[0], subs[4], subs[5]])
            PaymentsCompanion.insert(
              id: '${s.id}-$m',
              subscriptionId: s.id,
              paidOn: utcDate(t.year, t.month - m, m == 0 ? 1 : 15),
              amountMinor: s.priceMinor,
              currency: s.currency,
              origin: PaymentOrigin.auto,
              rateToBase: Value(s.currency == 'USD' ? '0.1408' : '1'),
              baseCurrency: const Value('CNY'),
            ),
      ]);
      await RateRepository(db, LocalSettings(db)).save(FetchedRates(
        base: 'CNY',
        updatedAt: DateTime.now().toUtc(),
        rates: {'USD': Decimal.parse('0.1408')},
      ));
      await LocalSettings(db).setBudgetMonthlyMinor(40000);
    });

void main() {
  late AppDatabase db;

  setUpAll(() async {
    await _font('IBM Plex Sans', [
      'assets/fonts/IBMPlexSans-Regular.ttf',
      'assets/fonts/IBMPlexSans-SemiBold.ttf',
    ]);
    await _font('Noto Sans SC', [
      'assets/fonts/NotoSansSC-Regular.ttf',
      'assets/fonts/NotoSansSC-SemiBold.ttf',
    ]);
    await _font('MaterialIcons', [
      '/opt/homebrew/share/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ]);
    final simple = Directory(
      '${Platform.environment['HOME']}/.pub-cache/hosted/pub.dev',
    ).listSync().whereType<Directory>().firstWhere(
          (d) => d.path.contains('simple_icons-'),
        );
    await _font('packages/simple_icons/SimpleIcons', [
      '${simple.path}/fonts/SimpleIcons.ttf',
    ]);
  });

  setUp(() {
    db = widgetTestDatabase();
    WidgetsApp.debugAllowBannerOverride = false;
  });

  Future<void> open(WidgetTester tester, Size size) async {
    await _seed(tester, db);
    final presets = PresetSearch(parseServicePresets(
        File('assets/presets/services.json').readAsStringSync()));
    await pumpEbb(tester, db, size: size, overrides: [
      servicePresetsProvider.overrideWith((ref) async => presets),
    ]);
    tester.view
      ..physicalSize = size * 2
      ..devicePixelRatio = 2;
    await settleWrites(tester);
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await settleWrites(tester);
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile(Uri.file('$_out/$name.png')));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  testWidgets('home and budget sheet', (tester) async {
    await open(tester, _phone);
    await shot(tester, 'home');
    await tester.tap(find.textContaining('预算 ¥400'));
    await settle(tester);
    await shot(tester, 'budget-sheet');
    await unmountEbb(tester);
  });

  testWidgets('calendar phone', (tester) async {
    await open(tester, _phone);
    await tapText(tester, '日历');
    await tester.tap(find.byWidgetPredicate(
        (w) => w is PhoneDayCell && w.date == _pendingDay));
    await settle(tester);
    await shot(tester, 'calendar-phone');
    await unmountEbb(tester);
  });

  testWidgets('calendar desktop', (tester) async {
    await open(tester, _desktop);
    await tapText(tester, '日历');
    await shot(tester, 'calendar-desktop');
    await unmountEbb(tester);
  });

  testWidgets('review', (tester) async {
    await open(tester, _phone);
    GoRouter.of(tester.element(find.byType(Scaffold).first))
        .push(RoutePaths.review);
    await settle(tester);
    await tapText(tester, '还在用');
    await tapText(tester, '还在用');
    await tapText(tester, '不用了');
    await shot(tester, 'review-card');
    await tapText(tester, '设为到期不续');
    for (var i = 0; i < 10 && find.text('还在用').evaluate().isNotEmpty; i++) {
      await tapText(tester, '还在用');
    }
    await shot(tester, 'review-done');
    await unmountEbb(tester);
  });
}
