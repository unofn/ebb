import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../data/enums.dart';
import '../../../../billing/cycle.dart';
import '../../../domain/default_next_date.dart';
import 'amount_input.dart';

part 'edit_form.freezed.dart';

// 表单值是纯 Dart：金额和整数按输入框原文保存，存库前再按币种解析，
// 这样换币种或输入一半时不丢原文。

/// What the edit form holds: the subscription columns it owns, as typed.
@freezed
abstract class EditForm with _$EditForm {
  const factory EditForm({
    @Default('') String name,

    /// The plan, e.g. 「标准」; stored as `description`.
    @Default('') String plan,
    @Default(SubscriptionKind.recurring) SubscriptionKind kind,
    required String currency,
    @Default('') String price,
    @Default(CycleUnit.month) CycleUnit cycleUnit,
    @Default('1') String cycleCount,

    /// First charge, or the purchase date of a one-time buy.
    DateTime? startDate,
    DateTime? nextDate,

    /// Whether [nextDate] follows the start, cycle and trial: until the
    /// user picks one on a new form, or while a stored row has none.
    @Default(true) bool nextDateFollows,
    @Default(true) bool autoRenew,
    @Default(false) bool trial,
    DateTime? trialEndsOn,
    @Default(false) bool intro,
    @Default('') String introPrice,
    DateTime? introEndsOn,
    @Default(false) bool shared,
    @Default('') String myShare,
    @Default(false) bool reimbursed,
    @Default(true) bool reminder,

    /// Empty follows the default in settings.
    @Default('') String reminderDays,

    /// Minutes after midnight; null follows the default in settings.
    int? reminderTime,
    String? categoryId,
    @Default(<String>{}) Set<String> tagIds,
    String? paymentMethodId,
    @Default('') String account,
    @Default('') String url,
    @Default('') String notes,

    /// 0xRRGGBB.
    int? color,

    /// Whether [color] is the user's choice (picked here, or stored);
    /// otherwise it follows the preset the name matches.
    @Default(false) bool colorChosen,
  }) = _EditForm;

  const EditForm._();

  bool get recurring => kind == SubscriptionKind.recurring;

  /// The cycle typed so far; null while the count is not a positive number.
  Cycle? get cycle => switch (int.tryParse(cycleCount.trim())) {
    final count? when count > 0 => Cycle(cycleUnit, count),
    _ => null,
  };

  int? get priceMinor => parseMinor(price, currency);

  /// This form with [nextDate] recomputed when it follows the inputs.
  EditForm settled(DateTime today) {
    final cycle = this.cycle;
    final start = startDate;
    if (!nextDateFollows || !recurring || cycle == null || start == null) {
      return this;
    }
    return copyWith(
      nextDate: defaultNextDate(
        start: start,
        cycle: cycle,
        trialEndsOn: trial ? trialEndsOn : null,
        today: today,
      ),
    );
  }
}
