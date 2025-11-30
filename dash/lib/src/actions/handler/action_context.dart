import 'package:dash/src/model/model.dart';

/// Context provided to action handlers when executing.
///
/// Contains all the information needed to handle an action:
/// - The record being acted upon (if applicable)
/// - Form data submitted with the action
/// - Resource metadata
/// - Request context (path, method, etc.)
///
/// Example:
/// ```dart
/// class ArchiveHandler extends ActionHandler {
///   @override
///   Future<ActionResult> handle(ActionContext context) async {
///     final record = context.record as User;
///     final reason = context.data['reason'];
///
///     await record.archive(reason: reason);
///
///     return ActionResult.success('User archived successfully');
///   }
/// }
/// ```
class ActionContext<T extends Model> {
  /// The record being acted upon (null for bulk actions without records).
  final T? record;

  /// Form data submitted with the action.
  final Map<String, dynamic> data;

  /// The resource slug (e.g., 'users', 'posts').
  final String resourceSlug;

  /// The action name (e.g., 'archive', 'restore').
  final String actionName;

  /// Selected record IDs for bulk actions.
  final List<dynamic>? selectedIds;

  /// The base path for the resource (e.g., '/admin/users').
  final String basePath;

  const ActionContext({
    this.record,
    required this.data,
    required this.resourceSlug,
    required this.actionName,
    this.selectedIds,
    required this.basePath,
  });

  /// Whether this is a bulk action with multiple records.
  bool get isBulkAction => selectedIds != null && selectedIds!.isNotEmpty;

  /// Whether this action has a single record.
  bool get hasSingleRecord => record != null;

  /// Gets the record, throwing if not present.
  T getRecord() {
    if (record == null) {
      throw StateError('ActionContext does not have a record');
    }
    return record!;
  }

  /// Gets a value from the form data.
  dynamic getValue(String key) => data[key];

  /// Gets a string value from the form data.
  String? getString(String key) => data[key]?.toString();

  /// Gets an int value from the form data.
  int? getInt(String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Gets a bool value from the form data.
  bool getBool(String key) {
    final value = data[key];
    if (value is bool) return value;
    if (value is String) return value == 'true' || value == '1' || value == 'on';
    return false;
  }
}
