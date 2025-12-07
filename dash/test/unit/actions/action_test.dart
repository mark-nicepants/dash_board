import 'package:dash/dash.dart';
import 'package:test/test.dart';

/// Test model for action tests
class TestModel extends Model {
  final int? _id;
  final String _name;
  final bool _isActive;
  final DateTime? _deletedAt;

  TestModel({
    int? id,
    required String name,
    bool isActive = true,
    DateTime? deletedAt,
  })  : _id = id,
        _name = name,
        _isActive = isActive,
        _deletedAt = deletedAt;

  @override
  String get table => 'test_models';

  @override
  String get primaryKey => 'id';

  @override
  dynamic getKey() => _id;

  @override
  void setKey(dynamic key) {}

  @override
  List<String> getFields() => ['id', 'name', 'is_active', 'deleted_at'];

  int? get id => _id;
  String get name => _name;
  bool get isActive => _isActive;
  DateTime? get deletedAt => _deletedAt;

  @override
  Map<String, dynamic> toMap() => {
        'id': _id,
        'name': _name,
        'is_active': _isActive,
        'deleted_at': _deletedAt?.toIso8601String(),
      };

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      isActive: map['is_active'] as bool? ?? true,
      deletedAt: map['deleted_at'] != null ? DateTime.parse(map['deleted_at'] as String) : null,
    );
  }
}

