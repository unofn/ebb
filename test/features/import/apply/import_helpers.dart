import 'package:ebb/data/database.dart';
import 'package:ebb/features/import/apply/attachment_store.dart';
import 'package:ebb/features/import/apply/import_result.dart';
import 'package:ebb/features/import/apply/import_writer.dart';
import 'package:ebb/features/import/draft/import_draft.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/plan/import_plan.dart';
import 'package:ebb/features/import/plan/load_existing.dart';
import 'package:ebb/features/import/plan/plan_builder.dart';

import '../plan/fake_drafts.dart';

/// Plans [drafts] against [db], lets [decide] adjust the plan, applies it.
Future<ImportResult> importDrafts(
  AppDatabase db,
  List<ImportDraft> drafts, {
  SourceApp app = SourceApp.subscriptionManager,
  AttachmentStore? store,
  ImportPlan Function(ImportPlan plan)? decide,
}) async {
  final plan = buildPlan(
    parsedOf(drafts, app: app),
    await loadExisting(db, app),
  );
  return applyPlan(
    db,
    decide == null ? plan : decide(plan),
    store ?? MemoryAttachmentStore(),
  );
}

Future<List<Subscription>> subscriptionsIn(AppDatabase db) =>
    db.select(db.subscriptions).get();

Future<List<Payment>> paymentsIn(AppDatabase db) =>
    db.select(db.payments).get();
