import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/actions/action_color.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/model/model.dart';

/// Pre-configured action for deleting records.
///
/// This action deletes a record with confirmation:
///
/// ```dart
/// table.actions([
///   DeleteAction.make(),
///   // Or with a custom label for the confirmation message:
///   DeleteAction.make('user'), // "Are you sure you want to delete this user?"
/// ])
/// ```
///
/// The action is pre-configured with:
/// - Label: "Delete"
/// - Icon: [HeroIcons.trash]
/// - Color: [ActionColor.danger]
/// - Requires confirmation with modal
/// - POST to: `{basePath}/{recordId}/delete`
class DeleteAction<T extends Model> extends Action<T> {
  DeleteAction([String? recordLabel]) : super('delete') {
    label('Delete');
    icon(HeroIcons.trash);
    color(ActionColor.danger);
    requiresConfirmation();
    modalIcon(HeroIcons.trash);
    modalIconColor(ActionColor.danger);
    confirmationButtonLabel('Delete');
    if (recordLabel != null) {
      confirmationHeading('Are you sure you want to delete this $recordLabel?');
    } else {
      confirmationHeading('Are you sure you want to delete this record?');
    }
    confirmationDescription('This action cannot be undone.');
    actionUrl((record, basePath) => '$basePath/${getRecordId(record)}/delete');
  }

  /// Factory method to create a new DeleteAction.
  ///
  /// Optionally pass a [recordLabel] to customize the confirmation message:
  /// ```dart
  /// DeleteAction.make()        // "Are you sure you want to delete this record?"
  /// DeleteAction.make('user')  // "Are you sure you want to delete this user?"
  /// ```
  static DeleteAction<T> make<T extends Model>([String? recordLabel]) => DeleteAction<T>(recordLabel);
}
