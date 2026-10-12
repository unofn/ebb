import 'package:flutter/material.dart';

import '../../../../app/l10n/category_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../data/seed/categories.dart';
import '../../plan/category_choice.dart';

// 下拉框的值是字符串：null 显示提示「选择品类」（未选），空串是「不对应」。
const _none = '';

String? _valueOf(CategoryChoice choice) => switch (choice) {
  Undecided() => null,
  NoCategory() => _none,
  MapsToCategory(:final key) => key,
};

/// Picks one of the built-in categories, listed under their groups, or
/// 「不对应」; shows 「选择品类」 while [value] is undecided.
class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({super.key, required this.value, this.onChanged});

  final CategoryChoice value;

  /// Null disables the dropdown.
  final ValueChanged<CategoryChoice>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final body = EbbType.body.copyWith(color: c.ink);
    return Container(
      width: 116,
      height: 40,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.lineStrong),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _valueOf(value),
          isExpanded: true,
          style: body,
          dropdownColor: c.surface,
          borderRadius: BorderRadius.circular(10),
          menuMaxHeight: 420,
          icon: Icon(Icons.expand_more, size: 18, color: c.ink2),
          hint: Text(l10n.pickCategory, style: body.copyWith(color: c.ink3)),
          onChanged: onChanged == null
              ? null
              : (key) => onChanged!(switch (key) {
                  null => const CategoryChoice.undecided(),
                  _none => const CategoryChoice.none(),
                  final key => CategoryChoice.category(key),
                }),
          items: [
            DropdownMenuItem(value: _none, child: Text(l10n.noCategory)),
            for (final MapEntry(key: group, value: keys)
                in builtInCategories.entries) ...[
              // 分组名只作标题，不能选。
              DropdownMenuItem(
                value: 'group:$group',
                enabled: false,
                child: Text(
                  categoryGroupName(l10n, group),
                  style: EbbType.small.copyWith(
                    color: c.ink2,
                    fontWeight: EbbType.strong,
                  ),
                ),
              ),
              for (final key in keys)
                DropdownMenuItem(
                  value: key,
                  child: Text(
                    categoryName(l10n, key),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
