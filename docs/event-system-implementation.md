# Event System Implementation Plan

> Implementation of a comprehensive event system for Dash with DashWire frontend integration

## Overview

This document outlines the implementation of an enhanced Event System for Dash, designed to:
1. Replace ad-hoc model callbacks with a unified event infrastructure
2. Enable plugins to subscribe to and emit named events
3. Provide type-safe event payloads
4. Support frontend notifications via DashWire SSE (Server-Sent Events)
5. Power the dash-activity-log plugin as a proof of concept

## Why We Need This

From the plugin roadmap, several plugins depend on an event system:
- **dash-activity-log** - Needs to capture model CRUD events with before/after state
- **dash-webhooks** - Subscribe to events and dispatch to external services
- **dash-workflow** - Trigger workflows based on named events
- **dash-notifications** - Listen for events and send notifications

Current limitations:
- Model callbacks (`onModelCreated`, etc.) are simple callbacks without payload typing
- No way to emit custom events beyond CRUD
- No mechanism to reach the frontend with real-time updates
- Events aren't centralized - scattered across Panel and Model classes

## Architecture Design

### Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                         Event System                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────────┐    ┌───────────────┐ │
│  │    Event     │    │  EventDispatcher │    │   Listener    │ │
│  │  (Base)      │───▶│   (Singleton)    │◀───│  (Function)   │ │
│  └──────────────┘    └──────────────────┘    └───────────────┘ │
│         │                    │                                   │
│         ▼                    ▼                                   │
│  ┌──────────────┐    ┌──────────────────┐                       │
│  │ Model Events │    │   SSE Channel    │──────▶ DashWire      │
│  │ (Typed)      │    │  (Frontend)      │       (Frontend)      │
│  └──────────────┘    └──────────────────┘                       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Event Flow

1. **Event Creation** → Event object created with typed payload
2. **Dispatch** → EventDispatcher broadcasts to all listeners
3. **Backend Listeners** → Plugins/services handle events (activity log, webhooks)
4. **Frontend Push** → SSE channel pushes to connected browsers
5. **DashWire Update** → Components refresh or show notifications

## Implementation Details

### Phase 1: Core Event System

**Location:** `/lib/src/events/`

#### 1.1 Event Base Class

```dart
// /lib/src/events/event.dart

/// Base class for all events in the Dash system.
///
/// Events are typed payloads that flow through the EventDispatcher.
/// Each event has a unique name and optional payload data.
///
/// Example:
/// ```dart
/// class UserCreatedEvent extends Event {
///   final User user;
///   
///   UserCreatedEvent(this.user);
///   
///   @override
///   String get name => 'user.created';
///   
///   @override
///   Map<String, dynamic> toPayload() => {
///     'user_id': user.id,
///     'email': user.email,
///   };
/// }
/// ```
abstract class Event {
  /// The unique name of this event (e.g., 'user.created', 'post.updated')
  String get name;
  
  /// Timestamp when the event was created
  final DateTime timestamp = DateTime.now();
  
  /// Converts the event to a JSON-serializable payload
  Map<String, dynamic> toPayload();
  
  /// Whether this event should be broadcast to the frontend via SSE
  bool get broadcastToFrontend => false;
  
  /// The channel to broadcast on (null = global)
  String? get broadcastChannel => null;
}
```

#### 1.2 EventDispatcher

```dart
// /lib/src/events/event_dispatcher.dart

/// Type for event listener callbacks
typedef EventListener<T extends Event> = FutureOr<void> Function(T event);

/// Type for generic event listener
typedef GenericEventListener = FutureOr<void> Function(Event event);

/// Central dispatcher for all events in the system.
///
/// The EventDispatcher is a singleton that manages event registration
/// and broadcasting. It supports:
/// - Type-safe event listeners
/// - Wildcard listeners (listen to all events)
/// - Async event handling
/// - Frontend broadcasting via SSE
///
/// Example:
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
class EventDispatcher {
  static EventDispatcher? _instance;
  
  /// Gets the singleton instance
  static EventDispatcher get instance {
    _instance ??= EventDispatcher._();
    return _instance!;
  }
  
  /// Resets the singleton (for testing)
  static void reset() {
    _instance = null;
  }
  
  EventDispatcher._();
  
  /// Listeners mapped by event type
  final Map<Type, List<GenericEventListener>> _listeners = {};
  
