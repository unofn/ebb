import 'package:crdt/crdt.dart' show Hlc;

import '../../../data/raw_rows.dart';
import '../../../data/sync_columns.dart';
import '../../rates/data/manual_rates.dart';
import 'backup_errors.dart';

/// `data.json`: the synced rows, the user's settings and manual rates.
class BackupData {
  const BackupData({
    required this.tables,
    required this.settings,
    required this.manualRates,
  });

  static const fileName = 'data.json';

  /// Table name → its rows as SQL stores them, soft-deleted ones included.
  final Map<String, List<RawRow>> tables;

  /// `local_meta` key → value, user settings only.
  final Map<String, String> settings;
  final List<ManualRate> manualRates;

  /// The rows of [table] that are not soft-deleted.
  Iterable<RawRow> live(String table) => (tables[table] ?? const <RawRow>[])
      .where((row) => row[deletedColumn] == 0);

  /// The newest `updated_at` of all rows; null when there are none.
  /// Throws [FormatException] for a stamp that is not an HLC.
  Hlc? get latestStamp {
    Hlc? latest;
    for (final rows in tables.values) {
      for (final row in rows) {
        final stamp = row[updatedAtColumn];
        if (stamp is! String || stamp.isEmpty) continue;
        final hlc = Hlc.parse(stamp);
        if (latest == null || hlc > latest) latest = hlc;
      }
    }
    return latest;
  }

  Map<String, Object?> toJson() => {
    'tables': tables,
    'settings': settings,
    'manualRates': [
      for (final rate in manualRates)
        {
          'base': rate.base,
          'currency': rate.currency,
          'overrideRate': rate.overrideRate,
        },
    ],
  };

  /// Throws [UnreadableBackup] when [json] does not have this shape.
  factory BackupData.fromJson(Map<String, Object?> json) {
    if (json case {
      'tables': final Map<String, Object?> tables,
      'settings': final Map<String, Object?> settings,
      'manualRates': final List<Object?> rates,
    }) {
      return BackupData(
        tables: tables.map((name, rows) => MapEntry(name, _rows(rows))),
        settings: settings.map(
          (key, value) => MapEntry(key, _as<String>(value)),
        ),
        manualRates: [for (final rate in rates) _manualRate(rate)],
      );
    }
    throw _damaged;
  }
}

const _damaged = UnreadableBackup(UnreadableReason.damaged);

T _as<T>(Object? value) => value is T ? value : throw _damaged;

List<RawRow> _rows(Object? rows) => [
  for (final row in _as<List<Object?>>(rows))
    {
      // SQL 层的值只有文本、整数、实数和空值。
      for (final MapEntry(:key, :value) in _as<RawRow>(row).entries)
        key: value is String || value is num || value == null
            ? value
            : throw _damaged,
    },
];

ManualRate _manualRate(Object? json) => switch (json) {
  {
    'base': final String base,
    'currency': final String currency,
    'overrideRate': final String overrideRate,
  } =>
    ManualRate(base: base, currency: currency, overrideRate: overrideRate),
  _ => throw _damaged,
};
