import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router/route_paths.dart';
import '../import/apply/import_result.dart';
import '../import/ui/export_file.dart';

/// Asks for an export file, opens its preview, and reports what the
/// import wrote once the preview closes after importing.
Future<void> startImport(BuildContext context, WidgetRef ref) async {
  // 先取好：导入后首页从空状态换成列表，发起导入的 context 已不在树上。
  final router = GoRouter.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  final file = await ref.read(exportFilePickerProvider)();
  if (file == null) return;
  final result = await router.push<ImportResult>(
    RoutePaths.import,
    extra: file,
  );
  if (result == null) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        l10n.importDone(result.created, result.updated, result.paymentsAdded),
      ),
    ),
  );
}
