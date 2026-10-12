import 'package:flutter/material.dart';

import '../../app/l10n/l10n.dart';
import '../../app/widgets/empty_state.dart';
import '../subscriptions/domain/list_segments.dart';

/// A home tab with nothing in it, saying what would be there.
class SegmentEmpty extends StatelessWidget {
  const SegmentEmpty(this.segment, {super.key});

  final ListSegment segment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (title, body) = switch (segment) {
      ListSegment.upcoming => (l10n.emptyUpcomingTitle, l10n.emptyUpcomingBody),
      ListSegment.all => (l10n.emptyAllTitle, l10n.emptyAllBody),
      ListSegment.oneTime => (l10n.emptyOneTimeTitle, l10n.emptyOneTimeBody),
      ListSegment.archived => (l10n.emptyArchivedTitle, l10n.emptyArchivedBody),
    };
    return EmptyState(title: title, body: body);
  }
}
