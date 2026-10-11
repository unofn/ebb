import '../../../data/database.dart';
import '../../../data/enums.dart';

// 派生状态只看字段和「今天」（纯日期），不落库。

extension SubscriptionState on Subscription {
  /// In a free trial: the trial ends after [today]; from its last day on
  /// the subscription is a regular one.
  bool isInTrial(DateTime today) => trialEndsOn?.isAfter(today) ?? false;

  /// Paying the intro price: the offer ends after [today].
  bool isInIntro(DateTime today) =>
      introPriceMinor != null && (introEndsOn?.isAfter(today) ?? false);

  /// A manual renewal that is due and not yet confirmed as paid.
  bool isAwaitingConfirmation(DateTime today) =>
      kind == SubscriptionKind.recurring &&
      status == SubscriptionStatus.active &&
      !autoRenew &&
      !(nextDate?.isAfter(today) ?? true);

  bool get isShared => myShareMinor != null;
}
