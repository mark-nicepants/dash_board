import 'package:dash/src/actions/handler/action_handler.dart';

/// Registration info for an action handler.
class ActionHandlerRegistration {
  /// The unique key for this handler (e.g., 'resource:users:action:archive').
  final String key;

  /// The action handler instance (singleton).
  final ActionHandler handler;

  /// The resource slug this handler belongs to (if resource-scoped).
  final String? resourceSlug;

  /// The action name.
  final String actionName;

  /// Whether this is a bulk action handler.
  final bool isBulk;

  const ActionHandlerRegistration({
    required this.key,
    required this.handler,
    this.resourceSlug,
    required this.actionName,
    this.isBulk = false,
  });
}

/// Registry for action handlers.
///
/// Handlers are automatically registered when actions are configured
/// during resource/panel setup. The registry generates unique keys
/// based on context (resource slug, action name, etc.).
///
/// ## Key Format
///
/// - Single record actions: `resource:{slug}:action:{name}`
/// - Bulk actions: `resource:{slug}:bulk:{name}`
/// - Global actions: `global:action:{name}`
///
/// ## Usage
///
/// ```dart
/// // Register during Panel.boot()
/// ActionHandlerRegistry.register(
///   resourceSlug: 'users',
///   actionName: 'archive',
///   handler: ArchiveUserHandler(),
/// );
///
/// // Lookup by key
/// final handler = ActionHandlerRegistry.get('resource:users:action:archive');
///
/// // Lookup by route
/// final handler = ActionHandlerRegistry.getForRoute('users', 'archive');
/// ```
class ActionHandlerRegistry {
  static final Map<String, ActionHandlerRegistration> _handlers = {};

  /// Registers an action handler.
  ///
  /// The handler is stored as a singleton - the same instance is used
  /// for all invocations.
  static void register({
    String? resourceSlug,
    required String actionName,
    required ActionHandler handler,
    bool isBulk = false,
  }) {
    final key = _buildKey(resourceSlug: resourceSlug, actionName: actionName, isBulk: isBulk);

    if (_handlers.containsKey(key)) {
      // Already registered - update the handler
      _handlers[key] = ActionHandlerRegistration(
        key: key,
        handler: handler,
        resourceSlug: resourceSlug,
        actionName: actionName,
        isBulk: isBulk,
      );
      return;
    }

    _handlers[key] = ActionHandlerRegistration(
      key: key,
      handler: handler,
      resourceSlug: resourceSlug,
      actionName: actionName,
      isBulk: isBulk,
    );
  }

  /// Gets a handler by its key.
  static ActionHandler? get(String key) {
    return _handlers[key]?.handler;
  }

  /// Gets a handler by resource slug and action name.
  static ActionHandler? getForRoute(String? resourceSlug, String actionName, {bool isBulk = false}) {
    final key = _buildKey(resourceSlug: resourceSlug, actionName: actionName, isBulk: isBulk);
    return _handlers[key]?.handler;
  }

  /// Gets all registered handlers.
  static List<ActionHandlerRegistration> getAll() {
    return _handlers.values.toList();
  }

  /// Gets all handlers for a specific resource.
  static List<ActionHandlerRegistration> getForResource(String resourceSlug) {
    return _handlers.values.where((r) => r.resourceSlug == resourceSlug).toList();
  }

  /// Checks if a handler is registered.
  static bool has(String key) => _handlers.containsKey(key);

  /// Checks if a handler is registered for a route.
  static bool hasForRoute(String? resourceSlug, String actionName, {bool isBulk = false}) {
    final key = _buildKey(resourceSlug: resourceSlug, actionName: actionName, isBulk: isBulk);
    return _handlers.containsKey(key);
  }

  /// Clears all registered handlers (for testing).
  static void clear() {
    _handlers.clear();
  }

  /// Builds a unique key for a handler.
  static String _buildKey({String? resourceSlug, required String actionName, bool isBulk = false}) {
    if (resourceSlug == null) {
      return 'global:action:$actionName';
    }

    final prefix = isBulk ? 'bulk' : 'action';
    return 'resource:$resourceSlug:$prefix:$actionName';
  }

  /// Gets the route path for a handler.
  ///
  /// Returns the URL path where this action can be triggered.
  static String getRoutePath(String basePath, String actionName, {dynamic recordId, bool isBulk = false}) {
    if (isBulk) {
      return '$basePath/actions/$actionName';
    }
    if (recordId != null) {
      return '$basePath/$recordId/actions/$actionName';
    }
    return '$basePath/actions/$actionName';
  }
}
