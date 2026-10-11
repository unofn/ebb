import 'package:json_annotation/json_annotation.dart';

part 'tilla_json.g.dart';

// 字段全部可空：缺字段或类型不对由映射层判定，而不是在反序列化时整份失败。
// 列表保持原样，逐条解析，坏的一条只跳过那一条。

/// The root of a Tilla backup (`version: 4`).
@JsonSerializable(createToJson: false)
class TillaExport {
  const TillaExport({
    this.date,
    this.version,
    this.subscriptions,
    this.paymentMethods,
  });

  factory TillaExport.fromJson(Map<String, dynamic> json) =>
      _$TillaExportFromJson(json);

  /// Export instant, epoch milliseconds.
  final num? date;
  final num? version;
  final List<dynamic>? subscriptions;
  final List<dynamic>? paymentMethods;
}

/// One subscription; dates are epoch milliseconds at the device's midnight.
@JsonSerializable(createToJson: false)
class TillaSubscription {
  const TillaSubscription({
    this.uuid,
    this.title,
    this.price,
    this.currency,
    this.billingCycle,
    this.isOneTime,
    this.billingDate,
    this.nextBillDate,
    this.endDate,
    this.isSuspended,
    this.paymentTracking,
    this.isReminderEnabled,
    this.reminderType,
    this.paymentMethodId,
    this.categoryId,
    this.color,
    this.icon,
    this.link,
    this.notes,
    this.payments,
  });

  factory TillaSubscription.fromJson(Map<String, dynamic> json) =>
      _$TillaSubscriptionFromJson(json);

  final String? uuid;
  final String? title;
  final num? price;
  final String? currency;
  final String? billingCycle;
  final bool? isOneTime;
  final num? billingDate;
  final num? nextBillDate;
  final num? endDate;
  final bool? isSuspended;
  final String? paymentTracking;
  final bool? isReminderEnabled;
  final String? reminderType;
  final String? paymentMethodId;
  final num? categoryId;

  /// Signed Android ARGB.
  final num? color;

  /// Base64 PNG with embedded newlines.
  final String? icon;
  final String? link;
  final String? notes;
  final List<dynamic>? payments;
}

@JsonSerializable(createToJson: false)
class TillaPaymentMethod {
  const TillaPaymentMethod({this.uuid, this.title});

  factory TillaPaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$TillaPaymentMethodFromJson(json);

  final String? uuid;
  final String? title;
}
