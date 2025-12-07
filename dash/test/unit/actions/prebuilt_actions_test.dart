import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';
import 'package:test/test.dart';

/// Test model for action tests
class TestModel extends Model {
  final int? _id;
  final String _name;

  TestModel({int? id, required String name}) : _id = id, _name = name;

  @override
  String get table => 'test_models';

  @override
  String get primaryKey => 'id';

  @override
  dynamic getKey() => _id;

  @override
  void setKey(dynamic key) {}

  @override
  List<String> getFields() => ['id', 'name'];

  int? get id => _id;
  String get name => _name;

  @override
  Map<String, dynamic> toMap() => {'id': _id, 'name': _name};

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(id: map['id'] as int?, name: map['name'] as String);
  }
}

void main() {
  group('CreateAction', () {
    test('make() creates action with default label', () {
      final action = CreateAction.make<TestModel>();
      expect(action.getName(), equals('create'));
      expect(action.getLabel(), equals('Create'));
    });

    test('make() creates action with custom record label', () {
      final action = CreateAction.make<TestModel>('User');
      expect(action.getLabel(), equals('New User'));
    });

    test('has plus icon', () {
      final action = CreateAction.make<TestModel>();
      expect(action.getIcon(), equals(HeroIcons.plus));
    });

    test('has primary color', () {
      final action = CreateAction.make<TestModel>();
      expect(action.getColor(), equals(ActionColor.primary));
    });

    test('has md size', () {
      final action = CreateAction.make<TestModel>();
      expect(action.getSize(), equals(ActionSize.md));
    });

    test('url points to create page', () {
      final action = CreateAction.make<TestModel>();
      final record = TestModel(id: 1, name: 'Test');
      final url = action.getUrl(record, '/admin/users');
      expect(url, equals('/admin/users/create'));
    });
  });

  group('EditAction', () {
    test('make() creates action', () {
      final action = EditAction.make<TestModel>();
      expect(action.getName(), equals('edit'));
      expect(action.getLabel(), equals('Edit'));
    });

    test('has pencil icon', () {
      final action = EditAction.make<TestModel>();
      expect(action.getIcon(), equals(HeroIcons.pencilSquare));
    });

    test('has secondary color', () {
      final action = EditAction.make<TestModel>();
      expect(action.getColor(), equals(ActionColor.secondary));
    });

    test('url points to edit page with record id', () {
      final action = EditAction.make<TestModel>();
      final record = TestModel(id: 42, name: 'Test');
      final url = action.getUrl(record, '/admin/users');
      expect(url, equals('/admin/users/42/edit'));
    });
  });

  group('DeleteAction', () {
    test('make() creates action', () {
      final action = DeleteAction.make<TestModel>();
      expect(action.getName(), equals('delete'));
      expect(action.getLabel(), equals('Delete'));
    });

    test('make() with record label customizes confirmation', () {
      final action = DeleteAction.make<TestModel>('user');
      expect(action.getConfirmationHeading(), equals('Are you sure you want to delete this user?'));
    });

    test('has trash icon', () {
      final action = DeleteAction.make<TestModel>();
      expect(action.getIcon(), equals(HeroIcons.trash));
    });

    test('has danger color', () {
      final action = DeleteAction.make<TestModel>();
      expect(action.getColor(), equals(ActionColor.danger));
    });

    test('requires confirmation', () {
      final action = DeleteAction.make<TestModel>();
      expect(action.isConfirmationRequired(), isTrue);
    });

    test('has default confirmation heading', () {
      final action = DeleteAction.make<TestModel>();
      expect(action.getConfirmationHeading(), equals('Are you sure you want to delete this record?'));
    });

    test('has default confirmation description', () {
      final action = DeleteAction.make<TestModel>();
      expect(action.getConfirmationDescription(), equals('This action cannot be undone.'));
    });

    test('action url points to delete endpoint with record id', () {
      final action = DeleteAction.make<TestModel>();
      final record = TestModel(id: 42, name: 'Test');
      final url = action.getActionUrl(record, '/admin/users');
      expect(url, equals('/admin/users/42/delete'));
    });
  });

  group('ViewAction', () {
    test('make() creates action', () {
      final action = ViewAction.make<TestModel>();
      expect(action.getName(), equals('view'));
      expect(action.getLabel(), equals('View'));
    });

    test('has eye icon', () {
      final action = ViewAction.make<TestModel>();
      expect(action.getIcon(), equals(HeroIcons.eye));
    });

    test('has secondary color', () {
      final action = ViewAction.make<TestModel>();
      expect(action.getColor(), equals(ActionColor.secondary));
    });

    test('url points to view page with record id', () {
      final action = ViewAction.make<TestModel>();
      final record = TestModel(id: 42, name: 'Test');
      final url = action.getUrl(record, '/admin/users');
      expect(url, equals('/admin/users/42'));
    });
  });

  group('SaveAction', () {
    test('make() creates action', () {
      final action = SaveAction.make<TestModel>();
      expect(action.getName(), equals('save'));
      expect(action.getLabel(), equals('Save Changes'));
    });

    test('make() with create operation uses Create label', () {
      final action = SaveAction.make<TestModel>(operation: FormOperation.create);
      expect(action.getLabel(), equals('Create'));
    });

    test('make() with edit operation uses Save Changes label', () {
      final action = SaveAction.make<TestModel>(operation: FormOperation.edit);
      expect(action.getLabel(), equals('Save Changes'));
    });

    test('has check icon', () {
      final action = SaveAction.make<TestModel>();
      expect(action.getIcon(), equals(HeroIcons.check));
    });

    test('has primary color', () {
      final action = SaveAction.make<TestModel>();
      expect(action.getColor(), equals(ActionColor.primary));
    });
  });

  group('CancelAction', () {
    test('make() creates action', () {
      final action = CancelAction.make<TestModel>();
      expect(action.getName(), equals('cancel'));
      expect(action.getLabel(), equals('Cancel'));
    });

    test('has no icon by default', () {
      final action = CancelAction.make<TestModel>();
      expect(action.getIcon(), isNull);
    });

    test('has secondary color', () {
      final action = CancelAction.make<TestModel>();
      expect(action.getColor(), equals(ActionColor.secondary));
    });

    test('renders with history.back onclick', () {
      final action = CancelAction.make<TestModel>();
      // CancelAction uses browser history.back() instead of URL navigation
      final component = action.renderAsFormAction();
      expect(component, isA<Component>());
    });
  });

  group('ActionColor', () {
    test('has all expected values', () {
      expect(ActionColor.values, contains(ActionColor.primary));
      expect(ActionColor.values, contains(ActionColor.secondary));
      expect(ActionColor.values, contains(ActionColor.danger));
      expect(ActionColor.values, contains(ActionColor.warning));
      expect(ActionColor.values, contains(ActionColor.success));
      expect(ActionColor.values, contains(ActionColor.info));
    });
  });

  group('ActionSize', () {
    test('has all expected values', () {
      expect(ActionSize.values, contains(ActionSize.xs));
      expect(ActionSize.values, contains(ActionSize.sm));
      expect(ActionSize.values, contains(ActionSize.md));
      expect(ActionSize.values, contains(ActionSize.lg));
    });
  });
}
