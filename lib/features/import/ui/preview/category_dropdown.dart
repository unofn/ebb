import 'package:flutter/material.dart';

import '../../../../app/l10n/category_names.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_colors.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../data/seed/categories.dart';

// 「不对应」用空串占位：值为 null 的选项会顶替提示文字「选择品类」。
const _none = '';

/// Picks one of the built-in categories, listed under their groups;
/// null = none.
class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({super.key, required this.value, this.onChanged});

  final String? value;

  /// Null disables the dropdown.
  final ValueChanged<String?>? onChanged;

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
          value: value,
          isExpanded: true,
          style: body,
          dropdownColor: c.surface,
          borderRadius: BorderRadius.circular(10),
          menuMaxHeight: 420,
          icon: Icon(Icons.expand_more, size: 18, color: c.ink2),
          hint: Text(l10n.pickCategory, style: body.copyWith(color: c.ink3)),
          onChanged: onChanged == null
              ? null
              : (key) => onChanged!(key == _none ? null : key),
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
