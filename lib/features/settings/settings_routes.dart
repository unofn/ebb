import 'package:go_router/go_router.dart';

import '../../app/router/route_paths.dart';
import 'pages/base_currency_page.dart';
import 'pages/categories_page.dart';
import 'pages/payment_methods_page.dart';
import 'pages/rates_page.dart';
import 'pages/tags_page.dart';

/// Where the settings pages live; the router mounts [settingsRoutes]
/// under `/settings`.
abstract final class SettingsPaths {
  static const root = RoutePaths.settings;
  static const baseCurrency = '$root/currency';
  static const rates = '$root/rates';
  static const paymentMethods = '$root/payment-methods';
  static const categories = '$root/categories';
  static const tags = '$root/tags';
}

final settingsRoutes = <RouteBase>[
  GoRoute(path: 'currency', builder: (_, _) => const BaseCurrencyPage()),
  GoRoute(path: 'rates', builder: (_, _) => const RatesPage()),
  GoRoute(
    path: 'payment-methods',
    builder: (_, _) => const PaymentMethodsPage(),
  ),
  GoRoute(path: 'categories', builder: (_, _) => const CategoriesPage()),
  GoRoute(path: 'tags', builder: (_, _) => const TagsPage()),
];
