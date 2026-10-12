import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/l10n.dart';
import '../../app/theme/ebb_colors.dart';
import '../../app/theme/ebb_type.dart';
import 'home_search.dart';

/// The search box (40 high, on surface2). [closable] adds a close button
/// that hides it again (phone); otherwise it only clears.
class HomeSearchField extends ConsumerStatefulWidget {
  const HomeSearchField({super.key, this.closable = false});

  final bool closable;

  @override
  ConsumerState<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends ConsumerState<HomeSearchField> {
  late final _text = TextEditingController(
    text: ref.read(homeSearchProvider) ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final search = ref.read(homeSearchProvider.notifier);
    final query = ref.watch(homeSearchProvider) ?? '';
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _text,
        autofocus: widget.closable,
        onChanged: search.set,
        style: EbbType.body.copyWith(color: c.ink),
        decoration: InputDecoration(
          filled: true,
          fillColor: c.surface2,
          hintText: l10n.homeSearchHint,
          hintStyle: EbbType.body.copyWith(color: c.ink2),
          contentPadding: EdgeInsets.zero,
          prefixIcon: Icon(Icons.search, size: 20, color: c.ink2),
          suffixIcon: widget.closable || query.isNotEmpty
              ? IconButton(
                  tooltip: l10n.homeSearchClose,
                  icon: Icon(Icons.close, size: 18, color: c.ink2),
                  onPressed: () {
                    _text.clear();
                    widget.closable ? search.close() : search.set('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
