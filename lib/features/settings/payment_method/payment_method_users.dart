import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/repository_providers.dart';
import '../../subscriptions/data/subscription_entry.dart';
import '../../subscriptions/domain/list_segments.dart';

part 'payment_method_users.g.dart';

/// The subscriptions still charging payment method [methodId]: recurring
/// and not archived (those in the home 「全部」 segment), by name. These
/// are the ones to move when the card changes.
@riverpod
Stream<List<SubscriptionEntry>> paymentMethodUsers(Ref ref, String methodId) =>
    ref
        .watch(subscriptionRepositoryProvider)
        .watchAll()
        .map(
          (entries) => [
            for (final entry in entries)
              if (entry.subscription.paymentMethodId == methodId &&
                  isInSegment(entry.subscription, ListSegment.all))
                entry,
          ],
        );
