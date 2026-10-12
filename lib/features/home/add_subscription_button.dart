import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/l10n/l10n.dart';
import '../../app/router/route_paths.dart';
import '../../app/theme/ebb_colors.dart';

/// The solid 「+」 that opens the new-subscription form: 44 on phones, 40
/// beside the desktop search box.
class AddSubscriptionButton extends StatelessWidget {
  const AddSubscriptionButton({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IconButton.filled(
      tooltip: context.l10n.homeAdd,
      constraints: BoxConstraints.tight(Size.square(size)),
      style: IconButton.styleFrom(
        backgroundColor: c.ink,
        foregroundColor: c.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size >= 44 ? 12 : 10),
        ),
      ),
      onPressed: () => context.push(RoutePaths.newSubscription),
      icon: const Icon(Icons.add),
    );
  }
}
