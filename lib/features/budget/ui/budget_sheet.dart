import 'package:flutter/material.dart';

import '../../../app/theme/ebb_colors.dart';
import 'budget_form.dart';

/// The monthly budget: set it (typed or a quick amount), see it against
/// the monthly average, or clear it. Home, Stats and Settings open it.
Future<void> showBudgetSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  // 盖住底栏和侧栏，和画板一样占满屏幕底部。
  useRootNavigator: true,
  isScrollControlled: true,
  backgroundColor: context.colors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (context) => Padding(
    // 键盘弹出时整张面板上移。
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: const SafeArea(child: SingleChildScrollView(child: BudgetForm())),
  ),
);
