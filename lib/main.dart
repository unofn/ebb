import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/desktop/linux_tray.dart';
import 'app/l10n/system_l10n.dart';
import 'app/lifecycle/lifecycle_host.dart';
import 'app/providers/reminder_providers.dart';
import 'features/reminders/platform/notification_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  final l10n = systemL10n();
  await initNotifications(
    container.read(notificationsPluginProvider),
    l10n: l10n,
    onResponse: container.read(reminderResponsesProvider).handle,
  );
  // 托盘对象由 windowManager 的监听列表持有。
  if (Platform.isLinux) await LinuxTray(l10n).start();
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const LifecycleHost(child: EbbApp()),
    ),
  );
}
