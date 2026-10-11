import 'dart:async';
import 'dart:developer';

import 'package:clock/clock.dart';

import '../../core/local_date.dart';
import '../../data/database.dart';
import '../../data/local_settings.dart';
import '../../features/payments/data/payment_repository.dart';
import '../../features/payments/domain/auto_payments.dart';
import '../../features/rates/data/rate_repository.dart';
import '../../features/reminders/domain/plan_reminders.dart';
import '../../features/reminders/domain/planned_reminder.dart';
import '../../features/subscriptions/data/subscription_repository.dart';

/// Replaces the scheduled reminders with a new plan.
typedef Reschedule = Future<void> Function(List<PlannedReminder> planned);

/// The work on app start and resume, in order: refresh rates (when due),
/// record automatic payments, reschedule reminders. Runs one at a time; a
/// step that fails is logged and the next one still runs.
class AppJobs {
  AppJobs({
    required this._subscriptions,
    required this._payments,
    required this._rates,
    required this._settings,
    required this._refreshRates,
    required this._reschedule,
    this.debounce = const Duration(seconds: 1),
  });

  final SubscriptionRepository _subscriptions;
  final PaymentRepository _payments;
  final RateRepository _rates;
  final LocalSettings _settings;
  final Future<void> Function() _refreshRates;
  final Reschedule _reschedule;
  final Duration debounce;

  Future<void> _tail = Future.value();
  final _queued = <_Job, Future<void>>{};
  Timer? _debounceTimer;

  /// App start and resume; a run already waiting to start is reused.
  Future<void> runAll() => _enqueue(_Job.all, () async {
    await _step('refresh rates', _refreshRates);
    await _step('auto payments', _recordPayments);
    await _step('reminders', _replan);
  });

  /// Subscriptions changed: replan once they have been quiet for
  /// [debounce].
  void subscriptionsChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () => unawaited(replanReminders()));
  }

  /// Plans and reschedules reminders now (after the running job), e.g.
  /// after the reminder defaults change.
  Future<void> replanReminders() =>
      _enqueue(_Job.reminders, () => _step('reminders', _replan));

  void dispose() => _debounceTimer?.cancel();

  Future<void> _enqueue(_Job job, Future<void> Function() work) {
    if (_queued[job] case final waiting?) return waiting;
    final run = _tail.then((_) {
      _queued.remove(job);
      return work();
    });
    _tail = run.catchError((Object _) {});
    return _queued[job] = run;
  }

  Future<void> _step(String name, Future<void> Function() work) async {
    try {
      await work();
    } catch (e, stack) {
      log('$name failed', name: 'ebb.jobs', error: e, stackTrace: stack);
    }
  }

  Future<void> _recordPayments() async {
    final rates = await _rates.current(await _settings.baseCurrency());
    for (final sub in await _all()) {
      // 一条出错不影响其他订阅。
      await _step('auto payments ${sub.id}', () async {
        final run = autoPayments(
          sub,
          today: today(),
          existingPaymentIds: await _payments.idsFor(sub.id),
          rateOf: rates.rateOf,
        );
        if (!run.isEmpty) await _payments.record(sub.id, run);
      });
    }
  }

  Future<void> _replan() async {
    final defaults = ReminderDefaults(
      daysBefore: await _settings.reminderDays(),
      minuteOfDay: await _settings.reminderTime(),
    );
    await _reschedule(
      planReminders(await _all(), defaults: defaults, now: clock.now()),
    );
  }

  Future<List<Subscription>> _all() async => [
    for (final entry in await _subscriptions.watchAll().first)
      entry.subscription,
  ];
}

enum _Job { all, reminders }
