import '../draft/source_app.dart';

/// Which app produced [json] (from `decodePayload`); null = unknown.
SourceApp? detectFormat(Map<String, dynamic> json) {
  if (json['subscriptions'] is! List) return null;
  if (json['version'] is num && json.containsKey('paymentMethods')) {
    return SourceApp.tilla;
  }
  if (json['appVersion'] is num) return SourceApp.subscriptionManager;
  return null;
}
