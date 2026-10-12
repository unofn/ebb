import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/format/date_text.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/theme/ebb_type.dart';
import '../../../../core/local_date.dart';
import '../../data/receipt.dart';
import '../size_text.dart';

/// The image's name, and 「9月22日添加 · 1.2 MB」 under it.
class ViewerCaption extends StatelessWidget {
  const ViewerCaption({super.key, required this.receipt});

  final Receipt receipt;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    // 添加时间是时刻：先换到本机日历上的那一天，再按纯日期格式化。
    final added = receipt.addedAt.toLocal();
    final day = dayText(
      locale,
      utcDate(added.year, added.month, added.day),
      today(),
    );
    final meta =
        '${context.l10n.attachmentAddedOn(day)} · '
        '${sizeText(receipt.size)}';
    return Padding(
      // 底部留 36，系统手势条更高时让开它。
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        math.max(36, MediaQuery.paddingOf(context).bottom),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Text(
              receipt.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EbbType.body.copyWith(
                color: Colors.white,
                fontWeight: EbbType.strong,
              ),
            ),
            Text(
              meta,
              style: EbbType.small.tabular.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
