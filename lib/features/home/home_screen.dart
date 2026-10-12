import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../app/widgets/content_width.dart';
import '../../core/local_date.dart';
import 'empty_home.dart';
import 'home_header.dart';
import 'home_segment_list.dart';
import 'home_view.dart';
import 'trial_hints.dart';

/// Monthly cost, trials about to charge, then the subscriptions by tab;
/// the empty state before there are any.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.selectedId, this.wide = false});

  /// The subscription shown beside the list (wide layout).
  final String? selectedId;

  /// The list column of the wide layout.
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 数据都在本机，读库几乎瞬时完成，不放加载态。
    final view = ref.watch(homeViewProvider).value;
    if (view == null) return const Scaffold();
    if (view.entries.isEmpty) {
      return const Scaffold(body: ContentWidth(child: EmptyHome()));
    }
    final now = today();
    return Scaffold(
      body: SafeArea(
        child: SlidableAutoCloseBehavior(
          child: ContentWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                HomeHeader(view: view, today: now, wide: wide),
                const SizedBox(height: 20),
                TrialHints(subscriptions: view.subscriptions, today: now),
                HomeSegmentList(view: view, today: now, selectedId: selectedId),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
