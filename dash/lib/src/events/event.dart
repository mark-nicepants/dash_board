/// Base class for all events in the Dash system.
///
/// Events are typed payloads that flow through the [EventDispatcher].
/// Each event has a unique name and optional payload data.
///
/// ## Creating Custom Events
///
/// Extend this class to create application-specific events:
///
/// ```dart
/// class UserRegisteredEvent extends Event {
///   final User user;
///   final String registrationSource;
///
///   UserRegisteredEvent(this.user, {this.registrationSource = 'web'});
///
///   @override
///   String get name => 'user.registered';
///
///   @override
///   Map<String, dynamic> toPayload() => {
///     'user_id': user.id,
///     'email': user.email,
///     'source': registrationSource,
///   };
///
///   // Enable real-time frontend notifications
///   @override
///   bool get broadcastToFrontend => true;
/// }
/// ```
///
/// ## Dispatching Events
///
/// ```dart
/// final dispatcher = EventDispatcher.instance;
/// await dispatcher.dispatch(UserRegisteredEvent(user));
/// ```
///
/// ## Listening to Events
///
/// ```dart
/// dispatcher.listen<UserRegisteredEvent>((event) {
///   print('New user: ${event.user.email}');
/// });
/// ```
abstract class Event {
  /// The unique name of this event.
  ///
  /// Use dot notation for namespacing (e.g., 'users.created', 'orders.shipped').
  /// Model events use the format '{table}.{action}' (e.g., 'users.created').
  String get name;

  /// Timestamp when the event was created.
  final DateTime timestamp = DateTime.now();

  /// The session ID that caused this event.
  ///
  /// Used for session-scoped event broadcasting. When set, SSE connections
  /// will only receive events from their own session.
  String? sessionId;

  /// Converts the event to a JSON-serializable payload.
  ///
  /// This payload is used for:
  /// - Serializing events for SSE transmission to frontend
  /// - Logging event data
  /// - Webhook payloads
  Map<String, dynamic> toPayload();

  /// Whether this event should be broadcast to the frontend via SSE.
  ///
  /// Override to return `true` for events that should trigger
  /// real-time UI updates in the browser.
  bool get broadcastToFrontend => false;

  /// The SSE channel to broadcast on.
  ///
  /// Return `null` for global broadcast to all connected clients.
  /// Return a specific channel name to target specific subscribers.
  String? get broadcastChannel => null;

  /// Whether this event should only be sent to the session that caused it.
  ///
  /// When true, only the SSE connection with the matching sessionId will
  /// receive this event. When false, all connected clients receive it.
  bool get sessionScoped => true;

  @override
  String toString() => 'Event($name)';
}
