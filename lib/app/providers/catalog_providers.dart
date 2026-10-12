import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import 'repository_providers.dart';

// 编辑表单、批量编辑和设置共用的列表，都已排除软删除的行。
// 手写而不用 @riverpod：riverpod_generator 解析不到同一轮生成的 drift 行类型。

/// Categories in display order.
final categoriesProvider = StreamProvider.autoDispose<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Tags by name.
final tagsProvider = StreamProvider.autoDispose<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchAll(),
);

/// Payment methods by name.
final paymentMethodsProvider = StreamProvider.autoDispose<List<PaymentMethod>>(
  (ref) => ref.watch(paymentMethodRepositoryProvider).watchAll(),
);
