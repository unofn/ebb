import 'dart:io';

import 'package:collection/collection.dart';
import 'package:ebb/core/local_date.dart';
import 'package:ebb/core/money.dart';
import 'package:ebb/features/import/apply/import_result.dart';
import 'package:ebb/features/import/draft/import_warning.dart';
import 'package:ebb/features/import/draft/parsed_import.dart';
import 'package:ebb/features/import/plan/import_plan.dart';
import 'package:ebb/features/import/plan/plan_summary.dart';
import 'package:money2/money2.dart';

void out(String line) => stdout.writeln(line);

String _price(int minor, String code) =>
    '${Money.fromIntWithCurrency(minor, currencyOf(code)).amount} $code';

String _counts(Map<Enum, int> counts) => counts.isEmpty
    ? '-'
    : [
        for (final MapEntry(:key, :value) in counts.entries)
          '${key.name} $value',
      ].join(', ');

String resultLine(ImportResult r) =>
    'created ${r.created}, updated ${r.updated}, unchanged ${r.unchanged}, '
    'skipped ${r.skipped}, payments added ${r.paymentsAdded}';

void printFileWarnings(ParsedImport parsed) {
  out(
    'file-level warnings (incl. invalidRecord): '
    '${parsed.fileWarnings.length}',
  );
  for (final w in parsed.fileWarnings) {
    out('  ${w.code.name} id=${w.sourceId ?? '-'} ${w.detail ?? ''}');
  }
}

void printChains(ImportPlan plan) {
  out('renewal chains: ${plan.chains.length}');
  for (final chain in plan.chains) {
    final split = plan.splitChainIds.contains(chain.id) ? ' (split)' : '';
    out('  chain$split:');
    for (final m in chain.members) {
      out(
        '    ${m.name} | ${m.startDate?.isoDate} | '
        '${_price(m.priceMinor, m.currency)} | ${m.status.name}',
      );
    }
  }
}

void printPlanTotals(ImportPlan plan) {
  out(
    'resulting subscriptions: ${plan.subscriptionCount} '
    '(skipped ${plan.skippedCount})',
  );
  out('by status: ${_counts(plan.countsByStatus)}');
  out('by diff: ${_counts(plan.countsByDiff)}');
  out('payments to add: ${plan.paymentsToAdd}');
}

/// Record warnings grouped by code, each with the record's name.
void printRecordWarnings(ParsedImport parsed) {
  final named = [
    for (final d in parsed.drafts)
      for (final w in d.warnings) (d.name, w),
  ];
  out('record warnings: ${named.length}');
  final byCode = groupBy(named, (e) => e.$2.code);
  for (final code in ImportWarningCode.values) {
    final entries = byCode[code];
    if (entries == null) continue;
    out('  ${code.name} (${entries.length})');
    for (final (name, w) in entries) {
      out('    $name [${w.sourceId}] ${w.detail ?? ''}');
    }
  }
}

void printCrossAppMatches(ImportPlan plan) {
  out('cross-app same-name: ${plan.crossAppMatches.length}');
  for (final m in plan.crossAppMatches) {
    out(
      '  "${m.name}": ${m.itemIds.length} here, '
      '${m.existingSubscriptionIds.length} imported earlier',
    );
  }
}