void main() {
  group('Action', () {
    group('Factory Method', () {
      test('make() creates action with name', () {
        final action = Action.make<TestModel>('edit');
        expect(action.getName(), equals('edit'));
      });
    });

    group('Label Configuration', () {
      test('label() sets custom label', () {
        final action = Action.make<TestModel>('edit').label('Edit User');
        expect(action.getLabel(), equals('Edit User'));
      });

      test('getLabel() derives label from name when not set', () {
        final action = Action.make<TestModel>('editUser');
        expect(action.getLabel(), equals('Edit User'));
      });

      test('getLabel() handles snake_case names', () {
        final action = Action.make<TestModel>('edit_user');
        expect(action.getLabel(), equals('Edit User'));
      });

      test('hiddenLabel() hides the label', () {
        final action = Action.make<TestModel>('edit').hiddenLabel();
        expect(action.isLabelHidden(), isTrue);
      });

      test('hiddenLabel(false) shows the label', () {
        final action = Action.make<TestModel>('edit').hiddenLabel(false);
        expect(action.isLabelHidden(), isFalse);
      });
    });

    group('Icon Configuration', () {
      test('icon() sets the icon', () {
        final action = Action.make<TestModel>('edit').icon(HeroIcons.pencilSquare);
        expect(action.getIcon(), equals(HeroIcons.pencilSquare));
      });

      test('iconPosition() sets icon position', () {
        final action = Action.make<TestModel>('edit').iconPosition(IconPosition.after);
        expect(action.getIconPosition(), equals(IconPosition.after));
      });

      test('default icon position is before', () {
        final action = Action.make<TestModel>('edit');
        expect(action.getIconPosition(), equals(IconPosition.before));
      });
    });

    group('Color Configuration', () {
      test('color() sets action color', () {
        final action = Action.make<TestModel>('edit').color(ActionColor.danger);
        expect(action.getColor(), equals(ActionColor.danger));
      });

      test('danger() sets color to danger', () {
        final action = Action.make<TestModel>('delete').danger();
        expect(action.getColor(), equals(ActionColor.danger));
      });

      test('success() sets color to success', () {
        final action = Action.make<TestModel>('approve').success();
        expect(action.getColor(), equals(ActionColor.success));
      });

      test('warning() sets color to warning', () {
        final action = Action.make<TestModel>('warn').warning();
        expect(action.getColor(), equals(ActionColor.warning));
      });

      test('info() sets color to info', () {
        final action = Action.make<TestModel>('details').info();
        expect(action.getColor(), equals(ActionColor.info));
      });

      test('secondary() sets color to secondary', () {
        final action = Action.make<TestModel>('cancel').secondary();
        expect(action.getColor(), equals(ActionColor.secondary));
      });

      test('default color is primary', () {
        final action = Action.make<TestModel>('edit');
        expect(action.getColor(), equals(ActionColor.primary));
      });
    });

    group('Size Configuration', () {
      test('size() sets action size', () {
        final action = Action.make<TestModel>('edit').size(ActionSize.lg);
        expect(action.getSize(), equals(ActionSize.lg));
      });

      test('default size is sm', () {
        final action = Action.make<TestModel>('edit');
        expect(action.getSize(), equals(ActionSize.sm));
      });
    });

    group('Visibility Control', () {
      test('hidden() hides action when condition is true', () {
        final action = Action.make<TestModel>('restore').hidden((record) => record.deletedAt == null);

        final activeRecord = TestModel(id: 1, name: 'Active');
        final deletedRecord = TestModel(id: 2, name: 'Deleted', deletedAt: DateTime.now());

        expect(action.isHidden(activeRecord), isTrue);
        expect(action.isHidden(deletedRecord), isFalse);
      });

      test('visible() shows action when condition is true', () {
        final action = Action.make<TestModel>('restore').visible((record) => record.deletedAt != null);

        final activeRecord = TestModel(id: 1, name: 'Active');
        final deletedRecord = TestModel(id: 2, name: 'Deleted', deletedAt: DateTime.now());

        expect(action.isVisible(activeRecord), isFalse);
        expect(action.isVisible(deletedRecord), isTrue);
      });

      test('disabled() disables action when condition is true', () {
        final action = Action.make<TestModel>('edit').disabled((record) => !record.isActive);

        final activeRecord = TestModel(id: 1, name: 'Active', isActive: true);
        final inactiveRecord = TestModel(id: 2, name: 'Inactive', isActive: false);

        expect(action.isDisabled(activeRecord), isFalse);
        expect(action.isDisabled(inactiveRecord), isTrue);
      });

      test('isVisible() returns inverse of isHidden()', () {
        final action = Action.make<TestModel>('edit').hidden((record) => record.id == 1);
        final record1 = TestModel(id: 1, name: 'Test');
        final record2 = TestModel(id: 2, name: 'Test');

        expect(action.isHidden(record1), isTrue);
        expect(action.isVisible(record1), isFalse);
        expect(action.isHidden(record2), isFalse);
        expect(action.isVisible(record2), isTrue);
      });
    });

    group('URL Navigation', () {
      test('url() sets navigation URL', () {
        final action = Action.make<TestModel>('edit').url((record, basePath) => '$basePath/${record.id}/edit');

        final record = TestModel(id: 42, name: 'Test');
        expect(action.getUrl(record, '/users'), equals('/users/42/edit'));
      });

      test('isUrlAction() returns true when URL is set', () {
        final action = Action.make<TestModel>('edit').url((record, basePath) => '$basePath/${record.id}/edit');
        expect(action.isUrlAction(), isTrue);
      });

      test('isUrlAction() returns false when no URL is set', () {
        final action = Action.make<TestModel>('edit');
        expect(action.isUrlAction(), isFalse);
      });

      test('openUrlInNewTab() sets new tab behavior', () {
        final action = Action.make<TestModel>('external').openUrlInNewTab();
        expect(action.shouldOpenUrlInNewTab(), isTrue);
      });

      test('default openUrlInNewTab is false', () {
        final action = Action.make<TestModel>('edit');
        expect(action.shouldOpenUrlInNewTab(), isFalse);
      });
    });

    group('Confirmation Dialog', () {
      test('requiresConfirmation() enables confirmation', () {
        final action = Action.make<TestModel>('delete').requiresConfirmation();
        expect(action.isConfirmationRequired(), isTrue);
      });

      test('default confirmation is not required', () {
        final action = Action.make<TestModel>('edit');
        expect(action.isConfirmationRequired(), isFalse);
      });

      test('confirmationHeading() sets dialog heading', () {
        final action =
            Action.make<TestModel>('delete').requiresConfirmation().confirmationHeading('Delete this user?');
        expect(action.getConfirmationHeading(), equals('Delete this user?'));
      });

      test('default confirmation heading is "Are you sure?"', () {
        final action = Action.make<TestModel>('delete');
        expect(action.getConfirmationHeading(), equals('Are you sure?'));
      });

      test('confirmationDescription() sets dialog description', () {
        final action =
            Action.make<TestModel>('delete').requiresConfirmation().confirmationDescription('This cannot be undone.');
        expect(action.getConfirmationDescription(), equals('This cannot be undone.'));
      });

      test('confirmationButtonLabel() sets confirm button label', () {
        final action = Action.make<TestModel>('delete').requiresConfirmation().confirmationButtonLabel('Yes, delete');
        expect(action.getConfirmationButtonLabel(), equals('Yes, delete'));
      });

      test('default confirmation button label is "Confirm"', () {
        final action = Action.make<TestModel>('delete');
        expect(action.getConfirmationButtonLabel(), equals('Confirm'));
      });

      test('cancelButtonLabel() sets cancel button label', () {
        final action = Action.make<TestModel>('delete').requiresConfirmation().cancelButtonLabel('No, keep it');
        expect(action.getCancelButtonLabel(), equals('No, keep it'));
      });

      test('default cancel button label is "Cancel"', () {
        final action = Action.make<TestModel>('delete');
        expect(action.getCancelButtonLabel(), equals('Cancel'));
      });
    });

    group('POST Actions', () {
      test('actionUrl() sets POST action URL', () {
        final action = Action.make<TestModel>('delete').actionUrl((record, basePath) => '$basePath/${record.id}/delete');

        final record = TestModel(id: 42, name: 'Test');
        expect(action.getActionUrl(record, '/users'), equals('/users/42/delete'));
      });

      test('isPostAction() returns true when actionUrl is set', () {
        final action = Action.make<TestModel>('delete').actionUrl((record, basePath) => '$basePath/${record.id}');
        expect(action.isPostAction(), isTrue);
      });

      test('isPostAction() returns false when no actionUrl is set', () {
        final action = Action.make<TestModel>('edit');
        expect(action.isPostAction(), isFalse);
      });

      test('method() sets HTTP method', () {
        final action = Action.make<TestModel>('delete').method('DELETE');
        expect(action.getMethod(), equals('DELETE'));
      });

      test('method() uppercases the value', () {
        final action = Action.make<TestModel>('delete').method('delete');
        expect(action.getMethod(), equals('DELETE'));
      });

      test('default method is POST', () {
        final action = Action.make<TestModel>('action');
        expect(action.getMethod(), equals('POST'));
      });
    });

    group('Tooltip & Extra Attributes', () {
      test('tooltip() sets tooltip text', () {
        final action = Action.make<TestModel>('edit').tooltip('Edit this record');
        expect(action.getTooltip(), equals('Edit this record'));
      });

      test('extraAttributes() sets additional HTML attributes', () {
        final action = Action.make<TestModel>('edit').extraAttributes({
          'data-testid': 'edit-button',
          'aria-label': 'Edit record',
        });
        final attrs = action.getExtraAttributes();
        expect(attrs, isNotNull);
        expect(attrs!['data-testid'], equals('edit-button'));
        expect(attrs['aria-label'], equals('Edit record'));
      });
    });

    group('Fluent API Chaining', () {
      test('methods can be chained together', () {
        final action = Action.make<TestModel>('delete')
            .label('Delete User')
            .icon(HeroIcons.trash)
            .color(ActionColor.danger)
            .size(ActionSize.sm)
            .requiresConfirmation()
            .confirmationHeading('Are you absolutely sure?')
            .confirmationDescription('This action cannot be undone.')
            .actionUrl((record, basePath) => '$basePath/${record.id}/delete')
            .method('DELETE')
            .tooltip('Permanently delete this user');

        expect(action.getLabel(), equals('Delete User'));
        expect(action.getIcon(), equals(HeroIcons.trash));
        expect(action.getColor(), equals(ActionColor.danger));
        expect(action.getSize(), equals(ActionSize.sm));
        expect(action.isConfirmationRequired(), isTrue);
        expect(action.getConfirmationHeading(), equals('Are you absolutely sure?'));
        expect(action.getConfirmationDescription(), equals('This action cannot be undone.'));
        expect(action.getMethod(), equals('DELETE'));
        expect(action.getTooltip(), equals('Permanently delete this user'));
      });
    });

    group('Button Variant Conversion', () {
      test('converts ActionColor to ButtonVariant correctly', () {
        expect(Action.make<TestModel>('a').color(ActionColor.primary).buttonVariant, equals(ButtonVariant.primary));
        expect(Action.make<TestModel>('a').color(ActionColor.secondary).buttonVariant, equals(ButtonVariant.secondary));
        expect(Action.make<TestModel>('a').color(ActionColor.danger).buttonVariant, equals(ButtonVariant.danger));
        expect(Action.make<TestModel>('a').color(ActionColor.warning).buttonVariant, equals(ButtonVariant.warning));
        expect(Action.make<TestModel>('a').color(ActionColor.success).buttonVariant, equals(ButtonVariant.success));
        expect(Action.make<TestModel>('a').color(ActionColor.info).buttonVariant, equals(ButtonVariant.info));
      });
    });

    group('Button Size Conversion', () {
      test('converts ActionSize to ButtonSize correctly', () {
        expect(Action.make<TestModel>('a').size(ActionSize.xs).buttonSize, equals(ButtonSize.xs));
        expect(Action.make<TestModel>('a').size(ActionSize.sm).buttonSize, equals(ButtonSize.sm));
        expect(Action.make<TestModel>('a').size(ActionSize.md).buttonSize, equals(ButtonSize.md));
        expect(Action.make<TestModel>('a').size(ActionSize.lg).buttonSize, equals(ButtonSize.lg));
      });
    });

    group('getRecordId()', () {
      test('returns the primary key value', () {
        final action = Action.make<TestModel>('edit');
        final record = TestModel(id: 42, name: 'Test');
        expect(action.getRecordId(record), equals(42));
      });
    });
  });
}
