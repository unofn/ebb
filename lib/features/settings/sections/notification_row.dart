import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/job_providers.dart';
import '../../../app/providers/reminder_providers.dart';
import '../settings_providers.dart';
import '../widgets/settings_row.dart';

/// Whether the system lets Ebb notify. When it does not, a tap asks
/// again, or opens the system settings once the system no longer asks.
/// Rechecked whenever the app comes back to the foreground.
class NotificationRow extends ConsumerStatefulWidget {
  const NotificationRow({super.key});

  @override
  ConsumerState<NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends ConsumerState<NotificationRow> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // 用户可能刚从系统设置回来。
    _lifecycle = AppLifecycleListener(
      onResume: () => ref.invalidate(notificationsPermittedProvider),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// The system prompt shows only while the user has not decided; after a
  /// refusal the request returns false at once and the settings open.
  Future<void> _turnOn() async {
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.notifyCannotOpen;
    final granted = await ref
        .read(reminderSchedulerProvider)
        .requestPermission();
    if (granted) {
      unawaited(ref.read(appJobsProvider).replanReminders());
    } else if (!await ref.read(openNotificationSettingsProvider)()) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
    ref.invalidate(notificationsPermittedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (ref.watch(notificationsPermittedProvider).value) {
      null => SettingsRow(label: l10n.notifySystem),
      true => SettingsRow(label: l10n.notifySystem, value: l10n.notifyOn),
      false => SettingsRow(
        label: l10n.notifySystem,
        hint: l10n.notifyOffHint,
        value: l10n.notifyTurnOn,
        attention: true,
        onTap: _turnOn,
      ),
    };
  }
}
