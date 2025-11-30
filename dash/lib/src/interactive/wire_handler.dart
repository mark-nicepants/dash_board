import 'dart:convert';

import 'package:dash/src/interactive/component_registry.dart';
import 'package:dash/src/interactive/interactive_component.dart';
import 'package:jaspr/server.dart';

/// Handles wire requests for interactive components.
///
/// Wire requests allow client-side JavaScript to trigger server-side
/// component actions and receive updated HTML.
///
/// Request format:
/// ```json
/// {
///   "name": "ComponentName",
///   "state": "base64encodedState.signature",
///   "action": "methodName",        // optional
///   "params": ["arg1", "arg2"],    // optional
///   "models": {"prop": "value"},   // optional
///   "event": {"name": "...", "payload": {...}}  // optional, for event handling
/// }
/// ```
///
/// Response format:
/// ```json
/// {
///   "html": "<div wire:id=...>...</div>",
///   "events": [{"name": "page-changed", "payload": {"page": 2}}]
/// }
/// ```
class WireHandler {
  /// The base path for wire requests (e.g., '/admin').
  final String basePath;

  WireHandler({required this.basePath});

  /// The full wire endpoint path (e.g., 'admin/wire/').
  String get _wirePathPrefix {
    final base = basePath.replaceFirst('/', '');
    return '$base/wire/';
  }

  /// Checks if a request is a wire request.
  bool isWireRequest(Request request) {
    final path = request.url.path;
    // Check if path matches {basePath}/wire/{componentId}
    return path.startsWith(_wirePathPrefix) || (request.headers['x-wire-request'] == 'true' && path.contains('/wire/'));
  }

  /// Handles a wire request.
  ///
  /// Expected URL format: /admin/wire/{componentId}
  /// The component ID is used to look up the component factory.
  Future<Response> handle(Request request) async {
    if (request.method != 'POST') {
      return Response(405, body: 'Method not allowed');
    }

    try {
      // Parse the request body
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      // Extract component info
      final componentName = data['name'] as String?;
      final serializedState = data['state'] as String?;
      final action = data['action'] as String?;
      final params = (data['params'] as List?)?.cast<dynamic>();
      final models = data['models'] as Map<String, dynamic>?;
      final incomingEvent = data['event'] as Map<String, dynamic>?;

      if (componentName == null || serializedState == null) {
        return Response.badRequest(body: 'Missing component name or state');
      }

      // Handle the wire request through the registry
      final component = await ComponentRegistry.handleWireRequest(
        typeName: componentName,
        serializedState: serializedState,
        action: action,
        params: params,
        modelUpdates: models,
        incomingEvent: incomingEvent,
      );

      if (component == null) {
        return Response.notFound('Component not found: $componentName');
      }

      // Render the updated component
      final html = await _renderComponent(component);

      // Get any events dispatched by this component
      final dispatchedEvents = component.getDispatchedEvents();
      component.clearDispatchedEvents();

      // Return JSON response with HTML and events
      final responseData = {'html': html, 'events': dispatchedEvents.map((e) => e.toJson()).toList()};

      return Response.ok(
        jsonEncode(responseData),
        headers: {'content-type': 'application/json; charset=utf-8', 'x-wire-response': 'true'},
      );
    } catch (e, stack) {
      print('WireHandler error: $e');
      print(stack);
      return Response.internalServerError(body: 'Wire request failed: $e');
    }
  }

  /// Renders an interactive component to HTML.
  Future<String> _renderComponent(InteractiveComponent component) async {
    // Run before render lifecycle
    await component.beforeRender();

    // Build the component (this includes the wire wrapper)
    final componentTree = component.build();

    // Render using Jaspr
    final rendered = await renderComponent(componentTree);

    return rendered.body;
  }
}

/// Extension on Request to extract wire request path info.
extension WireRequestExtension on Request {
  /// Extracts the component ID from the wire request path.
  ///
  /// Path format: /admin/wire/{componentId}
  String? get wireComponentId {
    final path = url.path;
    final wireIndex = path.indexOf('/wire/');
    if (wireIndex == -1) return null;

    final afterWire = path.substring(wireIndex + 6); // Length of '/wire/'
    final slashIndex = afterWire.indexOf('/');

    return slashIndex == -1 ? afterWire : afterWire.substring(0, slashIndex);
  }
}
