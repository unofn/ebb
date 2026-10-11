import 'package:freezed_annotation/freezed_annotation.dart';

import 'import_draft.dart';
import 'import_warning.dart';
import 'source_app.dart';

part 'parsed_import.freezed.dart';

/// Everything an importer read from one export file.
@freezed
abstract class ParsedImport with _$ParsedImport {
  const factory ParsedImport({
    required SourceApp sourceApp,

    /// Tilla `version` or SubscriptionManager `appVersion`.
    required int formatVersion,
    DateTime? exportedAt,
    required List<ImportDraft> drafts,
    @Default([]) List<ImportWarning> fileWarnings,

    /// Source category ID → number of drafts using it (for the mapping UI).
    @Default({}) Map<String, int> sourceCategories,
  }) = _ParsedImport;
}
