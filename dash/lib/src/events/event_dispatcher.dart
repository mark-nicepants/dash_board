import 'dart:async';

import 'package:dash_board/src/events/event.dart';

/// Type for event listener callbacks with typed events.
typedef EventListener<T extends Event> = FutureOr<void> Function(T event);

/// Type for generic event listener that receives any event.
typedef GenericEventListener = FutureOr<void> Function(Event event);

/// Represents an SSE connection with its associated session.
class _SSEConnection {
  final StreamController<Event> controller;
  final String? sessionId;
  final DateTime connectedAt;

  _SSEConnection({required this.controller, required this.sessionId}) : connectedAt = DateTime.now();

  bool get isClosed => controller.isClosed;
}

/// Central dispatcher for all events in the Dash system.
///
/// The EventDispatcher is a singleton that manages event registration
/// and broadcasting. It supports:
/// - Type-safe event listeners
/// - Wildcard listeners (listen to all events)
/// - Name-based listeners (listen by event name pattern)
/// - Async event handling
/// - Session-scoped frontend broadcasting via SSE streams
///
/// ## Basic Usage
///
/// ```dart
/// final dispatcher = EventDispatcher.instance;
///
/// // Listen to specific event type
/// dispatcher.listen<UserCreatedEvent>((event) {
///   print('User created: ${event.user.email}');
/// });
///
/// // Listen to all events
/// dispatcher.listenAll((event) {
///   print('Event: ${event.name}');
/// });
///
/// // Dispatch an event
/// await dispatcher.dispatch(UserCreatedEvent(user));
/// ```
///
/// ## Name-Based Listening
///
/// ```dart
/// // Listen to events by name (useful for dynamic subscriptions)
/// dispatcher.listenTo('users.created', (event) {
///   print('User created event received');
/// });
///
/// // Listen to events matching a pattern
/// dispatcher.listenToPattern('users.*', (event) {
///   print('User event: ${event.name}');
/// });
/// ```
///
/// ## Frontend Integration
///
/// ```dart
/// // Create an SSE stream for a client with session
/// final stream = dispatcher.createSSEStream(sessionId: 'abc123');
///
/// // Events with broadcastToFrontend=true will be sent to this stream
/// // Session-scoped events only go to matching sessions
/// ```
class EventDispatcher {
  static EventDispatcher? _instance;

  /// Gets the singleton instance of the EventDispatcher.
  static EventDispatcher get instance {
    _instance ??= EventDispatcher._();
    return _instance!;
  }

  /// Resets the singleton instance (useful for testing).
  static void reset() {
    _instance?._dispose();
    _instance = null;
  }

  EventDispatcher._();

  /// Listeners mapped by event type.
  final Map<Type, List<GenericEventListener>> _typeListeners = {};

  /// Listeners mapped by event name.
  final Map<String, List<GenericEventListener>> _nameListeners = {};

  /// Pattern-based listeners (e.g., 'users.*').
  final Map<String, List<GenericEventListener>> _patternListeners = {};

  /// Listeners for all events.
  final List<GenericEventListener> _globalListeners = [];

  /// Session-aware SSE connections for frontend broadcasting.
  final List<_SSEConnection> _sseConnections = [];

  /// Whether to log events (useful for debugging).
  bool enableLogging = false;

  /// Registers a typed listener for a specific event type.
  ///
  /// Example:
  /// ```dart
  /// dispatcher.listen<ModelCreatedEvent>((event) {
  ///   print('Model created: ${event.model.table}');
  /// });
  /// ```
  void listen<T extends Event>(EventListener<T> listener) {
    _typeListeners.putIfAbsent(T, () => []);
    _typeListeners[T]!.add((event) => listener(event as T));
  }

  /// Registers a listener for events with a specific name.
  ///
  /// Example:
  /// ```dart
  /// dispatcher.listenTo('users.created', (event) {
  ///   print('User created');
  /// });
  /// ```
  void listenTo(String eventName, GenericEventListener listener) {
    _nameListeners.putIfAbsent(eventName, () => []);
    _nameListeners[eventName]!.add(listener);
  }

