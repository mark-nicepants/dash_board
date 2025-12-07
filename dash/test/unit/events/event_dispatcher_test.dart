import 'dart:async';

import 'package:dash_board/src/events/events.dart';
import 'package:test/test.dart';

/// Custom test event for testing the event system.
class TestEvent extends Event {
  final String message;

  TestEvent(this.message);

  @override
  String get name => 'test.event';

  @override
  Map<String, dynamic> toPayload() => {'message': message};
}

/// Another test event for type-based listening tests.
class AnotherTestEvent extends Event {
  final int value;

  AnotherTestEvent(this.value);

  @override
  String get name => 'another.event';

  @override
  Map<String, dynamic> toPayload() => {'value': value};
}

/// Test event that broadcasts to frontend.
class BroadcastEvent extends Event {
  final String data;

  BroadcastEvent(this.data);

  @override
  String get name => 'broadcast.event';

  @override
  bool get broadcastToFrontend => true;

  @override
  Map<String, dynamic> toPayload() => {'data': data};
}

void main() {
  group('Event', () {
    test('has a name', () {
      final event = TestEvent('hello');
      expect(event.name, equals('test.event'));
    });

    test('has a timestamp', () {
      final before = DateTime.now();
      final event = TestEvent('hello');
      final after = DateTime.now();

      expect(event.timestamp.isAfter(before) || event.timestamp.isAtSameMomentAs(before), isTrue);
      expect(event.timestamp.isBefore(after) || event.timestamp.isAtSameMomentAs(after), isTrue);
    });

    test('converts to payload', () {
      final event = TestEvent('hello world');
      expect(event.toPayload(), equals({'message': 'hello world'}));
    });

    test('defaults broadcastToFrontend to false', () {
      final event = TestEvent('hello');
      expect(event.broadcastToFrontend, isFalse);
    });

    test('defaults broadcastChannel to null', () {
      final event = TestEvent('hello');
      expect(event.broadcastChannel, isNull);
    });

    test('toString includes name', () {
      final event = TestEvent('hello');
      expect(event.toString(), equals('Event(test.event)'));
    });
  });

  group('EventDispatcher', () {
    setUp(EventDispatcher.reset);

    tearDown(EventDispatcher.reset);

    test('is a singleton', () {
      final d1 = EventDispatcher.instance;
      final d2 = EventDispatcher.instance;
      expect(identical(d1, d2), isTrue);
    });

    test('reset creates a new instance', () {
      final d1 = EventDispatcher.instance;
      EventDispatcher.reset();
      final d2 = EventDispatcher.instance;
      expect(identical(d1, d2), isFalse);
    });

    group('listen()', () {
      test('registers typed listener', () async {
        final dispatcher = EventDispatcher.instance;
        var called = false;

        dispatcher.listen<TestEvent>((event) {
          called = true;
          expect(event.message, equals('hello'));
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(called, isTrue);
      });

      test('only receives events of correct type', () async {
        final dispatcher = EventDispatcher.instance;
        var testEventCalled = false;
        var anotherEventCalled = false;

        dispatcher.listen<TestEvent>((event) {
          testEventCalled = true;
        });

        dispatcher.listen<AnotherTestEvent>((event) {
          anotherEventCalled = true;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');

        expect(testEventCalled, isTrue);
        expect(anotherEventCalled, isFalse);
      });

      test('multiple listeners for same type all receive event', () async {
        final dispatcher = EventDispatcher.instance;
        var count = 0;

        dispatcher.listen<TestEvent>((event) => count++);
        dispatcher.listen<TestEvent>((event) => count++);
        dispatcher.listen<TestEvent>((event) => count++);

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(count, equals(3));
      });
    });

    group('listenTo()', () {
      test('registers name-based listener', () async {
        final dispatcher = EventDispatcher.instance;
        var called = false;

        dispatcher.listenTo('test.event', (event) {
          called = true;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(called, isTrue);
      });

      test('does not receive events with different names', () async {
        final dispatcher = EventDispatcher.instance;
        var called = false;

        dispatcher.listenTo('other.event', (event) {
          called = true;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(called, isFalse);
      });
    });

    group('listenToPattern()', () {
      test('matches wildcard pattern test.*', () async {
        final dispatcher = EventDispatcher.instance;
        var count = 0;

        dispatcher.listenToPattern('test.*', (event) {
          count++;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(count, equals(1));
      });

      test('matches wildcard pattern *.event', () async {
        final dispatcher = EventDispatcher.instance;
        var count = 0;

        dispatcher.listenToPattern('*.event', (event) {
          count++;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(count, equals(1));
      });

      test('matches all with *', () async {
        final dispatcher = EventDispatcher.instance;
        var count = 0;

        dispatcher.listenToPattern('*', (event) {
          count++;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        await dispatcher.dispatch(AnotherTestEvent(42), '123');
        expect(count, equals(2));
      });

      test('does not match non-matching pattern', () async {
        final dispatcher = EventDispatcher.instance;
        var called = false;

        dispatcher.listenToPattern('other.*', (event) {
          called = true;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(called, isFalse);
      });
    });

    group('listenAll()', () {
      test('receives all events', () async {
        final dispatcher = EventDispatcher.instance;
        var count = 0;

        dispatcher.listenAll((event) {
          count++;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        await dispatcher.dispatch(AnotherTestEvent(42), '123');
        expect(count, equals(2));
      });
    });

    group('dispatch()', () {
      test('notifies listeners in order: type, name, pattern, global', () async {
        final dispatcher = EventDispatcher.instance;
        final order = <String>[];

        dispatcher.listen<TestEvent>((event) {
          order.add('type');
        });

        dispatcher.listenTo('test.event', (event) {
          order.add('name');
        });

        dispatcher.listenToPattern('test.*', (event) {
          order.add('pattern');
        });

        dispatcher.listenAll((event) {
          order.add('global');
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(order, equals(['type', 'name', 'pattern', 'global']));
      });

      test('handles async listeners', () async {
        final dispatcher = EventDispatcher.instance;
        var completed = false;

        dispatcher.listen<TestEvent>((event) async {
          await Future.delayed(const Duration(milliseconds: 10));
          completed = true;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(completed, isTrue);
      });

      test('continues after listener error', () async {
        final dispatcher = EventDispatcher.instance;
        var secondCalled = false;

        dispatcher.listen<TestEvent>((event) {
          throw Exception('Test error');
        });

        dispatcher.listen<TestEvent>((event) {
          secondCalled = true;
        });

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(secondCalled, isTrue);
      });
    });

    group('dispatchAll()', () {
      test('dispatches multiple events in sequence', () async {
        final dispatcher = EventDispatcher.instance;
        final received = <String>[];

        dispatcher.listen<TestEvent>((event) {
          received.add('test:${event.message}');
        });

        dispatcher.listen<AnotherTestEvent>((event) {
          received.add('another:${event.value}');
        });

        await dispatcher.dispatchAll([TestEvent('first'), AnotherTestEvent(1), TestEvent('second')], '123');

        expect(received, equals(['test:first', 'another:1', 'test:second']));
      });
    });

    group('hasListeners()', () {
      test('returns false when no listeners', () {
        final dispatcher = EventDispatcher.instance;
        expect(dispatcher.hasListeners<TestEvent>(), isFalse);
      });

      test('returns true when typed listener exists', () {
        final dispatcher = EventDispatcher.instance;
        dispatcher.listen<TestEvent>((event) {});
        expect(dispatcher.hasListeners<TestEvent>(), isTrue);
      });

      test('returns true when global listener exists', () {
        final dispatcher = EventDispatcher.instance;
        dispatcher.listenAll((event) {});
        expect(dispatcher.hasListeners<TestEvent>(), isTrue);
      });
    });

    group('clearAllListeners()', () {
      test('removes all listeners', () async {
        final dispatcher = EventDispatcher.instance;
        var called = false;

        dispatcher.listen<TestEvent>((event) => called = true);
        dispatcher.listenTo('test.event', (event) => called = true);
        dispatcher.listenToPattern('test.*', (event) => called = true);
        dispatcher.listenAll((event) => called = true);

        dispatcher.clearAllListeners();

        await dispatcher.dispatch(TestEvent('hello'), '123');
        expect(called, isFalse);
      });
    });

    group('SSE streaming', () {
      test('createSSEStream returns a stream', () {
        final dispatcher = EventDispatcher.instance;
        final stream = dispatcher.createSSEStream();
        expect(stream, isA<Stream<Event>>());
      });

      test('events with broadcastToFrontend are sent to SSE streams', () async {
        final dispatcher = EventDispatcher.instance;
        final stream = dispatcher.createSSEStream();
        final received = <Event>[];

        final subscription = stream.listen(received.add);

        await dispatcher.dispatch(BroadcastEvent('hello'), '123');

        // Give time for async broadcast
        await Future.delayed(const Duration(milliseconds: 10));

        await subscription.cancel();

        expect(received.length, equals(1));
        expect(received.first.name, equals('broadcast.event'));
      });

      test('events without broadcastToFrontend are not sent to SSE streams', () async {
        final dispatcher = EventDispatcher.instance;
        final stream = dispatcher.createSSEStream();
        final received = <Event>[];

        final subscription = stream.listen(received.add);

        await dispatcher.dispatch(TestEvent('hello'), '123');

        // Give time for async broadcast
        await Future.delayed(const Duration(milliseconds: 10));

        await subscription.cancel();

        expect(received.length, equals(0));
      });

      test('sseConnectionCount returns correct count', () {
        final dispatcher = EventDispatcher.instance;
        expect(dispatcher.sseConnectionCount, equals(0));

        dispatcher.createSSEStream();
        expect(dispatcher.sseConnectionCount, equals(1));

        dispatcher.createSSEStream();
        expect(dispatcher.sseConnectionCount, equals(2));
      });
    });
  });
}
