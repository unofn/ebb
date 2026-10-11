import 'package:freezed_annotation/freezed_annotation.dart';

import '../draft/import_warning.dart';

part 'import_result.freezed.dart';

/// What applying a plan wrote.
@freezed
abstract class ImportResult with _$ImportResult {
  const factory ImportResult({
    required int sourceRecords,
    required int created,

    /// Fields overwritten, payments added, category filled or restored.
    required int updated,
    required int unchanged,
    required int skipped,
    required int paymentsAdded,

    /// File warnings plus every record's warnings.
    @Default([]) List<ImportWarning> warnings,
  }) = _ImportResult;
}