  /// Registers a listener for events matching a pattern.
  ///
  /// Supports wildcards:
  /// - `users.*` matches `users.created`, `users.updated`, etc.
  /// - `*.created` matches `users.created`, `posts.created`, etc.
  /// - `*` matches all events
  ///
  /// Example:
  /// ```dart
  /// dispatcher.listenToPattern('users.*', (event) {
  ///   print('User event: ${event.name}');
  /// });
  /// ```
  void listenToPattern(String pattern, GenericEventListener listener) {
    _patternListeners.putIfAbsent(pattern, () => []);
    _patternListeners[pattern]!.add(listener);
  }

  /// Registers a listener for all events.
  ///
  /// Example:
  /// ```dart
  /// dispatcher.listenAll((event) {
  ///   print('Event dispatched: ${event.name}');
  /// });
  /// ```
  void listenAll(GenericEventListener listener) {
    _globalListeners.add(listener);
  }

  /// Removes a typed listener.
  void removeListener<T extends Event>(EventListener<T> listener) {
    _typeListeners[T]?.removeWhere((l) => l == listener);
  }

  /// Removes a name-based listener.
  void removeNameListener(String eventName, GenericEventListener listener) {
    _nameListeners[eventName]?.remove(listener);
  }

  /// Removes a pattern listener.
  void removePatternListener(String pattern, GenericEventListener listener) {
    _patternListeners[pattern]?.remove(listener);
  }

  /// Removes a global listener.
  void removeGlobalListener(GenericEventListener listener) {
    _globalListeners.remove(listener);
  }

  /// Clears all listeners (useful for testing).
  void clearAllListeners() {
    _typeListeners.clear();
    _nameListeners.clear();
    _patternListeners.clear();
    _globalListeners.clear();
  }

  /// Dispatches an event to all registered listeners.
  ///
  /// The dispatch order is:
  /// 1. Type-specific listeners
  /// 2. Name-based listeners
  /// 3. Pattern-based listeners
  /// 4. Global listeners
  /// 5. Frontend broadcast (if enabled)
  ///
  /// Example:
  /// ```dart
  /// await dispatcher.dispatch(UserCreatedEvent(user));
  /// ```
  Future<void> dispatch(Event event, String sessionId) async {
    if (enableLogging) {
      print('[EventDispatcher] Dispatching: ${event.name}');
    }

    // 1. Notify type-specific listeners
    final typeListeners = _typeListeners[event.runtimeType] ?? [];
    for (final listener in typeListeners) {
      try {
        await listener(event);
      } catch (e, stack) {
        _handleListenerError(e, stack, event, 'type');
      }
    }

    // 2. Notify name-based listeners
    final nameListeners = _nameListeners[event.name] ?? [];
    for (final listener in nameListeners) {
      try {
        await listener(event);
      } catch (e, stack) {
        _handleListenerError(e, stack, event, 'name');
      }
    }

    // 3. Notify pattern-based listeners
    for (final entry in _patternListeners.entries) {
      if (_matchesPattern(event.name, entry.key)) {
        for (final listener in entry.value) {
          try {
            await listener(event);
          } catch (e, stack) {
            _handleListenerError(e, stack, event, 'pattern');
          }
        }
      }
    }

    // 4. Notify global listeners
    for (final listener in _globalListeners) {
      try {
        await listener(event);
      } catch (e, stack) {
        _handleListenerError(e, stack, event, 'global');
      }
    }

    // 5. Broadcast to frontend if enabled
    if (event.broadcastToFrontend) {
      _broadcastToFrontend(event);
    }
  }

  /// Dispatches multiple events in sequence.
  Future<void> dispatchAll(List<Event> events, String sessionId) async {
    for (final event in events) {
      await dispatch(event, sessionId);
    }
  }

