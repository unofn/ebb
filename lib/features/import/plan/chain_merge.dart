import 'package:collection/collection.dart';

import '../../../data/enums.dart';
import '../../billing/schedule.dart';
import '../draft/import_draft.dart';
import 'import_ids.dart';
import 'plan_item.dart';
import 'renewal_chains.dart';

// 一条记录也当作长度为 1 的链处理，单条与合并走同一条路。

/// The subscription [sources] become: the last record's fields (latest
/// price, status, dates), every record's labels and warnings.
ImportDraft mergedBody(List<ImportDraft> sources) => sources.last.copyWith(
  labels: sources.expand((s) => s.labels).toSet().toList(),
  payments: const [],
  warnings: [for (final s in sources) ...s.warnings],
);

/// Every payment of [sources], each with the ID of the record it comes
/// from. An earlier record never pays on or after its successor's start:
/// without an end date it gets its own periods up to that start, at its own
/// price; with one, its draft payments are cut there.
List<PlannedPayment> plannedPayments(List<ImportDraft> sources) {
  final byId = <String, PlannedPayment>{};
  for (final (i, source) in sources.indexed) {
    final successor = sources.elementAtOrNull(i + 1);
    final payments = successor == null
        ? source.payments
        : source.endDate == null
        ? _untilSuccessor(source, successor)
        : [
            for (final p in source.payments)
              if (p.date.isBefore(_cutoff(source, successor))) p,
          ];
    for (final p in payments) {
      final id = importedPaymentId(source, p.date);
      byId.putIfAbsent(
        id,
        () => PlannedPayment(
          id: id,
          date: p.date,
          amountMinor: p.amountMinor,
          currency: p.currency,
          origin: p.origin,
        ),
      );
    }
  }
  return byId.values.toList();
}

// 后继的开始日可能比上一期晚几天（容差内）；那一期属于后继，不能再给前一条记一笔。
DateTime _cutoff(ImportDraft source, ImportDraft successor) =>
    successor.startDate!.subtract(renewalTolerance(source.cycle!));

List<DraftPayment> _untilSuccessor(ImportDraft source, ImportDraft successor) {
  final start = source.startDate!;
  return [
    for (final date in {
      start,
      ...occurrencesFrom(
        start,
        source.cycle!,
        untilExclusive: _cutoff(source, successor),
      ),
    })
      DraftPayment(
        date: date,
        amountMinor: source.priceMinor,
        currency: source.currency,
        origin: PaymentOrigin.backfilled,
      ),
  ];
}
