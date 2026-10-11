import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/enums.dart';
import '../../billing/cycle.dart';
import 'import_warning.dart';
import 'source_app.dart';

part 'import_draft.freezed.dart';

/// One source record mapped to Ebb's model, before planning and writing.
/// Dates are date-only (UTC midnight); amounts are minor units.
@freezed
abstract class ImportDraft with _$ImportDraft {
  const factory ImportDraft({
    required SourceApp sourceApp,
    required String sourceId,
    required String name,
    String? description,
    required SubscriptionKind kind,
    required int priceMinor,
    required String currency,
    Cycle? cycle,
    DateTime? startDate,
    DateTime? nextDate,
    DateTime? endDate,
    @Default(false) bool endDateUnknown,
    required SubscriptionStatus status,
    required bool autoRenew,
    String? sourceCategoryId,
    @Default([]) List<String> labels,
    DraftPaymentMethod? paymentMethod,

    /// 0xRRGGBB.
    int? color,
    Uint8List? iconPng,
    String? url,
    String? notes,
    @Default(false) bool reminderEnabled,
    int? reminderDays,

    /// Minutes after midnight.
    int? reminderTime,
    @Default([]) List<DraftPayment> payments,
    @Default([]) List<ImportWarning> warnings,
  }) = _ImportDraft;
}

@freezed
abstract class DraftPayment with _$DraftPayment {
  const factory DraftPayment({
    required DateTime date,
    required int amountMinor,
    required String currency,
    required PaymentOrigin origin,
  }) = _DraftPayment;
}

/// [sourceKey] identifies the method within its source: Tilla's uuid, or
/// SubscriptionManager's raw text.
@freezed
abstract class DraftPaymentMethod with _$DraftPaymentMethod {
  const factory DraftPaymentMethod({
    required String sourceKey,
    required String name,
  }) = _DraftPaymentMethod;
}
