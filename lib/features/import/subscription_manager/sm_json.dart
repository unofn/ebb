import 'package:json_annotation/json_annotation.dart';

part 'sm_json.g.dart';

// SubscriptionManager 导出的 JSON 结构，见 docs/import-formats.md。
// checked: true 让类型不符统一抛 CheckedFromJsonException，按条跳过。

/// The export root. Records stay raw so one bad record can be skipped.
@JsonSerializable(createToJson: false, checked: true)
class SmExport {
  SmExport({
    required this.appVersion,
    this.date,
    required this.subscriptions,
    this.notifications = const [],
  });

  factory SmExport.fromJson(Map<String, dynamic> json) =>
      _$SmExportFromJson(json);

  final int appVersion;

  /// Device-local time without a zone, e.g. `Oct 11, 2026 15:12:53`.
  final String? date;
  final List<dynamic> subscriptions;
  final List<dynamic> notifications;
}

@JsonSerializable(createToJson: false, checked: true)
class SmSubscription {
  SmSubscription({
    required this.id,
    required this.name,
    this.description,
    this.note,
    required this.type,
    required this.active,
    required this.price,
    this.cycle,
    this.firstBillingDate,
    this.expiringDate,
    this.duration,
    this.labels = const [],
    this.paymentMethod,
    this.color,
  });

  factory SmSubscription.fromJson(Map<String, dynamic> json) =>
      _$SmSubscriptionFromJson(json);

  final int id;
  final String name;
  final String? description;
  final String? note;

  /// 0 recurring, 1 one-time.
  final int type;
  final bool active;
  final SmPrice price;
  final SmCycle? cycle;

  /// `YYYY-MM-DD`.
  final String? firstBillingDate;
  final String? expiringDate;

  /// Always -1 in samples (presumably "unlimited payments").
  final int? duration;
  final List<String> labels;
  final String? paymentMethod;

  /// `#RRGGBB`.
  final String? color;
}

@JsonSerializable(createToJson: false, checked: true)
class SmPrice {
  SmPrice({required this.amount, this.currencyCode});

  factory SmPrice.fromJson(Map<String, dynamic> json) =>
      _$SmPriceFromJson(json);

  final num amount;
  final String? currencyCode;
}

/// Every [cycleDuration] units of [cycleRhythm], a `java.util.Calendar`
/// field constant.
@JsonSerializable(createToJson: false, checked: true)
class SmCycle {
  SmCycle({required this.cycleDuration, required this.cycleRhythm});

  factory SmCycle.fromJson(Map<String, dynamic> json) =>
      _$SmCycleFromJson(json);

  final int cycleDuration;
  final int cycleRhythm;
}

@JsonSerializable(createToJson: false, checked: true)
class SmNotification {
  SmNotification({
    required this.subscriptionId,
    required this.status,
    this.time,
    this.cycle,
  });

  factory SmNotification.fromJson(Map<String, dynamic> json) =>
      _$SmNotificationFromJson(json);

  final int subscriptionId;

  /// 1 = on.
  final int status;

  /// `HH:mm`.
  final String? time;
  final SmCycle? cycle;
}
