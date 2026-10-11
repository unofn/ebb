import '../../../data/database.dart';
import '../../../data/missing_rows.dart';
import '../../../data/tables/tags.dart';
import '../draft/import_draft.dart';
import '../plan/import_ids.dart';

// 支付方式和标签可被多个订阅共用：按确定性 ID 只补缺，不覆盖用户改过的名字。

/// Writes [body]'s payment method if missing; returns its ID.
Future<String?> ensurePaymentMethod(AppDatabase db, ImportDraft body) async {
  final method = body.paymentMethod;
  if (method == null) return null;
  final id = importedPaymentMethodId(body.sourceApp, method);
  await db.insertMissing(db.paymentMethods, {
    id: PaymentMethodsCompanion.insert(id: id, name: method.name),
  });
  return id;
}

/// Writes the tags named [labels] and links them to [subscriptionId],
/// whichever is missing.
Future<void> ensureTags(
  AppDatabase db,
  String subscriptionId,
  List<String> labels,
) async {
  final names = {
    for (final label in labels)
      if (label.trim().isNotEmpty) tagIdOf(label): label.trim(),
  };
  await db.insertMissing(db.tags, {
    for (final MapEntry(key: id, value: name) in names.entries)
      id: TagsCompanion.insert(id: id, name: name),
  });
  final tagLinks = {
    for (final tagId in names.keys)
      subscriptionTagId(subscriptionId, tagId): tagId,
  };
  await db.insertMissing(db.subscriptionTags, {
    for (final MapEntry(key: id, value: tagId) in tagLinks.entries)
      id: SubscriptionTagsCompanion.insert(
        id: id,
        subscriptionId: subscriptionId,
        tagId: tagId,
      ),
  });
}
