import 'dart:convert';
import 'dart:math';

/// [json] as base64 wrapped at 76 columns, like both apps' exports.
String base64Export(Object json) {
  final encoded = base64.encode(utf8.encode(jsonEncode(json)));
  return [
    for (var i = 0; i < encoded.length; i += 76)
      encoded.substring(i, min(i + 76, encoded.length)),
  ].join('\n');
}

/// A Tilla export file: the whole file is base64.
String tillaFile(Object json) => base64Export(json);

/// A SubscriptionManager export file: a few lines of text, a dash line,
/// then base64. The header is made up.
String subscriptionManagerFile(Object json) =>
    'Subscription Manager backup\n'
    'Generated 2026-01-02 - do not edit\n'
    '----------------------------------------\n'
    '${base64Export(json)}\n';
