import 'package:collection/collection.dart';

import '../../draft/import_draft.dart';
import '../../draft/source_app.dart';
import '../../plan/category_choice.dart';
import '../../plan/import_plan.dart';

/// One source category (Tilla) or label (SubscriptionManager) to map.
typedef MappingRow = ({
  String source,
  int count,
  List<String> sampleNames,
  CategoryChoice choice,
});

bool hasMappingRows(ImportPlan plan) => mappingRows(plan).isNotEmpty;

/// What [plan]'s file can map to categories, most used first.
List<MappingRow> mappingRows(ImportPlan plan) {
  final drafts = plan.parsed.drafts;
  if (plan.sourceApp == SourceApp.tilla) {
    return _rows(
      plan.categoryMapping,
      (id) => drafts.where((d) => d.sourceCategoryId == id),
    );
  }
  return _rows(
    plan.labelCategoryMapping,
    (label) => drafts.where((d) => d.labels.contains(label)),
  );
}

List<MappingRow> _rows(
  Map<String, CategoryChoice> mapping,
  Iterable<ImportDraft> Function(String source) draftsOf,
) => [
  for (final MapEntry(key: source, value: choice) in mapping.entries)
    (
      source: source,
      count: draftsOf(source).length,
      sampleNames: draftsOf(source).map((d) => d.name).take(3).toList(),
      choice: choice,
    ),
].sortedBy<num>((row) => -row.count);
