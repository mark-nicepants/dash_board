import 'package:dash_board/src/actions/action.dart';
import 'package:dash_board/src/actions/action_color.dart';
import 'package:dash_board/src/actions/action_size.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/model/model.dart';

/// Pre-configured action for creating new records.
///
/// This action navigates to the create page for a resource:
///
/// ```dart
/// // In a resource's indexHeaderActions:
/// @override
/// List<Action<User>> indexHeaderActions() => [
///   CreateAction.make(singularLabel),
/// ];
/// ```
///
/// The action is pre-configured with:
/// - Label: "New {singularLabel}" (customizable) or "Create"
/// - Icon: [HeroIcons.plus]
/// - Color: [ActionColor.primary]
/// - Size: [ActionSize.md]
/// - URL: `{basePath}/create`
class CreateAction<T extends Model> extends Action<T> {
  CreateAction([String? recordLabel]) : super('create') {
    if (recordLabel != null) {
      super.label('New $recordLabel');
    } else {
      super.label('Create');
    }
    icon(HeroIcons.plus);
    color(ActionColor.primary);
    size(ActionSize.md);
    // URL is set relative to basePath, pointing to /create
    url((record, basePath) => '$basePath/create');
  }

  /// Factory method to create a new CreateAction.
  ///
  /// Optionally pass a [recordLabel] to customize the button label:
  /// ```dart
  /// CreateAction.make()         // "Create"
  /// CreateAction.make('User')   // "New User"
  /// ```
  static CreateAction<T> make<T extends Model>([String? recordLabel]) => CreateAction<T>(recordLabel);
}
