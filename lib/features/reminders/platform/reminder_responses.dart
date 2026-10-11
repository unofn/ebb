import 'dart:async';
import 'dart:developer';

import '../../../data/local_settings.dart';
import '../../payments/data/payment_repository.dart';
import '../../payments/domain/mark_paid.dart';
import '../../rates/data/rate_repository.dart';
import '../../subscriptions/data/subscription_repository.dart';
import 'reminder_payload.dart';

/// Acts on taps on reminder notifications and their buttons, with the app
/// in the foreground (buttons open it; no background isolate).
class ReminderResponses {
  ReminderResponses({
    required this._subscriptions,
    required this._payments,
    required this._rates,
    required this._settings,
  });

  final SubscriptionRepository _subscriptions;
  final PaymentRepository _payments;
  final RateRepository _rates;
  final LocalSettings _settings;
  final _opens = StreamController<String>.broadcast();
  String? _unclaimedOpen;

  /// Subscription IDs to show, for the router. A request made while
  /// nothing listens (the tap that launched the app) waits in
  /// [takeUnclaimedOpen].
  Stream<String> get openRequests => _opens.stream;

  /// The last open request nobody listened to; cleared once taken.
  String? takeUnclaimedOpen() {
    final id = _unclaimedOpen;
    _unclaimedOpen = null;
    return id;
  }

  /// 「已付款」 records the charge; a tap or 「管理订阅」 opens the
  /// subscription. Payloads that are not Ebb's are ignored.
  Future<void> handle({String? actionId, String? payload}) async {
    final reminder = ReminderPayload.decode(payload);
    if (reminder == null) return;
    final action = reminder.action ?? actionId;
    if (action == ReminderActions.markPaid) {
      await _markPaid(reminder);
    } else {
      _open(reminder.subscriptionId);
    }
  }

  /// Only while that charge is still the next one: a second tap, or one
  /// after confirming in the app, must not move next_date again.
  Future<void> _markPaid(ReminderPayload reminder) async {
    final id = reminder.subscriptionId;
    final sub = (await _subscriptions.watch(id).first)?.subscription;
    if (sub == null || sub.nextDate != reminder.eventDate) {
      log(
        'mark paid skipped: $id ${reminder.eventDate}',
        name: 'ebb.reminders',
      );
      return;
    }
    final rates = await _rates.current(await _settings.baseCurrency());
    final run = markPaid(sub, reminder.eventDate, rateOf: rates.rateOf);
    if (!run.isEmpty) await _payments.recordManual(id, run);
  }

  void _open(String subscriptionId) {
    if (_opens.hasListener) {
      _opens.add(subscriptionId);
    } else {
      log('open $subscriptionId: no listener yet', name: 'ebb.reminders');
      _unclaimedOpen = subscriptionId;
    }
  }

  Future<void> dispose() => _opens.close();
}
