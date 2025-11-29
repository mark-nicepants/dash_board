import 'dart:async';

import 'package:dash/src/interactive/interactive_component.dart';

/// Factory function type for creating interactive components.
typedef InteractiveComponentFactory = InteractiveComponent Function();

/// Registry for managing interactive component instances and factories.
///
/// The registry serves two purposes:
/// 1. **Factory Registration** - Register component types for on-demand creation
/// 2. **Instance Management** - Track active component instances for action dispatch
///
/// Example:
/// ```dart
/// // Register a component factory
/// ComponentRegistry.registerFactory('counter', () => Counter());
///
/// // Create and track an instance
/// final counter = ComponentRegistry.createInstance('counter', 'counter-1');
///
/// // Later, dispatch an action to the instance
/// await ComponentRegistry.dispatchAction('counter-1', 'increment', []);
/// ```
class ComponentRegistry {
  /// Singleton instance.
  static final ComponentRegistry _instance = ComponentRegistry._();

  /// Private constructor.
  ComponentRegistry._();

  /// Gets the singleton instance.
  static ComponentRegistry get instance => _instance;

  /// Registered component factories by type name.
  final Map<String, InteractiveComponentFactory> _factories = {};

  /// Active component instances by instance ID.
  final Map<String, InteractiveComponent> _instances = {};

  // ============================================================
  // Factory Registration
  // ============================================================

  /// Registers a factory for creating components of the given type.
  ///
  /// [typeName] is a unique identifier for this component type.
  /// [factory] is a function that creates new instances.
  ///
  /// Example:
  /// ```dart
  /// ComponentRegistry.registerFactory('counter', () => Counter());
  /// ComponentRegistry.registerFactory('search-box', () => SearchBox());
  /// ```
  static void registerFactory(String typeName, InteractiveComponentFactory factory) {
    _instance._factories[typeName] = factory;
  }

  /// Checks if a factory is registered for the given type.
  static bool hasFactory(String typeName) {
    return _instance._factories.containsKey(typeName);
  }

  /// Gets all registered factory type names.
  static List<String> get registeredTypes => _instance._factories.keys.toList();

  // ============================================================
  // Instance Management
  // ============================================================

  /// Creates a new component instance from a registered factory.
  ///
  /// [typeName] is the registered factory name.
  /// [instanceId] is a unique ID for this specific instance.
  ///
  /// Returns the created component, or null if no factory is registered.
  static Future<InteractiveComponent?> createInstance(String typeName, {String? instanceId}) async {
    final factory = _instance._factories[typeName];
    if (factory == null) {
      print('ComponentRegistry: No factory registered for "$typeName"');
      return null;
    }

    final component = factory();
    final id = instanceId ?? component.componentId;

    // Run mount lifecycle
    await component.mount();

    // Track the instance
    _instance._instances[id] = component;

    return component;
  }

  /// Registers an existing component instance.
  ///
  /// Use this when you create components manually instead of via factory.
  static void registerInstance(InteractiveComponent component) {
    _instance._instances[component.componentId] = component;
  }

  /// Gets a component instance by ID.
  static InteractiveComponent? getInstance(String instanceId) {
    return _instance._instances[instanceId];
  }

  /// Removes a component instance from the registry.
  static void removeInstance(String instanceId) {
    _instance._instances.remove(instanceId);
  }

  /// Gets all active instance IDs.
  static List<String> get activeInstanceIds => _instance._instances.keys.toList();

  /// Clears all instances (useful for testing).
  static void clearInstances() {
    _instance._instances.clear();
  }

  /// Clears all factories and instances (useful for testing).
  static void clearAll() {
    _instance._factories.clear();
    _instance._instances.clear();
  }

  // ============================================================
  // Action Dispatch
  // ============================================================

  /// Dispatches an action to a component instance.
  ///
  /// [instanceId] is the target component's instance ID.
  /// [action] is the method name to call.
  /// [params] are optional parameters for the action.
  ///
  /// Returns the updated component, or null if the instance wasn't found.
  static Future<InteractiveComponent?> dispatchAction(String instanceId, String action, [List<dynamic>? params]) async {
    final component = _instance._instances[instanceId];
    if (component == null) {
      print('ComponentRegistry: No instance found for "$instanceId"');
      return null;
    }

    final handled = await component.dispatchAction(action, params);
    if (!handled) {
      print('ComponentRegistry: Action "$action" not found on "$instanceId"');
    }

    return component;
  }

  /// Updates a property on a component instance (for wire:model).
  ///
  /// [instanceId] is the target component's instance ID.
  /// [property] is the property name to update.
  /// [value] is the new value.
  ///
  /// Returns the updated component, or null if the instance wasn't found.
  static Future<InteractiveComponent?> updateProperty(String instanceId, String property, dynamic value) async {
    final component = _instance._instances[instanceId];
    if (component == null) {
      print('ComponentRegistry: No instance found for "$instanceId"');
      return null;
    }

    await component.updateProperty(property, value);
    return component;
  }

  /// Restores component state and dispatches an action.
  ///
  /// This is the main entry point for wire requests. It:
  /// 1. Creates a new component instance from the factory
  /// 2. Restores state from the serialized data
  /// 3. Dispatches the requested action
  /// 4. Returns the updated component for re-rendering
  ///
  /// [typeName] is the registered factory name.
  /// [serializedState] is the state from the client.
  /// [action] is the method to call (optional).
  /// [params] are action parameters (optional).
  static Future<InteractiveComponent?> handleWireRequest({
    required String typeName,
    required String serializedState,
    String? action,
    List<dynamic>? params,
    Map<String, dynamic>? modelUpdates,
  }) async {
    final factory = _instance._factories[typeName];
    if (factory == null) {
      print('ComponentRegistry: No factory registered for "$typeName"');
      return null;
    }

    // Create a fresh component instance
    final component = factory();

    // Restore state from client
    component.restoreState(serializedState);

    // Apply model updates if any (wire:model)
    if (modelUpdates != null) {
      for (final entry in modelUpdates.entries) {
        await component.updateProperty(entry.key, entry.value);
      }
    }

    // Dispatch action if provided (wire:click, wire:submit, etc.)
    if (action != null) {
      await component.dispatchAction(action, params);
    }

    // Run before render lifecycle
    await component.beforeRender();

    return component;
  }
}
