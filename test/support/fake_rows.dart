import 'package:ebb/data/database.dart';
import 'package:ebb/data/enums.dart';

/// A payment of [subscriptionId] with every required field filled.
Payment fakePayment(
  String id,
  String subscriptionId,
  DateTime paidOn,
  int amountMinor, {
  String currency = 'CNY',
  String? rateToBase,
  String? baseCurrency,
  bool deleted = false,
}) => Payment(
  id: id,
  updatedAt: '',
  deleted: deleted,
  subscriptionId: subscriptionId,
  paidOn: paidOn,
  amountMinor: amountMinor,
  currency: currency,
  rateToBase: rateToBase,
  baseCurrency: baseCurrency,
  origin: PaymentOrigin.auto,
);

/// A built-in style category [id] in statistics group [groupKey].
Category fakeCategory(
  String id,
  String groupKey, {
  int sort = 0,
  bool deleted = false,
}) => Category(
  id: id,
  updatedAt: '',
  deleted: deleted,
  key: id,
  groupKey: groupKey,
  sort: sort,
);
