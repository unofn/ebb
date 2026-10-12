import 'dart:async';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart' show Value;
import 'package:ebb/app/lifecycle/app_jobs.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/local_settings.dart';
import 'package:ebb/features/payments/data/payment_repository.dart';
import 'package:ebb/features/rates/data/rate_repository.dart';
import 'package:ebb/features/reminders/domain/planned_reminder.dart';
import 'package:ebb/features/subscriptions/data/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_subscription.dart';
import '../../support/memory_database.dart';

void main() {
  // 本机时间 2026-10-11 10:00。
  final now = DateTime(2026, 10, 11, 10);
  late AppDatabase db;
  late List<String> steps;
  late List<List<PlannedReminder>> plans;
  late Future<void> Function() refresh;
  setUp(() async {
    db = memoryDatabase();
    steps = [];
    plans = [];
    refresh = () async => steps.add('rates');
    // 自动续费的月付订阅，9 月 1 日起没记账。
    await db.writer.insert(
      db.subscriptions,
      fakeSubscriptionDraft('Netflix', id: 's1').copyWith(
        startDate: Value(utcDate(2026, 8, 1)),
        nextDate: Value(utcDate(2026, 9, 1)),
        reminderEnabled: const Value(true),
      ),
    );
  });
  tearDown(() => db.close());

  AppJobs jobs({Duration debounce = const Duration(seconds: 1)}) {
    final settings = LocalSettings(db);
    return AppJobs(
      subscriptions: SubscriptionRepository(db),
      payments: PaymentRepository(db),
      rates: RateRepository(db, settings),
      settings: settings,
      refreshRates: () => refresh(),
      reschedule: (planned) async {
        steps.add('reminders');
        plans.add(planned);
      },
      checkUpdate: ({force = false}) async =>
          steps.add(force ? 'update now' : 'update'),
      debounce: debounce,
    );
  }

  Future<List<DateTime>> paidDays() async =>
      [for (final p in await db.select(db.payments).get()) p.paidOn]..sort();

  test('rates, automatic payments, reminders, then the update', () async {
    refresh = () async {
      expect(await paidDays(), isEmpty);
      steps.add('rates');
    };
    await withClock(Clock.fixed(now), () => jobs().runAll());

    expect(steps, ['rates', 'reminders', 'update']);
    expect(await paidDays(), [utcDate(2026, 9, 1), utcDate(2026, 10, 1)]);
    final sub = await storedSubscription(db, 's1');
    expect(sub.nextDate, utcDate(2026, 11, 1));
    // 提醒按记账后的 next_date 排：11 月 1 日前 3 天 09:00。
    final reminder = plans.single.single;
    expect(reminder.subscriptionId, 's1');
    expect(reminder.fireAt, DateTime(2026, 10, 29, 9));
  });

  test('a failed rate refresh does not stop the rest', () async {
    refresh = () async => throw StateError('offline');
    await withClock(Clock.fixed(now), () => jobs().runAll());
    expect(await paidDays(), hasLength(2));
    expect(plans, hasLength(1));
  });

  test('runs again are idempotent', () async {
    final runner = jobs();
    await withClock(Clock.fixed(now), runner.runAll);
    await withClock(Clock.fixed(now), runner.runAll);
    expect(await paidDays(), hasLength(2));
    expect(plans, hasLength(2));
    expect(plans.last, plans.first);
  });

  test('one run at a time; a waiting run is shared', () async {
    final gate = Completer<void>();
    var refreshes = 0;
    refresh = () async {
      refreshes++;
      await gate.future;
    };
    final runner = jobs();
    await withClock(Clock.fixed(now), () async {
      final first = runner.runAll();
      await pumpEventQueue();
      // 第一次还卡在汇率上：后面两次排在它之后，合成一次。
      final second = runner.runAll();
      final third = runner.runAll();
      expect(identical(second, third), isTrue);
      await pumpEventQueue();
      expect(refreshes, 1);
      gate.complete();
      await Future.wait([first, second]);
    });
    expect(refreshes, 2);
    expect(plans, hasLength(2));
  });

  test('checkUpdateNow forces a check after the running job', () async {
    final gate = Completer<void>();
    refresh = () async {
      steps.add('rates');
      await gate.future;
    };
    final runner = jobs();
    await withClock(Clock.fixed(now), () async {
      final all = runner.runAll();
      await pumpEventQueue();
      final forced = runner.checkUpdateNow();
      gate.complete();
      await Future.wait([all, forced]);
    });
    expect(steps, ['rates', 'reminders', 'update', 'update now']);
  });

  test('subscription changes replan once, after a quiet spell', () async {
    // drift 的流查询在 fake_async 里不推进，这里用真实时间、放宽间隔。
    const quiet = Duration(milliseconds: 300);
    const step = Duration(milliseconds: 150);
    final runner = jobs(debounce: quiet)..subscriptionsChanged();
    await Future<void>.delayed(step);
    runner.subscriptionsChanged();
    await Future<void>.delayed(step);
    expect(plans, isEmpty);
    await Future<void>.delayed(quiet * 3);
    expect(steps, ['reminders']);
    expect(plans, hasLength(1));
    runner.dispose();
  });
}
