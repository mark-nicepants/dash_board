import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/actions/action_color.dart';
import 'package:dash_board/src/components/partials/button.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/form/form_schema.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:jaspr/jaspr.dart';

/// Pre-configured action for saving/submitting forms.
///
/// This action is used as the primary submit button in edit forms.
/// It renders as a submit button that posts the form.
///
/// Example:
/// ```dart
/// @override
/// List<Action<User>> formActions(FormOperation operation) => [
///   SaveAction.make(),
///   CancelAction.make(),
/// ];
/// ```
class SaveAction<T extends Model> extends Action<T> {
  final FormOperation _operation;

  SaveAction({FormOperation operation = FormOperation.edit}) : _operation = operation, super('save') {
    super.icon(HeroIcons.check);
    super.color(ActionColor.primary);
    super.label(_defaultLabel);
  }

  /// Factory method to create a save action.
  ///
  /// The [operation] parameter determines the default label:
  /// - [FormOperation.create] -> "Create"
  /// - [FormOperation.edit] -> "Save Changes"
  static SaveAction<T> make<T extends Model>({FormOperation operation = FormOperation.edit}) =>
      SaveAction<T>(operation: operation);

  String get _defaultLabel => switch (_operation) {
    FormOperation.create => 'Create',
    FormOperation.edit => 'Save Changes',
    FormOperation.view => 'Close',
  };

  @override
  Component renderAsFormAction({bool isDisabled = false}) {
    return Button(
      label: getLabel(),
      variant: buttonVariant,
      size: ButtonSize.md,
      icon: getIcon(),
      iconPosition: getIconPosition(),
      type: ButtonType.submit,
      disabled: isDisabled,
    );
  }
}
