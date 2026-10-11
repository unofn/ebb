import 'import_plan.dart';
import 'plan_builder.dart';

/// The user's choices in the import preview; each returns a new plan.
extension PlanDecisions on ImportPlan {
  ImportPlan skip(String itemId) =>
      copyWith(skipDecisions: {...skipDecisions, itemId: true});

  /// Also imports an item skipped by default (deleted in the database),
  /// which restores it.
  ImportPlan unskip(String itemId) =>
      copyWith(skipDecisions: {...skipDecisions, itemId: false});

  /// Imports [chainId]'s records as separate subscriptions, as they are.
  ImportPlan splitChain(String chainId) =>
      withItems(copyWith(splitChainIds: {...splitChainIds, chainId}));

  ImportPlan mergeChain(String chainId) =>
      withItems(copyWith(splitChainIds: {...splitChainIds}..remove(chainId)));

  /// Maps a source category ID to an Ebb category key (null = none).
  ImportPlan mapCategory(String sourceCategoryId, String? categoryKey) =>
      copyWith(
        categoryMapping: {...categoryMapping, sourceCategoryId: categoryKey},
      );

  /// Maps a label to an Ebb category key (null = none).
  ImportPlan mapLabel(String label, String? categoryKey) => copyWith(
    labelCategoryMapping: {...labelCategoryMapping, label: categoryKey},
  );
}
