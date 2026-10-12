import 'package:drift/drift.dart';

import 'database.steps.dart';
import 'enums.dart';
import 'hlc_clock.dart';
import 'local_meta_store.dart';
import 'seed/categories.dart';
import 'tables/attachments.dart';
import 'tables/cached_rates.dart';
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
    CachedRates,
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // 用一个临时时钟：共享的 hlcClock 可能正是触发这次打开、在等它完成的调用方。
      await seedCategories(this, Writer(this, HlcClock(this)));
      await writeMeta(LocalMetaKeys.baseCurrency, 'CNY');
    },
    // 分步迁移由 `dart run drift_dev make-migrations` 生成（见 build.yaml）；
    // 每次改表：先升 schemaVersion，再跑它，最后在这里补上新的一步。
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        await m.createTable(schema.exchangeRates);
      },
      from2To3: (m, schema) async {
        await m.addColumn(schema.payments, schema.payments.baseCurrency);
        // 已有付款的汇率都是对着当时的基准货币记的；没设过就是默认的 CNY。
        await customStatement(
          'UPDATE payments SET base_currency = COALESCE('
          '(SELECT value FROM local_meta WHERE key = ?), ?)',
          [LocalMetaKeys.baseCurrency, 'CNY'],
        );
      },
    ),
  );
}
