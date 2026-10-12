import 'edit_form.dart';
import 'form_errors.dart';

/// What a form section gets: the current values, the errors to show, and
/// a way to change the values.
class FormBinding {
  const FormBinding(this.form, this.errors, this._update);

  final EditForm form;

  /// Empty until the user first tries to save.
  final Set<FormError> errors;
  final void Function(EditForm Function(EditForm form) change) _update;

  /// Applies [change] to the form as it is when the change happens.
  void update(EditForm Function(EditForm form) change) => _update(change);

  /// The first of [kinds] the form has, to show under one field.
  FormError? errorOf(List<FormError> kinds) {
    for (final kind in kinds) {
      if (errors.contains(kind)) return kind;
    }
    return null;
  }
}
