import '../../../data/database.dart';
import '../../../data/enums.dart';
import 'name_order.dart';

/// The home list's tabs.
enum ListSegment {
  /// Active or ending recurring subscriptions with a next date.
  upcoming,

  /// Recurring and not cancelled (paused included).
  all,
  oneTime,

  /// Cancelled recurring subscriptions.
  archived,
}

bool isInSegment(Subscription sub, ListSegment segment) {
  if (sub.deleted) return false;
  final recurring = sub.kind == SubscriptionKind.recurring;
  final cancelled = sub.status == SubscriptionStatus.cancelled;
  return switch (segment) {
    ListSegment.upcoming =>
      recurring &&
          sub.nextDate != null &&
          (sub.status == SubscriptionStatus.active ||
              sub.status == SubscriptionStatus.ending),
    ListSegment.all => recurring && !cancelled,
    ListSegment.oneTime => !recurring,
    ListSegment.archived => recurring && cancelled,
  };
}

/// [subs] in [segment], keeping their order; upcoming is sorted by next
/// date (then name).
List<Subscription> subscriptionsIn(
  ListSegment segment,
  Iterable<Subscription> subs,
) {
  final selected = subs.where((s) => isInSegment(s, segment)).toList();
  if (segment == ListSegment.upcoming) {
    selected.sort(
      (a, b) => switch (a.nextDate!.compareTo(b.nextDate!)) {
        0 => compareNames(a.name, b.name),
        final order => order,
      },
    );
  }
  return selected;
}
