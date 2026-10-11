import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../sync_columns.dart';

class Tags extends Table with SyncColumns {
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();
}

class SubscriptionTags extends Table with SyncColumns {
  TextColumn get subscriptionId => text()();
  TextColumn get tagId => text()();
}

/// Tags with the same name share an ID across devices and sources:
/// `Netflix` and ` netflix` are one tag.
String tagIdOf(String name) => stableId('tag:${name.trim().toLowerCase()}');

/// The link row between [subscriptionId] and [tagId]: one per pair, so
/// removing and re-adding a tag revives the same row.
String subscriptionTagId(String subscriptionId, String tagId) =>
    stableId('$subscriptionId:tag:$tagId');
