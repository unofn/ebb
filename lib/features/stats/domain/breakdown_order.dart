import '../../../data/seed/categories.dart';
import '../../subscriptions/domain/name_order.dart';
import 'breakdown_shares.dart';

// 月均拆分里每一层的排序。

final _groupOrder = builtInCategories.keys.toList();

/// Larger first; ties in the built-in group order, uncategorized last.
int byGroupSize(GroupShare a, GroupShare b) =>
    switch (b.total.minor.compareTo(a.total.minor)) {
      0 => _groupRank(a.groupKey).compareTo(_groupRank(b.groupKey)),
      final order => order,
    };

int _groupRank(String? key) => switch (key) {
  null => _groupOrder.length + 1,
  final key when _groupOrder.contains(key) => _groupOrder.indexOf(key),
  _ => _groupOrder.length,
};

int byCategorySize(CategoryShare a, CategoryShare b) =>
    switch (b.total.minor.compareTo(a.total.minor)) {
      0 => (a.category?.sort ?? 0).compareTo(b.category?.sort ?? 0),
      final order => order,
    };

/// Larger first, amounts without a rate last; then by name.
int bySubscriptionSize(SubscriptionShare a, SubscriptionShare b) =>
    switch ((b.baseMinor ?? -1).compareTo(a.baseMinor ?? -1)) {
      0 => compareNames(a.subscription.name, b.subscription.name),
      final order => order,
    };
