import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/category_names.dart';
import '../../app/l10n/l10n.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../../app/widgets/card_section.dart';
import '../../app/widgets/segmented_tabs.dart';
import '../subscriptions/domain/list_segments.dart';
import '../subscriptions/domain/search_match.dart';
import 'home_row.dart';
import 'home_search.dart';
import 'home_sections.dart';
import 'home_segment.dart';
import 'home_view.dart';
import 'row_texts.dart';

/// The tabs (upcoming, all, one-time, archived) and the selected tab's
/// cards of rows, narrowed to the search (name, category, tags).
class HomeSegmentList extends ConsumerWidget {
  const HomeSegmentList({
    super.key,
    required this.view,
    required this.today,
    this.selectedId,
  });

  final HomeView view;
  final DateTime today;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final segment = ref.watch(homeSegmentProvider);
    final allCount = subscriptionsIn(ListSegment.all, view.subscriptions);
    final texts = RowTexts(
      l10n,
      locale,
      today: today,
      baseCurrency: view.baseCurrency,
      rates: view.rates,
    );
    final query = ref.watch(homeSearchProvider) ?? '';
    final found = view.where(
      (e) => matchesSearch(
        query,
        name: e.subscription.name,
        category: e.category == null ? null : categoryLabel(l10n, e.category!),
        tags: [for (final tag in e.tags) tag.name],
      ),
    );
    final sections = homeSections(l10n, locale, found, segment, today);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        SegmentedTabs(
          labels: [
            l10n.homeSegmentUpcoming,
            l10n.homeSegmentAll(allCount.length),
            l10n.homeSegmentOneTime,
            l10n.homeSegmentArchived,
          ],
          selected: segment.index,
          onSelected: (i) => ref
              .read(homeSegmentProvider.notifier)
              .select(ListSegment.values[i]),
        ),
        if (sections.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              query.trim().isEmpty
                  ? l10n.homeSegmentEmpty
                  : l10n.homeSearchEmpty,
              textAlign: TextAlign.center,
              style: EbbType.small.copyWith(color: context.colors.ink2),
            ),
          ),
        for (final section in sections)
          CardSection(
            title: section.title,
            trailing: section.trailing,
            children: [
              for (final s in section.subscriptions)
                HomeRow(
                  subscription: s,
                  texts: texts,
                  selected: s.id == selectedId,
                ),
            ],
          ),
      ],
    );
  }
}
