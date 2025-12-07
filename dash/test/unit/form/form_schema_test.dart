import 'package:dash_board/dash_board.dart';
import 'package:test/test.dart';

/// Test model for form schema tests
class TestModel extends Model {
  final int? _id;
  final String _name;
  final String _email;
  final String? _bio;
  final bool _isActive;

  TestModel({int? id, String name = '', String email = '', String? bio, bool isActive = true})
    : _id = id,
      _name = name,
      _email = email,
      _bio = bio,
      _isActive = isActive;

  @override
  String get table => 'test_models';

  @override
  String get primaryKey => 'id';

  @override
  dynamic getKey() => _id;

  @override
  void setKey(dynamic key) {}

  @override
  List<String> getFields() => ['id', 'name', 'email', 'bio', 'is_active'];

  int? get id => _id;
  String get name => _name;
  String get email => _email;
  String? get bio => _bio;
  bool get isActive => _isActive;

  @override
  Map<String, dynamic> toMap() => {'id': _id, 'name': _name, 'email': _email, 'bio': _bio, 'is_active': _isActive};

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      bio: map['bio'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

void main() {
  group('FormSchema', () {
    group('Factory', () {
      test('creates empty form with defaults', () {
        final form = FormSchema<TestModel>();

        expect(form.getComponents(), isEmpty);
        expect(form.getFields(), isEmpty);
        expect(form.getColumns(), equals(1));
        expect(form.getGap(), equals('4'));
        expect(form.getOperation(), equals(FormOperation.create));
        expect(form.isDisabled(), isFalse);
      });
    });

    group('Fields Configuration', () {
      test('fields() sets form components', () {
        final form = FormSchema<TestModel>().fields([TextInput.make('name'), TextInput.make('email')]);

        expect(form.getComponents(), hasLength(2));
        expect(form.getFields(), hasLength(2));
      });

      test('field() adds single component', () {
        final form = FormSchema<TestModel>().field(TextInput.make('name')).field(TextInput.make('email'));

        expect(form.getComponents(), hasLength(2));
      });

      test('getFields() flattens sections', () {
        final form = FormSchema<TestModel>().fields([
          TextInput.make('name'),
          Section.make('Contact Info').schema([TextInput.make('email'), TextInput.make('phone')]),
        ]);

        final fields = form.getFields();
        expect(fields, hasLength(3));
        expect(fields[0].getName(), equals('name'));
        expect(fields[1].getName(), equals('email'));
        expect(fields[2].getName(), equals('phone'));
      });
    });

    group('Layout Configuration', () {
      test('columns() sets grid columns', () {
        final form = FormSchema<TestModel>().columns(2);
        expect(form.getColumns(), equals(2));
      });

      test('gap() sets element gap', () {
        final form = FormSchema<TestModel>().gap('6');
        expect(form.getGap(), equals('6'));
      });
    });

    group('State Path', () {
      test('statePath() sets path prefix', () {
        final form = FormSchema<TestModel>().statePath('form');
        expect(form.getStatePath(), equals('form'));
      });

      test('default statePath is "data"', () {
        final form = FormSchema<TestModel>();
        expect(form.getStatePath(), equals('data'));
      });
    });

    group('Operation Type', () {
      test('operation() sets form operation', () {
        final form = FormSchema<TestModel>().operation(FormOperation.edit);
        expect(form.getOperation(), equals(FormOperation.edit));
      });

      test('default operation is create', () {
        final form = FormSchema<TestModel>();
        expect(form.getOperation(), equals(FormOperation.create));
      });
    });

    group('Record Binding', () {
      test('record() sets the model instance', () {
        final model = TestModel(id: 1, name: 'John', email: 'john@test.com');
        final form = FormSchema<TestModel>().record(model);
        expect(form.getRecord(), equals(model));
      });

      test('getRecord() returns null by default', () {
        final form = FormSchema<TestModel>();
        expect(form.getRecord(), isNull);
      });
    });

    group('Disabled State', () {
      test('disabled() disables the form', () {
        final form = FormSchema<TestModel>().disabled();
        expect(form.isDisabled(), isTrue);
      });

      test('disabled(false) enables the form', () {
        final form = FormSchema<TestModel>().disabled(false);
        expect(form.isDisabled(), isFalse);
      });
    });

    group('Button Labels', () {
      test('submitLabel() sets custom submit label', () {
        final form = FormSchema<TestModel>().submitLabel('Save User');
        expect(form.getSubmitLabel(), equals('Save User'));
      });

      test('default submit label depends on operation', () {
        expect(FormSchema<TestModel>().operation(FormOperation.create).getSubmitLabel(), equals('Create'));
        expect(FormSchema<TestModel>().operation(FormOperation.edit).getSubmitLabel(), equals('Save changes'));
        expect(FormSchema<TestModel>().operation(FormOperation.view).getSubmitLabel(), equals('Close'));
      });

      test('cancelLabel() sets custom cancel label', () {
        final form = FormSchema<TestModel>().cancelLabel('Go Back');
        expect(form.getCancelLabel(), equals('Go Back'));
      });

      test('default cancel label is "Cancel"', () {
        final form = FormSchema<TestModel>();
        expect(form.getCancelLabel(), equals('Cancel'));
      });

      test('showCancelButton() controls cancel button visibility', () {
        final form = FormSchema<TestModel>().showCancelButton(false);
        expect(form.shouldShowCancelButton(), isFalse);
      });

      test('default shows cancel button', () {
        final form = FormSchema<TestModel>();
        expect(form.shouldShowCancelButton(), isTrue);
      });
    });

    group('Form Action URL', () {
      test('action() sets form action URL', () {
        final form = FormSchema<TestModel>().action('/users/create');
        expect(form.getAction(), equals('/users/create'));
      });

      test('method() sets HTTP method', () {
        final form = FormSchema<TestModel>().method(FormSubmitMethod.put);
        expect(form.getMethod(), equals(FormSubmitMethod.put));
      });

      test('default method is POST', () {
        final form = FormSchema<TestModel>();
        expect(form.getMethod(), equals(FormSubmitMethod.post));
      });
    });

    group('Custom Form Actions', () {
      test('formActions() sets custom actions', () {
        final form = FormSchema<TestModel>().formActions([
          SaveAction.make<TestModel>(),
          CancelAction.make<TestModel>(),
        ]);

        expect(form.hasFormActions(), isTrue);
        expect(form.getFormActions(), hasLength(2));
      });

      test('hasFormActions() returns false when no actions', () {
        final form = FormSchema<TestModel>();
        expect(form.hasFormActions(), isFalse);
      });
    });

    group('Validation', () {
      test('getValidationRules() collects rules from fields', () {
        final form = FormSchema<TestModel>().fields([
          TextInput.make('name').required(),
          TextInput.make('email').required().email(),
        ]);

        final rules = form.getValidationRules();
        expect(rules.containsKey('name'), isTrue);
        expect(rules.containsKey('email'), isTrue);
        expect(rules['name'], contains('required'));
        expect(rules['email'], contains('required'));
        expect(rules['email'], contains('email'));
      });

      test('validate() returns empty map for valid data', () {
        final form = FormSchema<TestModel>().fields([
          TextInput.make('name').required(),
          TextInput.make('email').required().email(),
        ]);

        final errors = form.validate({'name': 'John Doe', 'email': 'john@example.com'});

        expect(errors, isEmpty);
      });

      test('validate() returns errors for invalid data', () {
        final form = FormSchema<TestModel>().fields([
          TextInput.make('name').required(),
          TextInput.make('email').required().email(),
        ]);

        final errors = form.validate({'name': '', 'email': 'invalid-email'});

        expect(errors.containsKey('name'), isTrue);
        expect(errors.containsKey('email'), isTrue);
      });
    });

    group('Fill and Initial Data', () {
      test('fill() populates field defaults from record', () {
        final model = TestModel(id: 1, name: 'John', email: 'john@test.com', bio: 'Hello');
        final form = FormSchema<TestModel>()
            .fields([TextInput.make('name'), TextInput.make('email'), Textarea.make('bio')])
            .record(model);

        form.fill();

        final fields = form.getFields();
        expect(fields[0].getDefaultValue(), equals('John'));
        expect(fields[1].getDefaultValue(), equals('john@test.com'));
        expect(fields[2].getDefaultValue(), equals('Hello'));
      });

      test('fill() does nothing when record is null', () {
        final form = FormSchema<TestModel>().fields([TextInput.make('name').defaultValue('default')]);

        form.fill();

        final fields = form.getFields();
        expect(fields[0].getDefaultValue(), equals('default'));
      });

      test('fill() only populates fields that exist in record', () {
        final model = TestModel(id: 1, name: 'John', email: 'john@test.com');
        final form = FormSchema<TestModel>()
            .fields([TextInput.make('name'), TextInput.make('nonexistent')])
            .record(model);

        form.fill();

        final fields = form.getFields();
        expect(fields[0].getDefaultValue(), equals('John'));
        expect(fields[1].getDefaultValue(), isNull);
      });

      test('fillAsync() populates field defaults from record', () async {
        final model = TestModel(id: 1, name: 'John', email: 'john@test.com', bio: 'Hello');
        final form = FormSchema<TestModel>()
            .fields([TextInput.make('name'), TextInput.make('email'), Textarea.make('bio')])
            .record(model);

        await form.fillAsync();

        final fields = form.getFields();
        expect(fields[0].getDefaultValue(), equals('John'));
        expect(fields[1].getDefaultValue(), equals('john@test.com'));
        expect(fields[2].getDefaultValue(), equals('Hello'));
      });

      test('fillAsync() does nothing when record is null', () async {
        final form = FormSchema<TestModel>().fields([TextInput.make('name').defaultValue('default')]);

        await form.fillAsync();

        final fields = form.getFields();
        expect(fields[0].getDefaultValue(), equals('default'));
      });

      test('fillAsync() sets record reference on fields', () async {
        final model = TestModel(id: 1, name: 'John', email: 'john@test.com');
        final form = FormSchema<TestModel>().fields([TextInput.make('name')]).record(model);

        await form.fillAsync();

        final fields = form.getFields();
        expect(fields[0].record, equals(model));
      });

      test('getInitialData() returns record data', () {
        final model = TestModel(id: 1, name: 'John', email: 'john@test.com');
        final form = FormSchema<TestModel>().record(model);

        final data = form.getInitialData();
        expect(data['name'], equals('John'));
        expect(data['email'], equals('john@test.com'));
      });

      test('getInitialData() includes field defaults', () {
        final form = FormSchema<TestModel>().fields([
          TextInput.make('name').defaultValue('Default Name'),
          TextInput.make('status').defaultValue('active'),
        ]);

        final data = form.getInitialData();
        expect(data['name'], equals('Default Name'));
        expect(data['status'], equals('active'));
      });
    });

    group('Fluent API Chaining', () {
      test('methods can be chained together', () {
        final model = TestModel(id: 1, name: 'John', email: 'john@test.com');
        final form = FormSchema<TestModel>()
            .columns(2)
            .gap('6')
            .statePath('user')
            .operation(FormOperation.edit)
            .record(model)
            .submitLabel('Update User')
            .cancelLabel('Cancel')
            .showCancelButton(true)
            .action('/users/1')
            .method(FormSubmitMethod.put)
            .fields([TextInput.make('name').required(), TextInput.make('email').required().email()]);

        expect(form.getColumns(), equals(2));
        expect(form.getGap(), equals('6'));
        expect(form.getStatePath(), equals('user'));
        expect(form.getOperation(), equals(FormOperation.edit));
        expect(form.getRecord(), equals(model));
        expect(form.getSubmitLabel(), equals('Update User'));
        expect(form.getCancelLabel(), equals('Cancel'));
        expect(form.shouldShowCancelButton(), isTrue);
        expect(form.getAction(), equals('/users/1'));
        expect(form.getMethod(), equals(FormSubmitMethod.put));
        expect(form.getFields(), hasLength(2));
      });
    });
  });

  group('FormOperation', () {
    test('has create, edit, and view values', () {
      expect(FormOperation.values, contains(FormOperation.create));
      expect(FormOperation.values, contains(FormOperation.edit));
      expect(FormOperation.values, contains(FormOperation.view));
    });
  });

  group('FormSubmitMethod', () {
    test('has post, put, and patch values', () {
      expect(FormSubmitMethod.values, contains(FormSubmitMethod.post));
      expect(FormSubmitMethod.values, contains(FormSubmitMethod.put));
      expect(FormSubmitMethod.values, contains(FormSubmitMethod.patch));
    });
  });
}
