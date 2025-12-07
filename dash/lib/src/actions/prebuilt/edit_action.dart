import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/actions/action_color.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/model/model.dart';

/// Pre-configured action for editing records.
///
/// This action navigates to the edit page for a record:
///
/// ```dart
/// table.actions([
///   EditAction.make(),
/// ])
/// ```
///
/// The action is pre-configured with:
/// - Label: "Edit"
/// - Icon: [HeroIcons.pencilSquare]
/// - Color: [ActionColor.secondary]
/// - URL: `{basePath}/{recordId}/edit`
class EditAction<T extends Model> extends Action<T> {
  EditAction() : super('edit') {
    label('Edit');
    icon(HeroIcons.pencilSquare);
    color(ActionColor.secondary);
    url((record, basePath) => '$basePath/${getRecordId(record)}/edit');
  }

  /// Factory method to create a new EditAction.
  static EditAction<T> make<T extends Model>() => EditAction<T>();
}
