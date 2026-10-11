import 'package:ebb/data/database.dart';
import 'package:ebb/features/import/draft/source_app.dart';
import 'package:ebb/features/import/ui/export_file.dart';

import '../../../support/export_files.dart';
import '../apply/import_helpers.dart';
import '../plan/fake_drafts.dart';
import '../subscription_manager/sm_fixture.dart';
import '../tilla/fake_tilla.dart';

// 手写假数据：名称、金额都是编的。

const _yearly = {'cycleDuration': 1, 'cycleRhythm': 1, 'cycleType': 1};

/// A SubscriptionManager file with four records: a yearly disk renewed
/// once (a chain of two), a stream also imported from Tilla, and a host
/// without a start date (a warning). Labels: Cloud ×2, Media ×1.
ExportFile smExportFile() => ExportFile(
  name: 'fake.subscriptions',
  text: subscriptionManagerFile(
    smExport([
      smRecord(1, {
        'name': 'Fake Disk',
        'active': false,
        'cycle': _yearly,
        'firstBillingDate': '2024-03-02',
        'expiringDate': '2025-03-02',
        'labels': ['Cloud'],
      }),
      smRecord(2, {
        'name': 'Fake Disk',
        'cycle': _yearly,
        'firstBillingDate': '2025-03-02',
        'labels': ['Cloud'],
      }),
      smRecord(3, {
        'name': 'Fake Tunes',
        'labels': ['Media'],
      }),
      smRecord(4, {'name': 'Fake Host'})..remove('firstBillingDate'),
    ]),
  ),
);

/// Imports a Tilla record named like the SM file's stream.
Future<void> importFromTilla(AppDatabase db) => importDrafts(db, [
  fakeDraft('t-1', name: 'Fake Tunes', app: SourceApp.tilla),
], app: SourceApp.tilla);

/// Valid base64 JSON, but from neither app.
ExportFile unknownExportFile() =>
    ExportFile(name: 'other.json', text: base64Export({'items': []}));

/// A Tilla file: two records in source category 3, one in 5.
ExportFile tillaExportFile() => ExportFile(
  name: 'backup_fake.txt',
  text: tillaFile(
    tillaExport([
      tillaRecord('a', {'title': 'Fake Video', 'categoryId': 3}),
      tillaRecord('b', {'title': 'Fake Films', 'categoryId': 3}),
      tillaRecord('c', {'title': 'Fake Notes', 'categoryId': 5}),
    ]),
  ),
);
