/// Locations the app navigates to; see `app_router.dart` for the pages.
abstract final class RoutePaths {
  static const home = '/';
  static const settings = '/settings';

  /// Needs the `ExportFile` as `extra`; open it through `startImport`.
  static const import = '/import';
  static const newSubscription = '/subscription/new';

  /// Takes the initially selected IDs (`Set<String>`) as `extra`.
  static const batch = '/batch';

  static String subscription(String id) => '/subscription/$id';
  static String editSubscription(String id) => '/subscription/$id/edit';
}
