import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../subscriptions/domain/list_segments.dart';

part 'home_segment.g.dart';

/// The home list's selected tab; kept while switching tabs or layouts.
@Riverpod(keepAlive: true)
class HomeSegment extends _$HomeSegment {
  @override
  ListSegment build() => ListSegment.upcoming;

  void select(ListSegment segment) => state = segment;
}
