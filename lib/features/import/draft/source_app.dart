/// An app Ebb imports from.
enum SourceApp {
  tilla('tilla'),
  subscriptionManager('subscription_manager');

  const SourceApp(this.key);

  /// Stored in `import_links.source_app` and used in stable IDs
  /// (`<key>:<sourceId>`); never change it.
  final String key;
}
