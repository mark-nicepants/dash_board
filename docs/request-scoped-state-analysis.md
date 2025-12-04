# Request-Scoped State in Dash: Analysis & Recommendations

> Critical analysis of the current architecture for handling request-scoped state, session management, and the event system, with recommendations for a scalable solution.

## Executive Summary

**Current Status: 🔴 BROKEN for concurrent requests**

The current `RequestSession` implementation uses a **singleton pattern** with GetIt, which means all concurrent requests share the same instance. When user A and user B make requests simultaneously:

1. Request A sets `RequestSession._sessionId = "session_a"`
2. Request B sets `RequestSession._sessionId = "session_b"` (overwrites!)
3. Request A's model save sees `session_b` instead of `session_a`

This is a **race condition** that will cause:
- Events being attributed to the wrong session
- SSE messages going to wrong users
- Security vulnerabilities (user A sees user B's events)

---

## Current Architecture Analysis

### 1. RequestSession: The Singleton Problem

```dart
// lib/src/auth/request_session.dart

class RequestSession {
  String? _sessionId;  // ⚠️ SHARED across ALL requests!
  Model? _user;        // ⚠️ SHARED across ALL requests!
  
  RequestSession._();
  
  // Registers as a SINGLETON - only ONE instance ever exists
  static void register() {
    if (!inject.isRegistered<RequestSession>()) {
      inject.registerLazySingleton<RequestSession>(RequestSession._);
    }
  }
  
  static RequestSession instance() => inject<RequestSession>();
}
```

**Problem**: With 300 concurrent connections, all 300 share the same `_sessionId` and `_user` fields.

### 2. Auth Middleware: Where the Race Begins

```dart
// lib/src/auth/auth_middleware.dart

Middleware authMiddleware(...) {
  return (Handler innerHandler) {
    return (Request request) async {
      // ...
      final user = await authService.getUser(sessionId);
      
      // ⚠️ RACE CONDITION: This overwrites the singleton!
      RequestSession.instance().initFromRequest(request, user: user);
      
      return innerHandler(request);  // Other requests may overwrite before we finish
    };
  };
}
```

### 3. Event System: Inherits the Problem

The proposed fix to add `sessionId` to events via `_dispatchWithSession()`:

```dart
Future<void> _dispatchWithSession(Event event) async {
  try {
    // ⚠️ This reads from the broken singleton!
    event.sessionId = RequestSession.instance().sessionId;
  } catch (_) {}
  await EventDispatcher.instance.dispatch(event);
}
```

This doesn't fix the problem - it just inherits the race condition from `RequestSession`.

### 4. Service Locator (GetIt): Not Designed for Request Scope

GetIt provides:
- ✅ `registerSingleton` - One instance for entire app
- ✅ `registerFactory` - New instance per call
- ✅ `registerLazySingleton` - One instance, created lazily
- ❌ **No request-scoped registration** - GetIt has no concept of "per-request" scope

---

## Dart Concurrency Model

### Single-Threaded But Concurrent

Dart runs in a **single isolate** by default (single thread), but handles multiple concurrent requests via the event loop:

```
Request A arrives  →  [parse]  →  [await DB]  →  [process]  →  [respond]
                          ↓           ↓            ↓
Request B arrives  ────────→  [parse]  →  [await DB]  →  [respond]
```

When Request A hits an `await`, Request B can run. They **interleave** but don't run in parallel.

### Why Singletons Break

```dart
// Timeline with interleaved requests:

t1: Request A: RequestSession._sessionId = "A"
t2: Request A: await model.save()  // Yields to event loop
t3: Request B: RequestSession._sessionId = "B"  // OVERWRITES!
t4: Request B: await model.save()  // Yields
t5: Request A: resumes, sees sessionId = "B"  // WRONG!
```

---

## Available Solutions

### Option 1: Shelf Request Context (Recommended)

Shelf's `Request` class has a `context` map and `change()` method for passing data through the middleware chain:

```dart
// Middleware stores session in request context
Middleware authMiddleware(...) {
  return (Handler innerHandler) {
    return (Request request) async {
      final sessionId = parseSessionId(request);
      final user = await authService.getUser(sessionId);
      
      // Attach to THIS request's context - isolated from other requests
      final enrichedRequest = request.change(context: {
        'dash.sessionId': sessionId,
        'dash.user': user,
      });
      
      return innerHandler(enrichedRequest);
    };
  };
}
```

**Challenge**: The `Request` object needs to flow through to Model operations, but currently models are called without request context:

```dart
// In Resource.createRecord():
await instance.save();  // Model.save() has no access to Request
```

### Option 2: Zone-Based Context

Dart Zones can carry context data through async operations:

```dart
// Define zone keys
final sessionIdKey = #dash.sessionId;

// In middleware
Middleware authMiddleware(...) {
  return (Handler innerHandler) {
    return (Request request) async {
      final sessionId = parseSessionId(request);
      
      // Run handler within a zone that carries the session
      return runZoned(
        () => innerHandler(request),
        zoneValues: {
          sessionIdKey: sessionId,
        },
      );
    };
  };
}

// Anywhere in code (including Model.save)
String? get currentSessionId => Zone.current[sessionIdKey] as String?;
```

**Pros**:
- Works automatically through all async calls
- No need to pass Request object everywhere
- Minimal code changes

**Cons**:
- Zones are implicit (harder to debug)
- Zone values don't survive across isolate boundaries (if we ever add them)
- Some frameworks/libraries can break zone inheritance

### Option 3: Async Local Storage Pattern

Similar to zones but more explicit, using a purpose-built class:

```dart
class RequestContext {
  static final _storage = <int, _RequestData>{};
  static int _counter = 0;
  
  final int _id;
  
  RequestContext._() : _id = ++_counter;
  
  static RequestContext create() => RequestContext._();
  
  void set(String key, dynamic value) {
    _storage.putIfAbsent(_id, () => _RequestData())[key] = value;
  }
  
  T? get<T>(String key) => _storage[_id]?[key] as T?;
  
  void dispose() => _storage.remove(_id);
}
```

**Cons**: Still needs to pass context through call chain or use zones.

### Option 4: Pass Session Explicitly (Simplest but Invasive)

Make session ID a parameter to model operations:

```dart
// Resource
Future<T> createRecord(Map<String, dynamic> data, {String? sessionId}) async {
  final instance = newModelInstance();
  _applyDataToModel(instance, data);
  await instance.save(sessionId: sessionId);
  return instance;
}

// Model
Future<bool> save({String? sessionId}) async {
  // ...
  final event = ModelCreatedEvent(this);
  event.sessionId = sessionId;
  await dispatcher.dispatch(event);
}
```

**Pros**: Explicit, no magic
**Cons**: Invasive changes throughout codebase, verbose

---

## Recommended Solution: Zone-Based Context

### Why Zones?

1. **Minimal changes** - Only middleware and event dispatch need modification
2. **Automatic propagation** - Works through all async calls automatically
3. **No API changes** - Model.save() signature stays the same
4. **Battle-tested** - Used by Flutter, Angular Dart, and other frameworks

### Implementation Plan

#### Phase 1: Create Request Context Wrapper

```dart
// lib/src/context/request_context.dart

/// Provides request-scoped context data via Dart zones.
/// 
/// Usage:
/// ```dart
/// // In middleware - wrap handler in zone
/// return RequestContext.run(
///   sessionId: sessionId,
///   user: user,
///   () => innerHandler(request),
/// );
/// 
/// // Anywhere in request - read context
/// final sessionId = RequestContext.sessionId;
/// final user = RequestContext.user;
/// ```
class RequestContext {
  static const _sessionIdKey = #dash.requestContext.sessionId;
  static const _userKey = #dash.requestContext.user;
  static const _requestIdKey = #dash.requestContext.requestId;
  
  /// Runs [callback] within a zone that carries request context.
  static Future<T> run<T>({
    String? sessionId,
    Model? user,
    required Future<T> Function() callback,
  }) {
    final requestId = _generateRequestId();
    
    return runZoned(
      callback,
      zoneValues: {
        _sessionIdKey: sessionId,
        _userKey: user,
        _requestIdKey: requestId,
      },
    );
  }
  
  /// Gets the current session ID, or null if not in a request context.
  static String? get sessionId => Zone.current[_sessionIdKey] as String?;
  
  /// Gets the current user, or null if not authenticated.
  static Model? get user => Zone.current[_userKey] as Model?;
  
  /// Gets the current request ID for tracing.
  static String? get requestId => Zone.current[_requestIdKey] as String?;
  
  /// Whether we're currently within a request context.
  static bool get isInRequestContext => Zone.current[_requestIdKey] != null;
  
  static String _generateRequestId() {
    return '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(9999)}';
  }
  
  static final _random = Random();
}
```

#### Phase 2: Update Auth Middleware

```dart
// lib/src/auth/auth_middleware.dart

Middleware authMiddleware(AuthService<Model> authService, {required String basePath}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.url.path;
      
      // Skip auth for login page
      if (path.startsWith('$baseSegment/login')) {
        return innerHandler(request);
      }
      
      final sessionId = RequestSession.parseSessionId(request);
      
      if (!await authService.isAuthenticated(sessionId)) {
        return Response.found('$basePath/login');
      }
      
      final user = await authService.getUser(sessionId);
      
      // Run the rest of the request within a zone
      return RequestContext.run(
        sessionId: sessionId,
        user: user,
        () => innerHandler(request),
      );
    };
  };
}
```

#### Phase 3: Update Event Dispatch in Model

```dart
// lib/src/model/model.dart

