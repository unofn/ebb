import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/duplicate_providers.dart';
import '../../../app/providers/payment_providers.dart';
import '../../home/home_view.dart';
import '../../presets/preset_match.dart';
import '../../presets/preset_match_provider.dart';
import '../../subscriptions/domain/duplicates.dart';

part 'review_context.g.dart';

/// Everything the review card shows besides the subscription itself.
class ReviewContext {
  const ReviewContext({
    required this.view,
    required this.lastPaid,
    required this.duplicates,
    required this.presets,
  });

  /// Subscriptions, base currency and today's rates, as on the home screen.
  final HomeView view;

  /// The latest payment per subscription ID: when and how much.
  final Map<String, ({DateTime on, int minor, String currency})> lastPaid;
  final List<DuplicateGroup> duplicates;
  final PresetMatcher? presets;
}

@riverpod
Future<ReviewContext> reviewContext(Ref ref, DateTime today) async {
  final payments = await ref.watch(allPaymentsProvider.future);
  final lastPaid = <String, ({DateTime on, int minor, String currency})>{};
  for (final p in payments.sortedBy((p) => p.paidOn)) {
    lastPaid[p.subscriptionId] = (
      on: p.paidOn,
      minor: p.amountMinor,
      currency: p.currency,
    );
  }
  return ReviewContext(
    view: await ref.watch(homeViewProvider.future),
    lastPaid: lastPaid,
    duplicates: await ref.watch(duplicateHintsProvider(today).future),
    presets: ref.watch(presetMatcherProvider).value,
  );
}
