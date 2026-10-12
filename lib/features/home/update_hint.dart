import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/l10n/l10n.dart';
import '../../app/providers/update_providers.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import '../../app/widgets/ebb_marks.dart';
import '../../app/widgets/surface_card.dart';
import '../updates/domain/latest_release.dart';

/// 「Ebb 0.2.0 可以更新了 / 新增备份恢复和附件」, its own card: 「查看」
/// opens the release page; the close button hides this version for good.
class UpdateHint extends ConsumerWidget {
  const UpdateHint({super.key, required this.release});

  final LatestRelease release;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.colors;
    final small = EbbType.small.copyWith(color: c.ink);
    final strong = small.copyWith(fontWeight: EbbType.strong);
    return SurfaceCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: c.surface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const EbbMarks.small(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _line(l10n.updateHintTitle('${release.version}'), strong),
                    if (release.note case final note?)
                      _line(note, small.copyWith(color: c.ink2)),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: strong,
                  // 桌面默认的紧凑密度会把 32 压矮。
                  visualDensity: VisualDensity.standard,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => launchUrl(release.url),
                child: Text(l10n.updateView),
              ),
              IconButton(
                tooltip: l10n.updateDismiss,
                style: IconButton.styleFrom(
                  fixedSize: const Size.square(36),
                  minimumSize: const Size.square(36),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(Icons.close, size: 16, color: c.ink3),
                onPressed: () => unawaited(
                  ref
                      .read(updateSettingsProvider)
                      .setDismissedVersion('${release.version}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(String text, TextStyle style) =>
      Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: style);
}
