import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../app/providers/repository_providers.dart';
import '../../data/subscription_entry.dart';
import '../../domain/list_segments.dart';

part 'batch_sections.g.dart';

/// The batch list's sections, like the home segments without
/// 「即将扣费」: every subscription shows in exactly one.
const batchSegments = [
  ListSegment.all,
  ListSegment.oneTime,
  ListSegment.archived,
];

class BatchSection {
  const BatchSection(this.segment, this.entries);

  final ListSegment segment;

  /// By name.
  final List<SubscriptionEntry> entries;
}

/// Non-empty sections in [batchSegments] order; follows the database.
// 自写分组类型：riverpod_generator 解析不到 drift 同一轮生成的行类型。
@riverpod
Stream<List<BatchSection>> batchSections(Ref ref) => ref
    .watch(subscriptionRepositoryProvider)
    .watchAll()
    .map(
      (entries) => [
        for (final segment in batchSegments)
          if (entries
                  .where((e) => isInSegment(e.subscription, segment))
                  .toList()
              case final inSegment when inSegment.isNotEmpty)
            BatchSection(segment, inSegment),
      ],
    );