/// Dispatches an event with the current request's session ID attached.
Future<void> _dispatchWithSession(Event event) async {
  // Read from zone - automatically gets correct session for this request
  event.sessionId = RequestContext.sessionId;
  await EventDispatcher.instance.dispatch(event);
}
```

#### Phase 4: Deprecate RequestSession Singleton

Mark `RequestSession` as deprecated and migrate usages:

```dart
@Deprecated('Use RequestContext instead. Will be removed in v2.0')
class RequestSession {
  // Keep for backwards compatibility during migration
  
  static String? get sessionId => RequestContext.sessionId;
  static Model? get user => RequestContext.user;
}
```

### Migration Path

1. **Create RequestContext** - New zone-based context
2. **Update middleware** - Wrap handlers in RequestContext.run()
3. **Update Model** - Use RequestContext.sessionId in dispatch
4. **Update SSE endpoint** - Already uses session from request
5. **Deprecate RequestSession** - Mark as deprecated
6. **Test with concurrent requests** - Verify isolation
7. **Remove RequestSession** - In future major version

---

## Testing Strategy

### Concurrent Request Test

```dart
void main() {
  test('sessions are isolated between concurrent requests', () async {
    final results = <String?>[];
    
    // Simulate 100 concurrent requests with different sessions
    await Future.wait(List.generate(100, (i) async {
      await RequestContext.run(
        sessionId: 'session_$i',
        () async {
          await Future.delayed(Duration(milliseconds: Random().nextInt(10)));
          results.add(RequestContext.sessionId);
        },
      );
    }));
    
    // Verify each request saw its own session
    expect(results, containsAll(List.generate(100, (i) => 'session_$i')));
  });
}
```

---

## Scalability Considerations

### Will This Scale to 300+ Concurrent Connections?

**Yes.** The zone-based approach:

1. **No shared mutable state** - Each zone has its own values
2. **O(1) context lookup** - Zone values are stored in a map
3. **Minimal memory overhead** - Zone values are small (sessionId, user reference)
4. **Automatic cleanup** - Zone values are garbage collected when zone completes

### SSE Connection Scalability

Each SSE connection:
- Holds a StreamController (~64 bytes)
- Stores session ID (string reference)
- Listed in EventDispatcher._sseConnections

For 300 connections: ~50KB memory overhead (negligible)

### Event Broadcasting Scalability

For session-scoped events (most events):
- O(n) to filter connections by session, but n is small per session
- Typically 1-3 tabs per user

For global events:
- O(n) where n = total connections
- Acceptable for rare global broadcasts

---

## Conclusion

### Immediate Actions Required

1. **Do NOT use the current RequestSession singleton for session ID in events** - It's broken
2. **Implement RequestContext with zones** - Provides correct isolation
3. **Fix the SSE URL issue** separately (already identified: `/admin/events/stream` vs `/admin/wire/events/stream`)

### Long-term

1. Remove RequestSession singleton pattern
2. Consider request-scoped dependency injection if needed (look at `get_it` scopes or `riverpod`)
3. Document the zone-based pattern for plugin developers

---

## Files to Modify

| File | Change |
|------|--------|
| `lib/src/context/request_context.dart` | **NEW** - Zone-based context |
| `lib/src/auth/auth_middleware.dart` | Wrap handler in RequestContext.run() |
| `lib/src/model/model.dart` | Use RequestContext.sessionId in dispatch |
| `lib/src/auth/request_session.dart` | Deprecate, delegate to RequestContext |
| `lib/dash.dart` | Export RequestContext |
| `test/context/request_context_test.dart` | **NEW** - Concurrency tests |

---

## References

- [Dart Zones](https://dart.dev/articles/libraries/zones)
- [Shelf Request.context](https://pub.dev/documentation/shelf/latest/shelf/Request/context.html)
- [GetIt Scopes](https://pub.dev/packages/get_it#scopes) (for future consideration)
- [Flask's request context](https://flask.palletsprojects.com/en/2.0.x/reqcontext/) (similar pattern in Python)

---

*Document created: December 4, 2025*
*Status: Analysis complete, awaiting implementation decision*
