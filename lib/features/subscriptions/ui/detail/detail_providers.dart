import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../../../data/database.dart';
import '../../../reminders/domain/planned_reminder.dart';
import '../../data/subscription_entry.dart';

part 'detail_providers.g.dart';

/// Subscription [id] with its category, payment method and tags; null
/// once deleted.
@riverpod
Stream<SubscriptionEntry?> subscriptionEntry(Ref ref, String id) =>
    ref.watch(subscriptionRepositoryProvider).watch(id);

/// A subscription's payments, newest first.
// 包一层自写类型：riverpod_generator 解析不到 drift 同一轮生成的行类型。
class PaymentHistory {
  const PaymentHistory(this.payments);

  final List<Payment> payments;
}

@riverpod
Stream<PaymentHistory> paymentHistory(Ref ref, String id) =>
    ref.watch(paymentRepositoryProvider).watchFor(id).map(PaymentHistory.new);

/// The reminder settings subscriptions without their own follow.
@riverpod
Future<ReminderDefaults> reminderDefaults(Ref ref) async {
  final settings = ref.watch(localSettingsProvider);
  return ReminderDefaults(
    daysBefore: await settings.reminderDays(),
    minuteOfDay: await settings.reminderTime(),
  );
}
