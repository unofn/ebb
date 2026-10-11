import 'package:freezed_annotation/freezed_annotation.dart';

import '../plan/import_plan.dart';
import 'export_file.dart';

part 'import_session.freezed.dart';

/// The preview's state: the picked file and the plan with the user's
/// decisions so far.
@freezed
abstract class ImportSession with _$ImportSession {
  const factory ImportSession({
    required ExportFile file,
    required ImportPlan plan,

    /// Writing; the preview is read-only meanwhile.
    @Default(false) bool applying,
  }) = _ImportSession;
}
