import '../draft/source_app.dart';

/// The app's own name; not translated.
String sourceAppName(SourceApp app) => switch (app) {
  SourceApp.tilla => 'Tilla',
  SourceApp.subscriptionManager => 'SubscriptionManager',
};
