import '../../import/plan/normalize_name.dart';

/// Whether [query] finds a subscription named [name], in the category
/// shown as [category], with [tags]: its normalized text ([normalizeName]:
/// case, full-width forms, spacing) is part of any of them. A blank query
/// finds everything.
bool matchesSearch(
  String query, {
  required String name,
  String? category,
  Iterable<String> tags = const [],
}) {
  final q = normalizeName(query);
  if (q.isEmpty) return true;
  return [
    name,
    ?category,
    ...tags,
  ].any((text) => normalizeName(text).contains(q));
}
