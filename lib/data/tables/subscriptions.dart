import 'package:drift/drift.dart';

import '../enums.dart';
import '../sync_columns.dart';

/// Date-only columns hold UTC midnight of the calendar day.
class Subscriptions extends Table with SyncColumns {
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get kind => textEnum<SubscriptionKind>()();
  IntColumn get priceMinor => integer()();
  TextColumn get currency => text()();
  TextColumn get cycleUnit => textEnum<CycleUnit>().nullable()();
  IntColumn get cycleCount => integer().nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get nextDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  BoolColumn get endDateUnknown =>
      boolean().withDefault(const Constant(false))();
  TextColumn get status => textEnum<SubscriptionStatus>()();
  BoolColumn get autoRenew => boolean().withDefault(const Constant(true))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get paymentMethodId => text().nullable()();
  TextColumn get account => text().nullable()();

  /// 0xRRGGBB.
  IntColumn get color => integer().nullable()();
  TextColumn get iconAttachmentId => text().nullable()();
  TextColumn get url => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get reminderDays => integer().nullable()();

  /// Minutes after midnight.
  IntColumn get reminderTime => integer().nullable()();
  DateTimeColumn get trialEndsOn => dateTime().nullable()();
  IntColumn get introPriceMinor => integer().nullable()();
  DateTimeColumn get introEndsOn => dateTime().nullable()();

  /// My share when split with others; null = not shared.
  IntColumn get myShareMinor => integer().nullable()();
  BoolColumn get reimbursed => boolean().withDefault(const Constant(false))();
}
