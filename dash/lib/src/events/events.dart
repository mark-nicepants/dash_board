/// Event system for Dash.
///
/// This module provides a comprehensive event dispatching system that enables:
/// - Type-safe event handling
/// - Named events with pattern matching
/// - Real-time frontend updates via SSE
/// - Plugin integration
///
/// ## Quick Start
///
/// ```dart
/// import 'package:dash_board/src/events/events.dart';
///
/// // Get the dispatcher
/// final dispatcher = EventDispatcher.instance;
///
/// // Listen to model events
/// dispatcher.listen<ModelCreatedEvent>((event) {
///   print('Created: ${event.model.table}');
/// });
///
/// // Listen by name
/// dispatcher.listenTo('users.created', (event) {
///   print('User created!');
/// });
///
/// // Dispatch custom events
/// await dispatcher.dispatch(MyCustomEvent(data));
/// ```
///
/// ## Model Events
///
/// The following events are automatically dispatched during model operations:
/// - [ModelCreatingEvent] - Before a model is created
/// - [ModelCreatedEvent] - After a model is created
/// - [ModelUpdatingEvent] - Before a model is updated (with before state)
/// - [ModelUpdatedEvent] - After a model is updated (with changes)
/// - [ModelDeletingEvent] - Before a model is deleted
/// - [ModelDeletedEvent] - After a model is deleted
/// - [ModelSavedEvent] - After any save operation (create or update)
///
/// ## Creating Custom Events
///
/// ```dart
/// class OrderShippedEvent extends Event {
///   final Order order;
///   final String trackingNumber;
///
///   OrderShippedEvent(this.order, this.trackingNumber);
///
///   @override
///   String get name => 'orders.shipped';
///
///   @override
///   Map<String, dynamic> toPayload() => {
///     'order_id': order.id,
///     'tracking_number': trackingNumber,
///   };
///
///   @override
///   bool get broadcastToFrontend => true;
/// }
/// ```
library;

export 'event.dart';
export 'event_dispatcher.dart';
export 'model_events.dart';
