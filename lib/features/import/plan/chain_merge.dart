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
/// from. An earlier record without an end date gets its own periods up to
/// its successor's start, at its own price, instead of its draft payments.
List<PlannedPayment> plannedPayments(List<ImportDraft> sources) {
  final byId = <String, PlannedPayment>{};
  for (final (i, source) in sources.indexed) {
    final successor = sources.elementAtOrNull(i + 1);
    final payments = successor != null && source.endDate == null
        ? _untilSuccessor(source, successor)
        : source.payments;
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
List<DraftPayment> _untilSuccessor(ImportDraft source, ImportDraft successor) {
  final start = source.startDate!;
  final cycle = source.cycle!;
  final cutoff = successor.startDate!.subtract(renewalTolerance(cycle));
  return [
    for (final date in {
      start,
      ...occurrencesFrom(start, cycle, untilExclusive: cutoff),
    })
      DraftPayment(
        date: date,
        amountMinor: source.priceMinor,
        currency: source.currency,
        origin: PaymentOrigin.backfilled,
      ),
  ];
}
