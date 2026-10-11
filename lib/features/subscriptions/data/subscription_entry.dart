import '../../../data/database.dart';

/// A subscription with the rows the list and detail show next to it;
/// deleted categories, payment methods and tags read as absent.
// 自写类型而不是 drift 行：riverpod_generator 解析不到同一轮生成的行类型。
class SubscriptionEntry {
  const SubscriptionEntry(
    this.subscription, {
    this.category,
    this.paymentMethod,
    this.tags = const [],
  });

  final Subscription subscription;
  final Category? category;
  final PaymentMethod? paymentMethod;

  /// By name.
  final List<Tag> tags;

  String get id => subscription.id;
}
