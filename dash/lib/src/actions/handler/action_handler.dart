import 'package:dash_board/src/actions/handler/action_context.dart';

/// Result of an action handler execution.
///
/// Indicates whether the action succeeded or failed, with an optional
/// message and redirect URL.
class ActionResult {
  /// Whether the action was successful.
  final bool success;

  /// Message to display to the user.
  final String? message;

  /// URL to redirect to after the action completes.
  final String? redirectUrl;

  /// Additional data returned by the action.
  final Map<String, dynamic>? data;

  const ActionResult._({required this.success, this.message, this.redirectUrl, this.data});

  /// Creates a successful result.
  ///
  /// ```dart
  /// return ActionResult.success('User archived successfully');
  /// ```
  factory ActionResult.success([String? message, String? redirectUrl]) {
    return ActionResult._(success: true, message: message, redirectUrl: redirectUrl);
  }

  /// Creates a successful result with a redirect.
  ///
  /// ```dart
  /// return ActionResult.successAndRedirect('/admin/users', 'User archived');
  /// ```
  factory ActionResult.successAndRedirect(String redirectUrl, [String? message]) {
    return ActionResult._(success: true, message: message, redirectUrl: redirectUrl);
  }

  /// Creates a failed result.
  ///
  /// ```dart
  /// return ActionResult.failure('Failed to archive user');
  /// ```
  factory ActionResult.failure([String? message]) {
    return ActionResult._(success: false, message: message);
  }

  /// Creates a result with additional data.
  factory ActionResult.withData(Map<String, dynamic> data, {bool success = true, String? message}) {
    return ActionResult._(success: success, message: message, data: data);
  }

  /// Whether the action failed.
  bool get failed => !success;
}

/// Abstract base class for action handlers.
///
/// Action handlers execute server-side logic when an action is triggered.
/// They are singletons (stateless) and receive all context via [ActionContext].
///
/// ## Creating a Handler
///
/// ```dart
/// class ArchiveUserHandler extends ActionHandler {
///   @override
///   String get name => 'archive';
///
///   @override
///   Future<ActionResult> handle(ActionContext context) async {
///     final user = context.record as User;
///
///     await user.archive();
///
///     return ActionResult.success('User archived successfully');
///   }
/// }
/// ```
///
/// ## Using with Actions
///
/// ```dart
/// Action.make('archive')
///   .label('Archive')
///   .handler(ArchiveUserHandler())
///   .requiresConfirmation()
/// ```
abstract class ActionHandler {
  /// The name of this handler (used for routing).
  ///
  /// Combined with resource slug to form unique action route:
  /// e.g., `/admin/users/actions/archive`
  String get name;

  /// Optional description for documentation.
  String? get description => null;

  /// Handles the action with the given context.
  ///
  /// Returns an [ActionResult] indicating success/failure and any
  /// messages or redirects.
  Future<ActionResult> handle(ActionContext context);

  /// Optional validation before the action executes.
  ///
  /// Return null if valid, or an error message if invalid.
  /// Override this to add custom validation logic.
  Future<String?> validate(ActionContext context) async => null;

  /// Called before the action handler executes.
  ///
  /// Override this to add pre-processing logic.
  Future<void> beforeHandle(ActionContext context) async {}

  /// Called after the action handler executes successfully.
  ///
  /// Override this to add post-processing logic.
  Future<void> afterHandle(ActionContext context, ActionResult result) async {}
}

/// A handler for bulk actions that operate on multiple records.
///
/// ```dart
/// class BulkArchiveHandler extends BulkActionHandler {
///   @override
///   String get name => 'bulk-archive';
///
///   @override
///   Future<ActionResult> handleBulk(ActionContext context, List<dynamic> ids) async {
///     final users = await User.query().whereIn('id', ids).get();
///
///     for (final user in users) {
///       await user.archive();
///     }
///
///     return ActionResult.success('${users.length} users archived');
///   }
/// }
/// ```
abstract class BulkActionHandler extends ActionHandler {
  @override
  Future<ActionResult> handle(ActionContext context) {
    if (!context.isBulkAction) {
      return Future.value(ActionResult.failure('No records selected'));
    }
    return handleBulk(context, context.selectedIds!);
  }

  /// Handles the bulk action with the selected record IDs.
  Future<ActionResult> handleBulk(ActionContext context, List<dynamic> ids);
}
