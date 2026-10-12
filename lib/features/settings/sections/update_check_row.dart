import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/job_providers.dart';
import '../../../app/providers/update_providers.dart';
import '../widgets/settings_row.dart';

/// 「自动检查新版本」: turning it on checks at once, whenever the last
/// check was.
class UpdateCheckRow extends ConsumerWidget {
  const UpdateCheckRow({super.key});

  Future<void> _set(WidgetRef ref, bool on) async {
    await ref.read(updateSettingsProvider).setEnabled(on);
    if (on) unawaited(ref.read(appJobsProvider).checkUpdateNow());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final on = ref.watch(updateCheckEnabledProvider).value ?? true;
    return MergeSemantics(
      child: SettingsRow(
        label: l10n.updateAutoCheck,
        hint: l10n.updateAutoCheckHint,
        onTap: () => _set(ref, !on),
        trailing: Switch(value: on, onChanged: (value) => _set(ref, value)),
      ),
    );
  }
}
