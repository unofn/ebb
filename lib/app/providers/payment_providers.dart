import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import 'repository_providers.dart';

// 手写而不用 @riverpod：riverpod_generator 解析不到同一轮生成的 drift 行类型。

/// Every payment not deleted, for statistics and the calendar.
final allPaymentsProvider = StreamProvider.autoDispose<List<Payment>>(
  (ref) => ref.watch(paymentRepositoryProvider).watchAll(),
);
