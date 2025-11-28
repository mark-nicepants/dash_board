import 'package:dash/src/actions/action.dart';
import 'package:dash/src/actions/action_color.dart';
import 'package:dash/src/components/partials/button.dart';
import 'package:dash/src/model/model.dart';
import 'package:jaspr/jaspr.dart';

/// Pre-configured action for canceling form operations.
///
/// This action navigates back using browser history, providing a consistent
/// way to exit forms without saving.
///
/// Example:
/// ```dart
/// @override
/// List<Action<User>> formActions(FormOperation operation) => [
///   SaveAction.make(),
///   CancelAction.make(),
/// ];
/// ```
class CancelAction<T extends Model> extends Action<T> {
  CancelAction() : super('cancel') {
    super.label('Cancel');
    super.color(ActionColor.secondary);
  }

  /// Factory method to create a cancel action.
  static CancelAction<T> make<T extends Model>() => CancelAction<T>();

  @override
  Component renderAsFormAction({bool isDisabled = false}) {
    return Button(
      label: getLabel(),
      variant: buttonVariant,
      size: ButtonSize.md,
      icon: getIcon(),
      iconPosition: getIconPosition(),
      attributes: const {'onclick': 'history.back()'},
    );
  }
}
