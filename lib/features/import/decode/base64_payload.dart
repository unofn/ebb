import 'dart:convert';

/// A line made only of dashes; SubscriptionManager puts its base64 after it.
final _dashLine = RegExp(r'^[ \t]*-+[ \t]*\r?$', multiLine: true);
final _whitespace = RegExp(r'\s');

/// Decodes an export file's text: the base64 after the all-dashes line if
/// there is one (SubscriptionManager), else the whole text (Tilla); then
/// UTF-8 and JSON. Throws [FormatException] unless the root is an object.
Map<String, dynamic> decodePayload(String text) {
  // base64 不含横线，取最后一条横线行即可容纳多条分隔线的说明头。
  final dashes = _dashLine.allMatches(text).lastOrNull;
  final payload = dashes == null ? text : text.substring(dashes.end);
  final bytes = base64.decode(
    base64.normalize(payload.replaceAll(_whitespace, '')),
  );
  final json = jsonDecode(utf8.decode(bytes));
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Export root is not a JSON object');
  }
  return json;
}