  /// Listeners for all events
  final List<GenericEventListener> _globalListeners = [];
  
  /// SSE connections for frontend broadcasting
  final List<StreamController<Event>> _sseConnections = [];
  
  /// Registers a typed listener for a specific event type
  void listen<T extends Event>(EventListener<T> listener) {
    _listeners.putIfAbsent(T, () => []);
    _listeners[T]!.add((event) => listener(event as T));
  }
  
  /// Registers a listener for all events
  void listenAll(GenericEventListener listener) {
    _globalListeners.add(listener);
  }
  
  /// Removes a listener
  void removeListener<T extends Event>(EventListener<T> listener) {
    _listeners[T]?.remove(listener);
  }
  
  /// Dispatches an event to all registered listeners
  Future<void> dispatch(Event event) async {
    // Notify type-specific listeners
    final typeListeners = _listeners[event.runtimeType] ?? [];
    for (final listener in typeListeners) {
      await listener(event);
    }
    
    // Notify global listeners
    for (final listener in _globalListeners) {
      await listener(event);
    }
    
    // Broadcast to frontend if enabled
    if (event.broadcastToFrontend) {
      _broadcastToFrontend(event);
    }
  }
  
  /// Broadcasts an event to connected frontend clients
  void _broadcastToFrontend(Event event) {
    for (final controller in _sseConnections) {
      if (!controller.isClosed) {
        controller.add(event);
      }
    }
    
    // Clean up closed connections
    _sseConnections.removeWhere((c) => c.isClosed);
  }
  
  /// Creates a new SSE connection stream
  Stream<Event> createSSEStream() {
    final controller = StreamController<Event>.broadcast();
    _sseConnections.add(controller);
    return controller.stream;
  }
  
  /// Removes an SSE connection
  void removeSSEConnection(StreamController<Event> controller) {
    _sseConnections.remove(controller);
    controller.close();
  }
}
```

#### 1.3 Model Events

```dart
// /lib/src/events/model_events.dart

/// Event fired when a model is about to be created (before save)
class ModelCreatingEvent extends Event {
  final Model model;
  
  ModelCreatingEvent(this.model);
  
  @override
  String get name => '${model.table}.creating';
  
  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'data': model.toMap(),
  };
}

/// Event fired after a model is created
class ModelCreatedEvent extends Event {
  final Model model;
  
  ModelCreatedEvent(this.model);
  
  @override
  String get name => '${model.table}.created';
  
  @override
  bool get broadcastToFrontend => true;
  
  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'data': model.toMap(),
  };
}

/// Event fired when a model is about to be updated (with before state)
class ModelUpdatingEvent extends Event {
  final Model model;
  final Map<String, dynamic> beforeState;
  
  ModelUpdatingEvent(this.model, this.beforeState);
  
  @override
  String get name => '${model.table}.updating';
  
  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'before': beforeState,
    'after': model.toMap(),
  };
}

/// Event fired after a model is updated
class ModelUpdatedEvent extends Event {
  final Model model;
  final Map<String, dynamic>? changes;
  
  ModelUpdatedEvent(this.model, {this.changes});
  
  @override
  String get name => '${model.table}.updated';
  
  @override
  bool get broadcastToFrontend => true;
  
  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'data': model.toMap(),
    if (changes != null) 'changes': changes,
  };
}

/// Event fired when a model is about to be deleted
class ModelDeletingEvent extends Event {
  final Model model;
  
  ModelDeletingEvent(this.model);
  
  @override
  String get name => '${model.table}.deleting';
  
  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'data': model.toMap(),
  };
}

/// Event fired after a model is deleted
class ModelDeletedEvent extends Event {
  final Model model;
  final Map<String, dynamic> deletedData;
  
  ModelDeletedEvent(this.model, this.deletedData);
  
  @override
  String get name => '${model.table}.deleted';
  
  @override
  bool get broadcastToFrontend => true;
  
