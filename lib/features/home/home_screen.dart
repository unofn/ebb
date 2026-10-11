import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/widgets/content_width.dart';
import 'empty_home.dart';
import 'home_list.dart';
import 'start_import.dart';
import 'subscription_groups.dart';

/// M1 home: the empty state, or the imported subscriptions to check them.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(subscriptionGroupsProvider);
    // 数据都在本机，读库几乎瞬时完成，不放加载态。
    return switch (groups.value) {
      null => const Scaffold(),
      [] => const Scaffold(body: ContentWidth(child: EmptyHome())),
      final groups => Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.homeTitle),
          actions: [
            IconButton(
              tooltip: context.l10n.importData,
              icon: const Icon(Icons.file_download_outlined),
              onPressed: () => startImport(context, ref),
            ),
          ],
        ),
        body: ContentWidth(child: HomeList(groups: groups)),
      ),
    };
  }
}
