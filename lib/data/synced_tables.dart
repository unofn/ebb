import 'package:drift/drift.dart';

import 'database.dart';

extension SyncedTables on AppDatabase {
  /// Every synced table, referenced tables before the ones that point at
  /// them (insert in this order, clear in reverse). Backup and restore
  /// cover exactly these.
  // 以后新增带同步列的表，一定要加进来，否则备份会漏掉它
  // （test/data/synced_tables_test.dart 会提醒）。
  // 现在表之间没有 SQL 外键，顺序按逻辑引用排；唯一的环是订阅的
  // icon_attachment_id 指向附件，附件又指回订阅。
  List<TableInfo<Table, Object?>> get syncedTables => [
    categories,
    tags,
    paymentMethods,
    subscriptions,
    importLinks,
    payments,
    subscriptionTags,
    attachments,
  ];
}
