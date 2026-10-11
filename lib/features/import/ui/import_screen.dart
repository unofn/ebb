import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/widgets/content_width.dart';
import 'export_file.dart';
import 'import_controller.dart';
import 'preview/import_bar.dart';
import 'preview/import_preview.dart';
import 'unsupported_file_view.dart';

/// The import preview for [file], or for another file the user picks
/// instead; pops with the `ImportResult` once the import is written.
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key, required this.file});

  final ExportFile file;

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  late ExportFile _file = widget.file;

  Future<void> _chooseAnother() async {
    final next = await ref.read(exportFilePickerProvider)();
    if (next != null && mounted) setState(() => _file = next);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importControllerProvider(_file));
    final session = state.hasError ? null : state.value;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 4,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(context.l10n.importPreviewTitle),
      ),
      body: ContentWidth(
        child: state.hasError
            ? UnsupportedFileView(
                fileName: _file.name,
                onChooseAnother: _chooseAnother,
              )
            : session == null
            ? const Center(child: CircularProgressIndicator())
            : ImportPreview(session: session),
      ),
      bottomNavigationBar: session == null ? null : ImportBar(session: session),
    );
  }
}
