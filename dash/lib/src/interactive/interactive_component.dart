import 'dart:async';

import 'package:dash/src/interactive/component_state.dart';
import 'package:dash/src/plugin/asset.dart';
import 'package:jaspr/jaspr.dart';

/// Represents an event dispatched by an interactive component.
///
/// Events are broadcast to other components that have registered listeners.
class WireEvent {
  /// The event name (e.g., 'page-changed', 'search-updated').
  final String name;

  /// Optional payload data for the event.
  final Map<String, dynamic> payload;

  const WireEvent(this.name, [this.payload = const {}]);

  Map<String, dynamic> toJson() => {'name': name, 'payload': payload};
}

/// Base class for interactive (Livewire-like) components.
///
/// An [InteractiveComponent] combines server-side rendering with client-side
/// interactivity. The component state lives on the server, and the client
/// communicates via wire: directives to trigger actions and update the UI.
///
/// ## Lifecycle
/// 1. **mount()** - Called once when the component is first rendered
/// 2. **render()** - Called to build the component's UI
/// 3. **updated(property)** - Called after a property is changed via wire:model
///
/// ## Wire Directives (client-side)
/// - `wire:click="methodName"` - Call a method on click
/// - `wire:model="property"` - Two-way bind to a property
/// - `wire:submit="methodName"` - Call a method on form submit
/// - `wire:keydown.enter="methodName"` - Call on keydown
/// - `wire:loading` - Show element while loading
///
/// ## Example
/// ```dart
/// class Counter extends InteractiveComponent {
///   int count = 0;
///
///   @override
///   String get componentId => 'counter';
///
///   void increment() {
///     count++;
///   }
///
///   void decrement() {
///     count--;
///   }
///
///   @override
///   Component render() {
///     return div([
///       span([text('Count: $count')]),
///       button(
///         attributes: {'wire:click': 'increment'},
///         [text('+')],
///       ),
///       button(
///         attributes: {'wire:click': 'decrement'},
///         [text('-')],
///       ),
///     ]);
///   }
/// }
/// ```
abstract class InteractiveComponent with AssetProvider {
  /// Unique identifier for this component instance.
  ///
  /// Used to route wire: requests back to this component.
  /// Should be unique within the page.
  String get componentId;

  /// Optional component name for debugging.
  String get componentName => runtimeType.toString();

  // ============================================================
  // Lifecycle Methods
  // ============================================================

  /// Called once when the component is first created.
  ///
  /// Use this to initialize state, fetch data, or set up listeners.
  /// This is the Dart equivalent of Livewire's mount() method.
  FutureOr<void> mount() {}

  /// Called after a property is updated via wire:model or action.
  ///
  /// [property] is the name of the property that changed.
  /// Use this to perform side effects when state changes.
  FutureOr<void> updated(String property) {}

  /// Called before the component is rendered.
  ///
  /// Use for any pre-render computations or validation.
  FutureOr<void> beforeRender() {}

  // ============================================================
  // Events (Livewire-style dispatch/listen)
  // ============================================================

  /// Events dispatched by this component during the current request.
  ///
  /// These are sent to the client and broadcast to other components.
  final List<WireEvent> _dispatchedEvents = [];

  /// Dispatches an event to other components.
  ///
  /// Events can be listened to by other components using [getListeners].
  /// The event will be broadcast client-side after this component re-renders.
  ///
  /// Example:
  /// ```dart
  /// void goToPage(int page) {
  ///   currentPage = page;
  ///   dispatch('page-changed', {'page': page});
  /// }
  /// ```
  void dispatch(String event, [Map<String, dynamic>? payload]) {
    _dispatchedEvents.add(WireEvent(event, payload ?? {}));
  }

  /// Returns the list of events dispatched during this request.
  List<WireEvent> getDispatchedEvents() => List.unmodifiable(_dispatchedEvents);

  /// Clears dispatched events (called after sending response).
  void clearDispatchedEvents() => _dispatchedEvents.clear();

  /// Returns a map of event names to handler methods.
  ///
  /// Override to declare which events this component listens to.
  /// When another component dispatches an event, all listeners
  /// will be refreshed automatically.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, Function(Map<String, dynamic>)> getListeners() => {
  ///   'page-changed': (data) => onPageChanged(data['page'] as int),
  ///   'search-updated': (data) => onSearchUpdated(data['query'] as String),
  /// };
  /// ```
  Map<String, Function(Map<String, dynamic>)> getListeners() => {};