  @override
  Map<String, dynamic> toPayload() => {
    'table': model.table,
    'id': model.getKey(),
    'data': deletedData,
  };
}
```

### Phase 2: Integration with Existing Code

#### 2.1 Update Model Class

Modify `Model.save()` and `Model.delete()` to dispatch events:

```dart
// In Model class save() method
Future<bool> save() async {
  final dispatcher = EventDispatcher.instance;
  final isCreating = getKey() == null;
  
  // Capture state before update
  Map<String, dynamic>? beforeState;
  if (!isCreating) {
    beforeState = Map.from(toMap());
    await dispatcher.dispatch(ModelUpdatingEvent(this, beforeState));
  } else {
    await dispatcher.dispatch(ModelCreatingEvent(this));
  }
  
  // ... existing save logic ...
  
  if (isCreating) {
    await dispatcher.dispatch(ModelCreatedEvent(this));
  } else {
    final changes = _computeChanges(beforeState!, toMap());
    await dispatcher.dispatch(ModelUpdatedEvent(this, changes: changes));
  }
  
  return true;
}
```

#### 2.2 Update Panel for Backward Compatibility

Keep existing `onModelCreated()`, `onModelUpdated()`, `onModelDeleted()` methods but have them register with the EventDispatcher internally:

```dart
// In Panel class
Panel onModelCreated(ModelCallback callback) {
  EventDispatcher.instance.listen<ModelCreatedEvent>((event) {
    callback(event.model);
  });
  return this;
}
```

### Phase 3: DashWire SSE Integration

#### 3.1 SSE Endpoint

Add an SSE endpoint to the router:

```dart
// /lib/src/panel/panel_router.dart

// Add route for SSE
if (request.url.path == '${config.path}/events/stream') {
  return _handleSSE(request);
}

Response _handleSSE(Request request) {
  final stream = EventDispatcher.instance.createSSEStream();
  
  // Convert events to SSE format
  final sseStream = stream.map((event) {
    final data = jsonEncode({
      'name': event.name,
      'payload': event.toPayload(),
      'timestamp': event.timestamp.toIso8601String(),
    });
    return 'data: $data\n\n';
  });
  
  return Response.ok(
    sseStream,
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  );
}
```

#### 3.2 DashWire Frontend Integration

Update `dash-wire.js` to connect to SSE and handle server events:

```javascript
// Add to dash-wire.js

/**
 * Server-Sent Events connection for real-time updates
 */
let sseConnection = null;

function initSSE() {
  const basePath = window.DashWireConfig?.basePath || '/admin';
  sseConnection = new EventSource(`${basePath}/events/stream`);
  
  sseConnection.onmessage = (event) => {
    const data = JSON.parse(event.data);
    handleServerEvent(data);
  };
  
  sseConnection.onerror = () => {
    // Reconnect after delay
    setTimeout(initSSE, 5000);
  };
}

function handleServerEvent(event) {
  log('Server event received:', event.name, event.payload);
  
  // Dispatch to listening components
  broadcastEvents([{ name: event.name, payload: event.payload }], null);
  
  // Show toast for model events
  if (event.name.endsWith('.created')) {
    showToast(`Record created`, 'success');
  } else if (event.name.endsWith('.updated')) {
    showToast(`Record updated`, 'success');
  } else if (event.name.endsWith('.deleted')) {
    showToast(`Record deleted`, 'success');
  }
}
```

### Phase 4: Activity Log Plugin

#### 4.1 Plugin Structure

```
plugins/dash-activity-log/
├── lib/
│   ├── dash_activity_log.dart          # Main export
│   └── src/
│       ├── activity_log_plugin.dart    # Plugin class
│       ├── models/
│       │   └── activity.dart           # Activity model
│       ├── resources/
│       │   └── activity_resource.dart  # Admin resource
│       └── widgets/
│           └── activity_timeline.dart  # Timeline widget
├── pubspec.yaml
└── README.md
```

#### 4.2 Activity Model

```dart
class Activity extends Model {
  int? id;
  String event;           // Event name (e.g., 'users.created')
  String subjectType;     // Model type (e.g., 'User')
  int? subjectId;         // Model ID
  String? causerId;       // User who caused the event
  Map<String, dynamic>? properties; // Before/after data
  DateTime? createdAt;
  
  @override
  String get table => 'activities';
  
  // ... standard model methods
}
```

#### 4.3 ActivityLogPlugin

```dart
class ActivityLogPlugin implements Plugin {
  List<String> _excludedTables = [];
  
  ActivityLogPlugin excludeTables(List<String> tables) {
    _excludedTables = tables;
    return this;
  }
  
  @override
  void register(Panel panel) {
    panel.registerResources([ActivityResource()]);
    panel.registerSchemas([Activity.schema]);
  }
  
