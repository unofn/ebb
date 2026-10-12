import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/export/data/csv_exporter.dart';
import 'rate_providers.dart';
import 'repository_providers.dart';

part 'export_providers.g.dart';

/// CSV export of subscriptions and payments; the page calls it with the
/// current `AppLocalizations` and `today()`.
@Riverpod(keepAlive: true)
CsvExporter csvExporter(Ref ref) => CsvExporter(
  subscriptions: ref.watch(subscriptionRepositoryProvider),
  payments: ref.watch(paymentRepositoryProvider),
  settings: ref.watch(localSettingsProvider),
  rates: ref.watch(rateRepositoryProvider),
);
