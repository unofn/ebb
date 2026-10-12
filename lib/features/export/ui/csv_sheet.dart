import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/l10n.dart';
import '../../../app/providers/export_providers.dart';
import '../../../app/widgets/option_sheet.dart';
import '../../../core/local_date.dart';
import '../domain/csv_export.dart';
import 'file_saver.dart';

extension ExportCsv on WidgetRef {
  /// Asks which list to export, makes its CSV and lets the user save it.
  Future<void> exportCsv(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final exporter = read(csvExporterProvider);
    final save = read(fileSaverProvider);
    final kind = await showOptionSheet<CsvKind>(
      context,
      title: l10n.csvExportTitle,
      options: [
        SheetOption(
          CsvKind.subscriptions,
          l10n.csvSubscriptionList,
          hint: l10n.csvSubscriptionListHint,
        ),
        SheetOption(
          CsvKind.payments,
          l10n.csvPaymentList,
          hint: l10n.csvPaymentListHint,
        ),
      ],
      foot: l10n.csvExportNote,
    );
    if (kind == null) return;
    try {
      final csv = switch (kind) {
        CsvKind.subscriptions => await exporter.exportSubscriptions(
          l10n,
          today(),
        ),
        CsvKind.payments => await exporter.exportPayments(l10n, today()),
      };
      if (!await save(csv.fileName, csv.bytes, 'text/csv')) return;
      final done = switch (kind) {
        CsvKind.subscriptions => l10n.csvExportedSubscriptions(csv.rowCount),
        CsvKind.payments => l10n.csvExportedPayments(csv.rowCount),
      };
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } on Exception {
      messenger.showSnackBar(SnackBar(content: Text(l10n.csvExportFailed)));
    }
  }
}
