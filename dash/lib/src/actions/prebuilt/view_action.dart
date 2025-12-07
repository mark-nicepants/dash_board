import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/actions/action_color.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/model/model.dart';

/// Pre-configured action for viewing records.
///
/// This action navigates to the view page for a record:
///
/// ```dart
/// table.actions([
///   ViewAction.make(),
/// ])
/// ```
///
/// The action is pre-configured with:
/// - Label: "View"
/// - Icon: [HeroIcons.eye]
/// - Color: [ActionColor.secondary]
/// - URL: `{basePath}/{recordId}`
class ViewAction<T extends Model> extends Action<T> {
  ViewAction() : super('view') {
    label('View');
    icon(HeroIcons.eye);
    color(ActionColor.secondary);
    url((record, basePath) => '$basePath/${getRecordId(record)}');
  }

  /// Factory method to create a new ViewAction.
  static ViewAction<T> make<T extends Model>() => ViewAction<T>();
}
