import 'dart:math';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import '../../billing/schedule.dart';
import '../draft/import_draft.dart';
import 'import_ids.dart';
import 'normalize_name.dart';

part 'renewal_chains.freezed.dart';

/// Records of one source that look like successive renewals of the same
/// subscription (the user created a new record each time and closed the
/// old one). [members] are in start-date order, at least two.
@freezed
abstract class RenewalChain with _$RenewalChain {
  const factory RenewalChain({
    /// The first member's source key.
    required String id,
    required List<ImportDraft> members,
  }) = _RenewalChain;
}

/// How far a successor's start may stray from [cycle]'s next occurrence:
/// max(3 days, 15% of the cycle).
Duration renewalTolerance(Cycle cycle) =>
    Duration(hours: (max(3, 0.15 * cycle.approxDays) * 24).round());

/// Whether [next] starts about one cycle of [previous] after it, with
/// [previous] no longer active.
bool isRenewal(ImportDraft previous, ImportDraft next) {
  if (previous.status == SubscriptionStatus.active) return false;
  final cycle = previous.cycle!;
  final expected = occurrence(previous.startDate!, cycle, 1);
  return next.startDate!.difference(expected).abs() <= renewalTolerance(cycle);
}

/// Renewal chains among [drafts]: same source, same normalized name,
/// recurring with a cycle and a start date; consecutive by start date.
List<RenewalChain> findRenewalChains(List<ImportDraft> drafts) {
  final groups = groupBy(
    drafts.where(_chainable),
    (d) => (d.sourceApp, normalizeName(d.name)),
  );
  return [
    for (final group in groups.values)
      ..._chainsIn(group.sortedBy((d) => d.startDate!)),
  ];
}

bool _chainable(ImportDraft d) =>
    d.kind == SubscriptionKind.recurring &&
    d.cycle != null &&
    d.startDate != null;

Iterable<RenewalChain> _chainsIn(List<ImportDraft> sorted) sync* {
  var run = [sorted.first];
  for (final next in sorted.skip(1)) {
    if (isRenewal(run.last, next)) {
      run.add(next);
      continue;
    }
    if (run.length > 1) yield _chainOf(run);
    run = [next];
  }
  if (run.length > 1) yield _chainOf(run);
}

RenewalChain _chainOf(List<ImportDraft> members) =>
    RenewalChain(id: sourceKeyOf(members.first), members: members);
