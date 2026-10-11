import '../../plan/import_plan.dart';
import '../../plan/plan_item.dart';

/// The preview's filter. Each item is in exactly one segment: items with
/// warnings only under [warned]; items deleted in the database under
/// [unchanged].
enum PreviewSegment { created, updated, unchanged, warned }

PreviewSegment segmentOf(PlanItem item) => item.warnings.isNotEmpty
    ? PreviewSegment.warned
    : switch (item.diff) {
        DiffStatus.create => PreviewSegment.created,
        DiffStatus.update => PreviewSegment.updated,
        DiffStatus.unchanged ||
        DiffStatus.deletedInDb => PreviewSegment.unchanged,
      };

extension PreviewSegments on ImportPlan {
  List<PlanItem> itemsIn(PreviewSegment segment) =>
      items.where((item) => segmentOf(item) == segment).toList();

  /// Rows in [segment]; file-level warnings are rows of [PreviewSegment.warned].
  int rowCountIn(PreviewSegment segment) =>
      itemsIn(segment).length +
      (segment == PreviewSegment.warned ? parsed.fileWarnings.length : 0);

  /// The first segment with rows, so the preview never opens on an empty one.
  PreviewSegment get firstFilledSegment => PreviewSegment.values.firstWhere(
    (s) => rowCountIn(s) > 0,
    orElse: () => PreviewSegment.created,
  );
}
