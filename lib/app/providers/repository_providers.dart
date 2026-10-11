import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/local_settings.dart';
import '../../features/payments/data/payment_method_repository.dart';
import '../../features/payments/data/payment_repository.dart';
import '../../features/subscriptions/data/category_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';
import '../../features/subscriptions/data/tag_repository.dart';
import 'storage_providers.dart';

part 'repository_providers.g.dart';

// 仓库都是数据库上的薄封装，跟数据库同寿命。

@Riverpod(keepAlive: true)
LocalSettings localSettings(Ref ref) =>
    LocalSettings(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) =>
    SubscriptionRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) =>
    PaymentRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
PaymentMethodRepository paymentMethodRepository(Ref ref) =>
    PaymentMethodRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) =>
    CategoryRepository(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
TagRepository tagRepository(Ref ref) =>
    TagRepository(ref.watch(appDatabaseProvider));

/// The base currency totals are converted into; follows settings changes.
@riverpod
Stream<String> baseCurrency(Ref ref) =>
    ref.watch(localSettingsProvider).watchBaseCurrency();
