import 'category_choice.dart';
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

  /// Maps a source category ID to [choice].
  ImportPlan mapCategory(String sourceCategoryId, CategoryChoice choice) =>
      copyWith(categoryMapping: {...categoryMapping, sourceCategoryId: choice});

  /// Maps a label to [choice].
  ImportPlan mapLabel(String label, CategoryChoice choice) =>
      copyWith(labelCategoryMapping: {...labelCategoryMapping, label: choice});
}
