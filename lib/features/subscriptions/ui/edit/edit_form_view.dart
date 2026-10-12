import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/confirm_dialog.dart';
import '../../../../core/local_date.dart';
import '../../../../app/router/route_paths.dart';
import 'delete_subscription.dart';
import 'edit_app_bar.dart';
import 'edit_form_body.dart';
import 'edit_start.dart';
import 'form/edit_form.dart';
import 'form/form_binding.dart';
import 'form/form_errors.dart';
import 'save_form.dart';

/// The form itself: holds the values, saves them, and asks before
/// dropping unsaved changes.
class EditFormView extends ConsumerStatefulWidget {
  const EditFormView({super.key, required this.start, this.subscriptionId});

  final EditStart start;
  final String? subscriptionId;

  @override
  ConsumerState<EditFormView> createState() => _EditFormViewState();
}

class _EditFormViewState extends ConsumerState<EditFormView> {
  late EditForm _form = widget.start.form;

  /// Errors show from the first save attempt on.
  var _tried = false;
  var _saving = false;

  /// Deleted: leaving needs no unsaved-changes check.
  var _deleted = false;

  bool get _dirty => _form != widget.start.form;

  void _update(EditForm Function(EditForm form) change) =>
      setState(() => _form = change(_form).settled(today()));

  Future<void> _save() async {
    if (formErrors(_form).isNotEmpty) return setState(() => _tried = true);
    setState(() => _saving = true);
    try {
      await saveForm(ref, _form, widget.subscriptionId);
    } on Object {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.editSaveFailed)));
      return;
    }
    if (mounted) context.pop();
  }

  Future<void> _delete(String id) async {
    final name = widget.start.form.name;
    if (!await deleteSubscription(context, ref, id: id, name: name)) return;
    if (!mounted) return;
    setState(() => _deleted = true);
    // 详情页已经不存在了，直接回首页。
    context.go(RoutePaths.home);
  }

  Future<void> _confirmLeave() async {
    final l10n = context.l10n;
    final discard = await showConfirmDialog(
      context,
      title: l10n.editDiscardTitle,
      body: l10n.editDiscardBody,
      action: l10n.editDiscard,
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final binding = FormBinding(
      _form,
      _tried ? formErrors(_form) : const {},
      _update,
    );
    return PopScope(
      canPop: !_dirty || _saving || _deleted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        appBar: EditAppBar(
          title: widget.subscriptionId == null
              ? l10n.editTitleNew
              : l10n.editTitleEdit,
          // maybePop 才会经过 PopScope 的未保存确认；context.pop 不经过。
          onCancel: () => Navigator.of(context).maybePop(),
          onSave: _saving ? null : _save,
        ),
        body: EditFormBody(
          binding: binding,
          reminders: widget.start.reminders,
          onDelete: switch (widget.subscriptionId) {
            final id? => () => _delete(id),
            null => null,
          },
        ),
      ),
    );
  }
}
