import 'package:dash_board/src/actions/handler/action_context.dart';
import 'package:dash_board/src/actions/handler/action_handler.dart';
import 'package:dash_board/src/cli/cli_logger.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/service_locator.dart';

/// Pre-configured action handler for toggling boolean column values.
///
/// This handler toggles a boolean field on a record when triggered by
/// a clickable [BooleanColumn] or [IconColumn].
///
/// The field name is passed via the action's data map under the 'field' key.
///
/// Example usage with BooleanColumn:
/// ```dart
/// BooleanColumn.make('is_active')
///   .clickable(), // Automatically uses ToggleBooleanHandler
/// ```
///
/// The handler:
/// 1. Finds the record by ID
/// 2. Gets the current boolean value of the field
/// 3. Toggles it (true -> false, false -> true)
/// 4. Saves the record
class ToggleBooleanHandler<T extends Model> extends ActionHandler {
  @override
  String get name => 'toggle-boolean';

  @override
  String? get description => 'Toggles a boolean field value on a record';

  @override
  Future<ActionResult> handle(ActionContext context) async {
    final record = context.record;
    if (record == null) {
      return ActionResult.failure('Record not found');
    }

    final field = context.data['field'] as String?;
    if (field == null) {
      return ActionResult.failure('Field name not provided');
    }

    try {
      // Get current value and toggle it
      final currentValue = record.toMap()[field];
      final newValue = !_parseBool(currentValue);

      // Get the resource to update the record
      final resource = resourceFromSlug(context.resourceSlug);
      await resource.updateRecord(record, {field: newValue});

      return ActionResult.success();
    } catch (e, stackTrace) {
      cliLogException(e, stackTrace: stackTrace);

      print('Error toggling boolean field: $e');
      return ActionResult.failure('Failed to toggle value: $e');
    }
  }

  /// Parses a value as a boolean.
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }
}
