import 'package:drift/drift.dart';

import 'enums.dart';
import 'hlc_clock.dart';
import 'local_meta_store.dart';
import 'seed/categories.dart';
import 'tables/attachments.dart';
import 'tables/categories.dart';
import 'tables/import_links.dart';
import 'tables/local_meta.dart';
import 'tables/payment_methods.dart';
import 'tables/payments.dart';
import 'tables/subscriptions.dart';
import 'tables/tags.dart';
import 'writer.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Subscriptions,
    Payments,
    ImportLinks,
    Categories,
    Tags,
    SubscriptionTags,
    PaymentMethods,
    Attachments,
    LocalMeta,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// [executor]: `openConnection()` in the app, `NativeDatabase.memory()`
  /// in tests and tools.
  AppDatabase(super.executor);

  /// The single HLC source for this database.
  late final HlcClock hlcClock = HlcClock(this);

  /// All writes to synced tables go through here.
  late final Writer writer = Writer(this, hlcClock);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // 用一个临时时钟：共享的 hlcClock 可能正是触发这次打开、在等它完成的调用方。
      await seedCategories(this, Writer(this, HlcClock(this)));
      await writeMeta(LocalMetaKeys.baseCurrency, 'CNY');
    },
  );
}
