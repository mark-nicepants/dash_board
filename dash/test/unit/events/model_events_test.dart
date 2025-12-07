import 'package:dash/src/events/events.dart';
import 'package:dash/src/model/model.dart';
import 'package:test/test.dart';

/// Test model for model event tests.
class TestModel extends Model {
  int? id;
  String name;
  String email;

  TestModel({this.id, this.name = '', this.email = ''});

  @override
  String get table => 'test_models';

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{'name': name, 'email': email};
    if (id != null) map['id'] = id;
    return map;
  }

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    name = map['name'] as String? ?? '';
    email = map['email'] as String? ?? '';
    return this;
  }

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic key) {
    id = key as int?;
  }

  @override
  List<String> getFields() => ['id', 'name', 'email'];
}

void main() {
  group('ModelCreatingEvent', () {
    test('has correct name format', () {
      final model = TestModel(name: 'Test', email: 'test@example.com');
      final event = ModelCreatingEvent(model);

      expect(event.name, equals('test_models.creating'));
    });

    test('includes model data in payload', () {
      final model = TestModel(name: 'Test', email: 'test@example.com');
      final event = ModelCreatingEvent(model);
      final payload = event.toPayload();

      expect(payload['table'], equals('test_models'));
      expect(payload['data']['name'], equals('Test'));
      expect(payload['data']['email'], equals('test@example.com'));
    });

    test('does not broadcast to frontend by default', () {
      final model = TestModel();
      final event = ModelCreatingEvent(model);

      expect(event.broadcastToFrontend, isFalse);
    });
  });

  group('ModelCreatedEvent', () {
    test('has correct name format', () {
      final model = TestModel(id: 1, name: 'Test', email: 'test@example.com');
      final event = ModelCreatedEvent(model);

      expect(event.name, equals('test_models.created'));
    });

    test('includes model ID in payload', () {
      final model = TestModel(id: 42, name: 'Test', email: 'test@example.com');
      final event = ModelCreatedEvent(model);
      final payload = event.toPayload();

      expect(payload['id'], equals(42));
      expect(payload['table'], equals('test_models'));
    });

    test('includes causer_id when provided', () {
      final model = TestModel(id: 1);
      final event = ModelCreatedEvent(model, causerId: 'user_123');
      final payload = event.toPayload();

      expect(payload['causer_id'], equals('user_123'));
    });

    test('broadcasts to frontend', () {
      final model = TestModel();
      final event = ModelCreatedEvent(model);

      expect(event.broadcastToFrontend, isTrue);
    });
  });

  group('ModelUpdatingEvent', () {
    test('has correct name format', () {
      final model = TestModel(id: 1);
      final beforeState = {'id': 1, 'name': 'Old', 'email': 'old@example.com'};
      final event = ModelUpdatingEvent(model, beforeState);

      expect(event.name, equals('test_models.updating'));
    });

    test('includes before and after state', () {
      final model = TestModel(id: 1, name: 'New', email: 'new@example.com');
      final beforeState = {'id': 1, 'name': 'Old', 'email': 'old@example.com'};
      final event = ModelUpdatingEvent(model, beforeState);
      final payload = event.toPayload();

      expect(payload['before']['name'], equals('Old'));
      expect(payload['after']['name'], equals('New'));
    });

    test('getChanges() computes differences', () {
      final model = TestModel(id: 1, name: 'New', email: 'same@example.com');
      final beforeState = {'id': 1, 'name': 'Old', 'email': 'same@example.com'};
      final event = ModelUpdatingEvent(model, beforeState);

      final changes = event.getChanges();

      expect(changes.containsKey('name'), isTrue);
      expect(changes['name']['before'], equals('Old'));
      expect(changes['name']['after'], equals('New'));
      expect(changes.containsKey('email'), isFalse); // unchanged
    });

    test('does not broadcast to frontend by default', () {
      final model = TestModel();
      final event = ModelUpdatingEvent(model, {});

      expect(event.broadcastToFrontend, isFalse);
    });
  });

  group('ModelUpdatedEvent', () {
    test('has correct name format', () {
      final model = TestModel(id: 1);
      final event = ModelUpdatedEvent(model);

      expect(event.name, equals('test_models.updated'));
    });

    test('includes changes when provided', () {
      final model = TestModel(id: 1);
      final changes = {
        'name': {'before': 'Old', 'after': 'New'},
      };
      final event = ModelUpdatedEvent(model, changes: changes);
      final payload = event.toPayload();

      expect(payload['changes'], equals(changes));
    });

    test('includes beforeState when provided', () {
      final model = TestModel(id: 1);
      final beforeState = {'name': 'Old'};
      final event = ModelUpdatedEvent(model, beforeState: beforeState);
      final payload = event.toPayload();

      expect(payload['before'], equals(beforeState));
    });

    test('broadcasts to frontend', () {
      final model = TestModel();
      final event = ModelUpdatedEvent(model);

      expect(event.broadcastToFrontend, isTrue);
    });
  });

  group('ModelDeletingEvent', () {
    test('has correct name format', () {
      final model = TestModel(id: 1);
      final event = ModelDeletingEvent(model);

      expect(event.name, equals('test_models.deleting'));
    });

    test('includes model data in payload', () {
      final model = TestModel(id: 1, name: 'Test', email: 'test@example.com');
      final event = ModelDeletingEvent(model);
      final payload = event.toPayload();

      expect(payload['id'], equals(1));
      expect(payload['data']['name'], equals('Test'));
    });

    test('does not broadcast to frontend by default', () {
      final model = TestModel();
      final event = ModelDeletingEvent(model);

      expect(event.broadcastToFrontend, isFalse);
    });
  });

  group('ModelDeletedEvent', () {
    test('has correct name format', () {
      final event = ModelDeletedEvent(table: 'test_models', modelId: 1, deletedData: {}, modelType: 'TestModel');

      expect(event.name, equals('test_models.deleted'));
    });

    test('factory constructor from model works', () {
      final model = TestModel(id: 42, name: 'Test', email: 'test@example.com');
      final event = ModelDeletedEvent.fromModel(model);

      expect(event.table, equals('test_models'));
      expect(event.modelId, equals(42));
      expect(event.modelType, equals('TestModel'));
      expect(event.deletedData['name'], equals('Test'));
    });

    test('includes causer_id when provided', () {
      final model = TestModel(id: 1);
      final event = ModelDeletedEvent.fromModel(model, causerId: 'admin_1');
      final payload = event.toPayload();

      expect(payload['causer_id'], equals('admin_1'));
    });

    test('broadcasts to frontend', () {
      final event = ModelDeletedEvent(table: 'test_models', modelId: 1, deletedData: {}, modelType: 'TestModel');

      expect(event.broadcastToFrontend, isTrue);
    });
  });

  group('ModelSavedEvent', () {
    test('has correct name format', () {
      final model = TestModel(id: 1);
      final event = ModelSavedEvent(model, wasCreating: true);

      expect(event.name, equals('test_models.saved'));
    });

    test('indicates if was creating', () {
      final model = TestModel(id: 1);
      final createEvent = ModelSavedEvent(model, wasCreating: true);
      final updateEvent = ModelSavedEvent(model, wasCreating: false);

      expect(createEvent.toPayload()['was_creating'], isTrue);
      expect(updateEvent.toPayload()['was_creating'], isFalse);
    });

    test('broadcasts to frontend', () {
      final model = TestModel();
      final event = ModelSavedEvent(model, wasCreating: true);

      expect(event.broadcastToFrontend, isTrue);
    });
  });
}