  /// Checks if a listener exists for a specific event type.
  bool hasListeners<T extends Event>() {
    return (_typeListeners[T]?.isNotEmpty ?? false) || _globalListeners.isNotEmpty;
  }

  /// Checks if a listener exists for a specific event name.
  bool hasNameListeners(String eventName) {
    return (_nameListeners[eventName]?.isNotEmpty ?? false) || _globalListeners.isNotEmpty;
  }

  /// Creates a new SSE connection stream for frontend clients.
  ///
  /// [sessionId] - The session ID for this connection. Used to filter
  /// session-scoped events so clients only receive their own events.
  ///
  /// Returns a stream that will receive events where
  /// `broadcastToFrontend` is true. Session-scoped events are filtered
  /// to only go to the matching session.
  Stream<Event> createSSEStream({String? sessionId}) {
    final controller = StreamController<Event>.broadcast(
      onCancel: () {
        // Connection cleanup happens in _broadcastToFrontend
      },
    );
    final connection = _SSEConnection(controller: controller, sessionId: sessionId);
    _sseConnections.add(connection);

    if (enableLogging) {
      print('[EventDispatcher] SSE connection created for session: ${sessionId ?? 'anonymous'}');
    }

    return controller.stream;
  }

  /// Removes an SSE connection by its controller.
  void removeSSEConnection(StreamController<Event> controller) {
    final connection = _sseConnections.firstWhere(
      (c) => c.controller == controller,
      orElse: () => _SSEConnection(controller: controller, sessionId: null),
    );
    _sseConnections.remove(connection);
    if (!controller.isClosed) {
      controller.close();
    }
  }

  /// Gets the number of active SSE connections.
  int get sseConnectionCount => _sseConnections.length;

  /// Gets SSE connections for a specific session.
  int getSessionConnectionCount(String sessionId) {
    return _sseConnections.where((c) => c.sessionId == sessionId).length;
  }

  /// Broadcasts an event to connected frontend clients.
  ///
  /// For session-scoped events, only connections with matching sessionId
  /// will receive the event. Non-session-scoped events go to all clients.
  void _broadcastToFrontend(Event event) {
    if (_sseConnections.isEmpty) return;

    final isSessionScoped = event.sessionScoped && event.sessionId != null;

    if (enableLogging) {
      final targetDesc = isSessionScoped ? 'session ${event.sessionId}' : 'all ${_sseConnections.length} clients';
      print('[EventDispatcher] Broadcasting ${event.name} to $targetDesc');
    }

    final closedConnections = <_SSEConnection>[];

    for (final connection in _sseConnections) {
      if (connection.isClosed) {
        closedConnections.add(connection);
        continue;
      }

      // Filter by session if the event is session-scoped
      if (isSessionScoped && connection.sessionId != event.sessionId) {
        continue;
      }

      try {
        connection.controller.add(event);
      } catch (e) {
        closedConnections.add(connection);
      }
    }

    // Clean up closed connections
    for (final connection in closedConnections) {
      _sseConnections.remove(connection);
    }
  }

  /// Matches an event name against a pattern with wildcard support.
  bool _matchesPattern(String eventName, String pattern) {
    if (pattern == '*') return true;

    // Convert pattern to regex
    final regexPattern = pattern.replaceAll('.', r'\.').replaceAll('*', '.*');

    return RegExp('^$regexPattern\$').hasMatch(eventName);
  }

  /// Handles errors in event listeners without breaking the dispatch chain.
  void _handleListenerError(Object error, StackTrace stack, Event event, String listenerType) {
    print('[EventDispatcher] Error in $listenerType listener for ${event.name}: $error');
    if (enableLogging) {
      print(stack);
    }
  }

  /// Disposes of all SSE connections and clears state.
  void _dispose() {
    for (final connection in _sseConnections) {
      if (!connection.isClosed) {
        connection.controller.close();
      }
    }
    _sseConnections.clear();
    clearAllListeners();
  }
}