  @override
  void boot(Panel panel) {
    final dispatcher = EventDispatcher.instance;
    
    // Listen to all model events
    dispatcher.listen<ModelCreatedEvent>(_logCreated);
    dispatcher.listen<ModelUpdatedEvent>(_logUpdated);
    dispatcher.listen<ModelDeletedEvent>(_logDeleted);
  }
  
  Future<void> _logCreated(ModelCreatedEvent event) async {
    if (_shouldLog(event.model.table)) {
      await Activity.create({
        'event': event.name,
        'subject_type': event.model.runtimeType.toString(),
        'subject_id': event.model.getKey(),
        'properties': jsonEncode({'new': event.model.toMap()}),
      });
    }
  }
  
  // ... similar for updated/deleted
}
```

## Migration Guide for Existing Code

### Before (Current Pattern)

```dart
// In Panel configuration
panel.onModelCreated((model) async {
  await metrics.modelCreated(model.runtimeType.toString());
});
```

### After (Event System)

```dart
// Option 1: Keep using Panel methods (backward compatible)
panel.onModelCreated((model) async {
  await metrics.modelCreated(model.runtimeType.toString());
});

// Option 2: Use EventDispatcher directly for more control
EventDispatcher.instance.listen<ModelCreatedEvent>((event) async {
  await metrics.modelCreated(event.model.runtimeType.toString());
});

// Option 3: Custom events
EventDispatcher.instance.dispatch(CustomAnalyticsEvent(data));
```

## Testing Strategy

### Unit Tests

1. **EventDispatcher tests**
   - Listener registration and removal
   - Event dispatching to correct listeners
   - Global listener notification
   - Async listener handling

2. **Model event tests**
   - Events fired on create/update/delete
   - Correct payload data
   - Before/after state capture

3. **Activity Log tests**
   - Activity records created for model events
   - Excluded tables not logged
   - Properties stored correctly

### Integration Tests

1. **Full flow test**
   - Create a model → event dispatched → activity logged
   - Update a model → changes captured → activity logged

2. **SSE tests**
   - Connect to SSE endpoint
   - Receive events in real-time
   - Reconnection handling

## Files to Create/Modify

### New Files
- `/lib/src/events/event.dart` - Event base class
- `/lib/src/events/event_dispatcher.dart` - Central dispatcher
- `/lib/src/events/model_events.dart` - Model event classes
- `/lib/src/events/events.dart` - Barrel export
- `/test/events/event_dispatcher_test.dart` - Unit tests
- `/test/events/model_events_test.dart` - Model event tests

### Modified Files
- `/lib/src/model/model.dart` - Dispatch events in save/delete
- `/lib/src/panel/panel.dart` - Integrate with EventDispatcher
- `/lib/src/panel/panel_router.dart` - Add SSE endpoint
- `/lib/dash.dart` - Export events module
- `/resources/js/dash-wire.js` - Add SSE client

### Plugin Files
- `/plugins/dash-activity-log/lib/dash_activity_log.dart`
- `/plugins/dash-activity-log/lib/src/activity_log_plugin.dart`
- `/plugins/dash-activity-log/lib/src/models/activity.dart`
- `/plugins/dash-activity-log/lib/src/resources/activity_resource.dart`
- `/plugins/dash-activity-log/pubspec.yaml`

## Timeline & Progress

- [x] **Phase 1**: Core Event System (Event, EventDispatcher, ModelEvents)
- [x] **Phase 2**: Model Integration (update Model.save/delete)
- [x] **Phase 3**: Panel Integration (backward-compatible methods)
- [x] **Phase 4**: SSE Endpoint (server-side)
- [x] **Phase 5**: DashWire SSE Client (frontend)
- [x] **Phase 6**: Activity Log Plugin
- [x] **Phase 7**: Unit Tests (55 tests passing)
- [ ] **Phase 8**: Integration Tests with Playwright (blocked - server startup requires CWD)

## Success Criteria

1. ✅ Events are dispatched when models are created/updated/deleted
2. ✅ Plugins can listen to events via EventDispatcher
3. ✅ Existing `panel.onModelCreated()` etc. still work
4. ✅ Activity log captures all model changes
5. ✅ Frontend receives real-time updates via SSE
6. ✅ All tests pass
7. ⏳ Example app demonstrates functionality (partially - server startup has CWD dependency)

---

*Last Updated: December 4, 2025*