  /// Handles an incoming event from another component.
  ///
  /// Returns true if the event was handled by a listener.
  FutureOr<bool> handleEvent(String event, Map<String, dynamic> payload) async {
    final listeners = getListeners();
    final handler = listeners[event];

    if (handler == null) {
      return false;
    }

    final result = handler(payload);
    if (result is Future) {
      await result;
    }

    return true;
  }

  // ============================================================
  // Rendering
  // ============================================================

  /// Builds the component's UI.
  ///
  /// This is called on initial render and after any action/update.
  /// Returns a Jaspr [Component] tree.
  Component render();

  /// Builds the complete component with wire wrapper.
  ///
  /// This wraps your [render()] output with the necessary
  /// data attributes for the wire system to function.
  Component build() {
    final listeners = getListeners();
    final listenerNames = listeners.keys.toList();

    return div(
      id: 'wire-$componentId',
      attributes: {
        'wire:id': componentId,
        'wire:name': componentName,
        'wire:initial-data': _serializeState(),
        if (listenerNames.isNotEmpty) 'wire:listeners': listenerNames.join(','),
      },
      [render()],
    );
  }

  // ============================================================
  // State Management
  // ============================================================

  /// Returns a map of all public properties and their values.
  ///
  /// Override to define which properties should be synchronized
  /// between server and client.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, dynamic> getState() => {
  ///   'count': count,
  ///   'name': name,
  /// };
  /// ```
  Map<String, dynamic> getState();

  /// Sets a property value from the state map.
  ///
  /// Called when restoring state from a client request.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void setState(Map<String, dynamic> state) {
  ///   count = state['count'] ?? 0;
  ///   name = state['name'] ?? '';
  /// }
  /// ```
  void setState(Map<String, dynamic> state);

  /// Serializes the component state to JSON for transmission.
  String _serializeState() {
    final state = getState();
    return ComponentState.serialize(componentId, state);
  }

  /// Deserializes and restores state from a client request.
  void restoreState(String serializedState) {
    final state = ComponentState.deserialize(serializedState);
    if (state != null) {
      setState(state);
    }
  }

  // ============================================================
  // Actions
  // ============================================================

  /// Dispatches an action (method call) on this component.
  ///
  /// [action] is the method name to call.
  /// [params] are optional parameters to pass to the method.
  ///
  /// Returns true if the action was handled.
  FutureOr<bool> dispatchAction(String action, [List<dynamic>? params]) async {
    // Subclasses implement action handling via getActions()
    final actions = getActions();
    final handler = actions[action];

    if (handler == null) {
      return false;
    }

    // Call the action handler
    final result = handler(params ?? []);
    if (result is Future) {
      await result;
    }

    return true;
  }

  /// Returns a map of action names to handler functions.
  ///
  /// Override to expose methods that can be called via wire:click etc.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Map<String, Function> getActions() => {
  ///   'increment': (_) => increment(),
  ///   'decrement': (_) => decrement(),
  ///   'setCount': (params) => setCount(params[0] as int),
  /// };
  /// ```
  Map<String, Function(List<dynamic>)> getActions();

  /// Updates a single property value.
  ///
  /// Called by wire:model bindings. Triggers [updated()] callback.
  FutureOr<void> updateProperty(String property, dynamic value) async {
    final state = getState();
    state[property] = value;
    setState(state);
    await updated(property);
  }

  // ============================================================
  // Assets
  // ============================================================

  /// Returns the list of CSS/JS assets required by this component.
  ///
  /// Override to declare external dependencies.
  @override
  List<Asset> get requiredAssets => [];

  // ============================================================
  // Visibility
  // ============================================================

  /// Determines whether this component should be rendered.
  ///
  /// Override to implement authorization or conditional visibility.
  bool canView() => true;
}

/// Mixin that provides a simpler way to define interactive components
/// with automatic state and action registration.
mixin SimpleInteractiveComponent on InteractiveComponent {
  final Map<String, dynamic> _state = {};
  final Map<String, Function(List<dynamic>)> _actions = {};

  /// Registers a reactive property with initial value.
  T property<T>(String name, T initialValue) {
    _state.putIfAbsent(name, () => initialValue);
    return _state[name] as T;
  }

  /// Sets a property value.
  void set(String name, dynamic value) {
    _state[name] = value;
  }

  /// Gets a property value.
  T get<T>(String name) => _state[name] as T;

  /// Registers an action handler.
  void action(String name, Function handler) {
    _actions[name] = (params) => Function.apply(handler, params);
  }

  @override
  Map<String, dynamic> getState() => Map.from(_state);

  @override
  void setState(Map<String, dynamic> state) {
    _state.addAll(state);
  }

  @override
  Map<String, Function(List<dynamic>)> getActions() => Map.from(_actions);
}
