import 'dart:io';

import 'package:ebb/data/database.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:ebb/features/import/apply/import_writer.dart';
import 'package:ebb/features/import/decode/base64_payload.dart';
import 'package:ebb/features/import/decode/detect_format.dart';
import 'package:ebb/features/import/draft/parsed_import.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/plan/import_plan.dart';
import 'package:ebb/features/import/plan/load_existing.dart';
import 'package:ebb/features/import/plan/plan_builder.dart';
import 'package:ebb/features/import/subscription_manager/sm_importer.dart';
import 'package:ebb/features/import/tilla/tilla_importer.dart';

import 'smoke_report.dart';

/// Imports the export at [path] into [db] twice (default decisions) and
/// prints what each step did.
Future<void> smokeFile(AppDatabase db, String path) async {
  out('=== $path');
  final json = decodePayload(await File(path).readAsString());
  final app = detectFormat(json);
  if (app == null) {
    out('  unrecognized format; skipped\n');
    return;
  }
  final parsed = switch (app) {
    SourceApp.tilla => parseTilla(json),
    SourceApp.subscriptionManager => parseSubscriptionManager(json),
  };
  final records = (json['subscriptions'] as List).length;
  out('format: ${app.key} v${parsed.formatVersion}');
  out('source records: $records, drafts after parse: ${parsed.drafts.length}');

  final plan = await _plan(db, parsed);
  printFileWarnings(parsed);
  printChains(plan);
  printPlanTotals(plan);
  final first = await applyPlan(db, plan, MemoryAttachmentStore());
  out('applied: ${resultLine(first)}');
  printRecordWarnings(parsed);
  printCrossAppMatches(plan);

  final again = await applyPlan(
    db,
    await _plan(db, parsed),
    MemoryAttachmentStore(),
  );
  final idempotent =
      again.created == 0 && again.updated == 0 && again.paymentsAdded == 0;
  out(
    're-import: ${resultLine(again)} '
    '${idempotent ? '(idempotent)' : '(NOT IDEMPOTENT)'}\n',
  );
}

Future<ImportPlan> _plan(AppDatabase db, ParsedImport parsed) async =>
    buildPlan(parsed, await loadExisting(db, parsed.sourceApp));
