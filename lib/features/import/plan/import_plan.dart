import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../draft/import_draft.dart';
import '../draft/parsed_import.dart';
import '../draft/source_app.dart';
import 'cross_app_matches.dart';
import 'existing_snapshot.dart';
import 'plan_item.dart';
import 'renewal_chains.dart';

import 'category_choice.dart';

part 'import_plan.freezed.dart';

/// What importing one file would do, plus the user's decisions. Immutable:
/// build with `buildPlan`, change with the `PlanDecisions` helpers.
@freezed
abstract class ImportPlan with _$ImportPlan {
  const factory ImportPlan({
    required ParsedImport parsed,
    required ExistingSnapshot existing,
    required List<RenewalChain> chains,

    /// Derived from the fields above and [splitChainIds].
    required List<PlanItem> items,
    required List<CrossAppMatch> crossAppMatches,

    /// Chains imported as separate subscriptions instead of merged.
    @Default({}) Set<String> splitChainIds,

    /// Item ID → skipped; items without a decision follow their default.
    @Default({}) Map<String, bool> skipDecisions,

    /// Source category ID (Tilla) → what it maps to.
    @Default({}) Map<String, CategoryChoice> categoryMapping,

    /// Label (SubscriptionManager) → what it maps to.
    @Default({}) Map<String, CategoryChoice> labelCategoryMapping,
  }) = _ImportPlan;

  const ImportPlan._();

  SourceApp get sourceApp => parsed.sourceApp;

  /// Skipped by decision, or by default when deleted in the database.
  bool isSkipped(PlanItem item) =>
      skipDecisions[item.id] ?? item.diff == DiffStatus.deletedInDb;

  Set<String> get skippedItemIds => {
    for (final item in items)
      if (isSkipped(item)) item.id,
  };

  /// The category key mapped for [body]: its source category's mapping,
  /// else the first of its labels that is mapped.
  String? categoryKeyFor(ImportDraft body) =>
      categoryMapping[body.sourceCategoryId]?.key ??
      body.labels.map((l) => labelCategoryMapping[l]?.key).nonNulls.firstOrNull;
}
