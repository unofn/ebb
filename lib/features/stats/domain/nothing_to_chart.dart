import '../../../data/database.dart';
import '../../../data/enums.dart';

/// No payment recorded and no subscription running (active or ending,
/// the ones the forecast counts): both twelve months would be empty, so
/// the stats page shows only its empty state.
bool nothingToChart(Iterable<Payment> payments, Iterable<Subscription> subs) =>
    payments.isEmpty &&
    !subs.any(
      (s) =>
          !s.deleted &&
          s.kind == SubscriptionKind.recurring &&
          (s.status == SubscriptionStatus.active ||
              s.status == SubscriptionStatus.ending),
    );
