import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import 'edit_form_view.dart';
import 'edit_start.dart';

/// Adds a subscription, or edits [subscriptionId]; pops once saved.
class EditSubscriptionScreen extends ConsumerWidget {
  const EditSubscriptionScreen({super.key, this.subscriptionId});

  final String? subscriptionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final start = ref.watch(editStartProvider(subscriptionId));
    return switch (start) {
      AsyncData(value: final start?) => EditFormView(
        start: start,
        subscriptionId: subscriptionId,
      ),
      AsyncData() => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            context.l10n.editMissing,
            style: EbbType.body.copyWith(color: context.colors.ink2),
          ),
        ),
      ),
      _ => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
    };
  }
}
