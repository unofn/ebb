import 'package:drift/drift.dart';
import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';

/// A monthly CNY subscription with every required field filled; tests
/// adjust it with `copyWith`.
Subscription fakeSubscription({
  String id = 'sub-1',
  String name = 'Video',
  int priceMinor = 1200,
  String currency = 'CNY',
  CycleUnit? cycleUnit = CycleUnit.month,
  int? cycleCount = 1,
  DateTime? startDate,
  DateTime? nextDate,
  SubscriptionStatus status = SubscriptionStatus.active,
  bool autoRenew = true,
}) => Subscription(
  id: id,
  updatedAt: '',
  deleted: false,
  name: name,
  kind: SubscriptionKind.recurring,
  priceMinor: priceMinor,
  currency: currency,
  cycleUnit: cycleUnit,
  cycleCount: cycleCount,
  startDate: startDate,
  nextDate: nextDate,
  endDateUnknown: false,
  status: status,
  autoRenew: autoRenew,
  reminderEnabled: false,
  reimbursed: false,
);

/// [fakeSubscription] as a draft for repository writes; without [id] the
/// repository assigns one.
SubscriptionsCompanion fakeSubscriptionDraft(
  String name, {
  String? id,
  String? categoryId,
  String? paymentMethodId,
}) => fakeSubscription(name: name, priceMinor: 1500)
    .toCompanion(false)
    .copyWith(
      id: Value.absentIfNull(id),
      updatedAt: const Value.absent(),
      categoryId: Value(categoryId),
      paymentMethodId: Value(paymentMethodId),
    );

/// The row [id] as stored, deleted or not.
Future<Subscription> storedSubscription(AppDatabase db, String id) =>
    (db.select(db.subscriptions)..where((s) => s.id.equals(id))).getSingle();
