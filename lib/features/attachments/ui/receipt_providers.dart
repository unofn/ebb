import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app/providers/attachment_providers.dart';
import '../../../app/providers/storage_providers.dart';
import '../data/receipt.dart';

part 'receipt_providers.g.dart';

/// The receipts of subscription [subscriptionId].
@riverpod
Stream<Receipts> receipts(Ref ref, String subscriptionId) async* {
  final repository = await ref.watch(attachmentRepositoryProvider.future);
  yield* repository.watchReceipts(subscriptionId).map(Receipts.new);
}

/// The bytes stored as [storedName]; null when missing. Dropped once no
/// thumbnail or viewer page shows them.
@riverpod
Future<Uint8List?> storedBytes(Ref ref, String storedName) async {
  final store = await ref.watch(attachmentStoreProvider.future);
  return store.read(storedName);
}
