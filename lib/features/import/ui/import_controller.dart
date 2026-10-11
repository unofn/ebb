import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/storage_providers.dart';
import '../apply/import_result.dart';
import '../apply/import_writer.dart';
import '../decode/read_export.dart';
import '../plan/import_plan.dart';
import '../plan/load_existing.dart';
import '../plan/plan_builder.dart';
import '../plan/plan_decisions.dart';
import 'export_file.dart';
import 'import_session.dart';

part 'import_controller.g.dart';

/// Reads [file], plans its import against the database, records the
/// user's decisions and applies the plan. Fails with
/// [UnsupportedExportFile] for files of other formats.
@Riverpod(retry: _noRetry)
class ImportController extends _$ImportController {
  @override
  Future<ImportSession> build(ExportFile file) async {
    final parsed = readExport(file.text);
    final db = ref.watch(appDatabaseProvider);
    final existing = await loadExisting(db, parsed.sourceApp);
    return ImportSession(file: file, plan: buildPlan(parsed, existing));
  }

  void setChainMerged(String chainId, {required bool merged}) => _decide(
    (plan) => merged ? plan.mergeChain(chainId) : plan.splitChain(chainId),
  );

  void setSkipped(Iterable<String> itemIds, {required bool skipped}) => _decide(
    (plan) => itemIds.fold(
      plan,
      (plan, id) => skipped ? plan.skip(id) : plan.unskip(id),
    ),
  );

  void mapSourceCategory(String sourceCategoryId, String? categoryKey) =>
      _decide((plan) => plan.mapCategory(sourceCategoryId, categoryKey));

  void mapLabel(String label, String? categoryKey) =>
      _decide((plan) => plan.mapLabel(label, categoryKey));

  /// Writes the plan; throws if writing fails (then nothing was written).
  Future<ImportResult> apply() async {
    final session = state.requireValue;
    state = AsyncData(session.copyWith(applying: true));
    try {
      final store = await ref.read(attachmentStoreProvider.future);
      final db = ref.read(appDatabaseProvider);
      return await applyPlan(db, session.plan, store);
    } finally {
      if (ref.mounted) state = AsyncData(session);
    }
  }

  void _decide(ImportPlan Function(ImportPlan plan) change) {
    final session = state.requireValue;
    if (session.applying) return;
    state = AsyncData(session.copyWith(plan: change(session.plan)));
  }
}

/// Reading the same file again fails the same way; don't retry.
Duration? _noRetry(int retryCount, Object error) => null;
