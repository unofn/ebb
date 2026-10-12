import 'package:flutter/material.dart';

import '../../../../../app/theme/ebb_colors.dart';

/// A bottom sheet like `showOptionSheet`'s, for pickers with their own
/// content (search, ticks): surface color, up to 80% of the screen.
Future<T?> showPickSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      builder: builder,
    );
