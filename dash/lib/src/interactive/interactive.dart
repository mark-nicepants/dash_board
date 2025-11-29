/// Interactive component system for Dash (Livewire-like).
///
/// This module provides a reactive server-driven component architecture
/// where state lives on the server and the UI is updated via wire: directives.
///
/// ## Quick Start
///
/// 1. Create a component by extending [InteractiveComponent]:
/// ```dart
/// class Counter extends InteractiveComponent {
///   int count = 0;
///
///   @override
///   String get componentId => 'counter';
///
///   void increment() => count++;
///
///   @override
///   Map<String, dynamic> getState() => {'count': count};
///
///   @override
///   void setState(Map<String, dynamic> state) {
///     count = state['count'] ?? 0;
///   }
///
///   @override
///   Map<String, Function(List<dynamic>)> getActions() => {
///     'increment': (_) => increment(),
///   };
///
///   @override
///   Component render() {
///     return div([
///       text('Count: $count'),
///       button(attributes: {'wire:click': 'increment'}, [text('+')]),
///     ]);
///   }
/// }
/// ```
///
/// 2. Register the component factory:
/// ```dart
/// ComponentRegistry.registerFactory('counter', () => Counter());
/// ```
///
/// 3. Use in your pages:
/// ```dart
/// final counter = Counter();
/// await counter.mount();
/// return counter.build(); // Returns component wrapped with wire attributes
/// ```
///
/// ## Wire Directives
///
/// | Directive | Description |
/// |-----------|-------------|
/// | `wire:click="method"` | Call method on click |
/// | `wire:click="method(arg)"` | Call method with arguments |
/// | `wire:model="property"` | Two-way data binding |
/// | `wire:model.lazy="property"` | Bind on change (not input) |
/// | `wire:submit="method"` | Handle form submission |
/// | `wire:keydown.enter="method"` | Handle specific key events |
/// | `wire:loading` | Show element during requests |
///
/// ## Alpine.js Integration
///
/// Use `$wire` in Alpine.js to access component methods:
/// ```html
/// <button x-on:click="$wire.call('increment')">+</button>
/// <button x-on:click="$wire.set('count', 0)">Reset</button>
/// ```
library;

export 'component_registry.dart';
export 'component_state.dart';
export 'interactive_component.dart';
export 'wire_handler.dart';
