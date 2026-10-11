import '../draft/import_draft.dart';
import '../draft/parsed_import.dart';
import 'chain_merge.dart';
import 'cross_app_matches.dart';
import 'diff_existing.dart';
import 'existing_snapshot.dart';
import 'import_ids.dart';
import 'import_plan.dart';
import 'plan_item.dart';
import 'renewal_chains.dart';

/// The plan for importing [parsed] on top of [existing], with default
/// decisions: chains merged, deleted-in-database items skipped, nothing
/// mapped.
ImportPlan buildPlan(ParsedImport parsed, ExistingSnapshot existing) {
  final chains = findRenewalChains(parsed.drafts);
  return withItems(
    ImportPlan(
      parsed: parsed,
      existing: existing,
      chains: chains,
      items: const [],
      crossAppMatches: const [],
      // 链上记录已分别导入成不同订阅时，合并会把其中一个落成重复，默认拆开。
      splitChainIds: {
        for (final chain in chains)
          if (_linkedApart(chain, existing)) chain.id,
      },
      categoryMapping: {
        for (final id in parsed.sourceCategories.keys) id: null,
      },
      labelCategoryMapping: {
        for (final draft in parsed.drafts)
          for (final label in draft.labels) label: null,
      },
    ),
  );
}

/// [plan] compared again with [existing] (e.g. re-read inside the write
/// transaction); decisions are kept.
ImportPlan refreshPlan(ImportPlan plan, ExistingSnapshot existing) =>
    withItems(plan.copyWith(existing: existing));

/// [plan] with items and cross-app matches recomputed from its drafts,
/// existing data and chain decisions.
ImportPlan withItems(ImportPlan plan) {
  final mergedChainOf = {
    for (final chain in plan.chains)
      if (!plan.splitChainIds.contains(chain.id))
        for (final member in chain.members) member.sourceId: chain,
  };
  // 合并的链只出现一次，位置是它的记录在文件里第一次出现处。
  final placed = <String>{};
  final items = <PlanItem>[];
  for (final draft in plan.parsed.drafts) {
    final chain = mergedChainOf[draft.sourceId];
    if (chain == null) {
      items.add(_item([draft], null, plan.existing));
    } else if (placed.add(chain.id)) {
      items.add(_item(chain.members, chain.id, plan.existing));
    }
  }
  final matches = findCrossAppMatches(items, plan.existing.otherApps);
  final flagged = {for (final m in matches) ...m.itemIds};
  return plan.copyWith(
    items: [
      for (final item in items)
        item.copyWith(crossApp: flagged.contains(item.id)),
    ],
    crossAppMatches: matches,
  );
}

PlanItem _item(
  List<ImportDraft> sources,
  String? chainId,
  ExistingSnapshot existing,
) {
  final body = mergedBody(sources);
  final payments = plannedPayments(sources);
  final diff = diffExisting(sources, body, existing);
  final newPayments = payments
      .where((p) => !existing.paymentIds.contains(p.id))
      .length;
  return PlanItem(
    id: sourceKeyOf(sources.first),
    sources: sources,
    body: body,
    subscriptionId: diff.subscriptionId,
    chainId: chainId,
    diff: diff.status == DiffStatus.unchanged && newPayments > 0
        ? DiffStatus.update
        : diff.status,
    changes: diff.changes,
    payments: payments,
    newPaymentCount: newPayments,
  );
}

bool _linkedApart(RenewalChain chain, ExistingSnapshot existing) =>
    chain.members
        .map((m) => existing.links[m.sourceId])
        .nonNulls
        .toSet()
        .length >
    1;
