import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/database.dart';
import '../../billing/monthly_cost.dart';

part 'duplicates.freezed.dart';

/// Two or more subscriptions in one category that all count toward the
/// monthly average: likely paying twice for the same thing.
@freezed
abstract class DuplicateGroup with _$DuplicateGroup {
  const factory DuplicateGroup({
    required String categoryId,

    /// In the order they were given.
    required List<Subscription> subscriptions,

    /// [duplicateKey] of the group; stored when the user dismisses it.
    required String key,
  }) = _DuplicateGroup;
}

/// Identifies a group by its category and members: once the members
/// change, so does the key, and a dismissed hint shows again.
String duplicateKey(String categoryId, Iterable<String> subscriptionIds) {
  final ids = subscriptionIds.sorted();
  return sha256.convert(utf8.encode('$categoryId:${ids.join(',')}')).toString();
}

/// Groups of [subs] counting toward the monthly average on [today]
/// ([countsTowardMonthly]) that share a category, except those whose key
/// is in [dismissed]. Uncategorized rows are never grouped.
List<DuplicateGroup> duplicateGroups(
  Iterable<Subscription> subs, {
  required DateTime today,
  Set<String> dismissed = const {},
}) {
  final byCategory = groupBy(
    subs.where((s) => s.categoryId != null && countsTowardMonthly(s, today)),
    (Subscription s) => s.categoryId!,
  );
  return [
    for (final MapEntry(key: categoryId, value: members) in byCategory.entries)
      if (members.length >= 2)
        if (duplicateKey(categoryId, members.map((s) => s.id)) case final key
            when !dismissed.contains(key))
          DuplicateGroup(
            categoryId: categoryId,
            subscriptions: members,
            key: key,
          ),
  ];
}
