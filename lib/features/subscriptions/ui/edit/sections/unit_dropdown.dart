import 'package:flutter/material.dart';

import '../../../../../app/l10n/l10n.dart';
import '../../../../../app/theme/ebb_colors.dart';
import '../../../../../app/theme/ebb_type.dart';
import '../../../../../data/enums.dart';
import '../fields/field_decoration.dart';
import '../form/form_binding.dart';

// 设计稿的顺序：月、年、周、天。
const _units = [CycleUnit.month, CycleUnit.year, CycleUnit.week, CycleUnit.day];

/// The cycle unit, named for the typed count (「月」, 「months」).
class UnitDropdown extends StatelessWidget {
  const UnitDropdown({super.key, required this.binding});

  final FormBinding binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final count = binding.form.cycle?.count ?? 1;
    String name(CycleUnit unit) => switch (unit) {
      CycleUnit.day => l10n.editUnitDay(count),
      CycleUnit.week => l10n.editUnitWeek(count),
      CycleUnit.month => l10n.editUnitMonth(count),
      CycleUnit.year => l10n.editUnitYear(count),
    };
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: fieldBox(c),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CycleUnit>(
          value: binding.form.cycleUnit,
          isExpanded: true,
          style: EbbType.body.copyWith(color: c.ink),
          dropdownColor: c.surface,
          borderRadius: BorderRadius.circular(10),
          icon: Icon(Icons.expand_more, size: 18, color: c.ink2),
          onChanged: (unit) =>
              binding.update((f) => f.copyWith(cycleUnit: unit!)),
          items: [
            for (final unit in _units)
              DropdownMenuItem(value: unit, child: Text(name(unit))),
          ],
        ),
      ),
    );
  }
}
