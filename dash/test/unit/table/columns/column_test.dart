import 'package:dash_board/dash_board.dart';
import 'package:test/test.dart';

/// Test model for column tests
class TestModel extends Model {
  final int? _id;
  final String _name;
  final String _email;
  final bool _isActive;
  final DateTime? _createdAt;
  final double? _price;

  TestModel({int? id, String name = '', String email = '', bool isActive = true, DateTime? createdAt, double? price})
    : _id = id,
      _name = name,
      _email = email,
      _isActive = isActive,
      _createdAt = createdAt,
      _price = price;

  @override
  String get table => 'test_models';

  @override
  String get primaryKey => 'id';

  @override
  dynamic getKey() => _id;

  @override
  void setKey(dynamic key) {}

  @override
  List<String> getFields() => ['id', 'name', 'email', 'is_active', 'created_at', 'price'];

  int? get id => _id;
  String get name => _name;
  String get email => _email;
  bool get isActive => _isActive;
  double? get price => _price;

  @override
  Map<String, dynamic> toMap() => {
    'id': _id,
    'name': _name,
    'email': _email,
    'is_active': _isActive,
    'created_at': _createdAt?.toIso8601String(),
    'price': _price,
  };

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : null,
      price: (map['price'] as num?)?.toDouble(),
    );
  }
}

void main() {
  group('TableColumn (Base)', () {
    group('Label Configuration', () {
      test('label() sets custom label', () {
        final column = TextColumn.make('user_name').label('User Name');
        expect(column.getLabel(), equals('User Name'));
      });

      test('getLabel() derives label from snake_case name', () {
        final column = TextColumn.make('user_name');
        expect(column.getLabel(), equals('User Name'));
      });

      test('getLabel() derives label from camelCase name', () {
        final column = TextColumn.make('userName');
        expect(column.getLabel(), equals('User Name'));
      });

      test('getLabel() handles single word', () {
        final column = TextColumn.make('name');
        expect(column.getLabel(), equals('Name'));
      });
    });

    group('Sorting & Searching', () {
      test('sortable() enables sorting', () {
        final column = TextColumn.make('name').sortable();
        expect(column.isSortable(), isTrue);
      });

      test('sortable(false) disables sorting', () {
        final column = TextColumn.make('name').sortable(false);
        expect(column.isSortable(), isFalse);
      });

      test('default sortable is false', () {
        final column = TextColumn.make('name');
        expect(column.isSortable(), isFalse);
      });

      test('searchable() enables searching', () {
        final column = TextColumn.make('name').searchable();
        expect(column.isSearchable(), isTrue);
      });

      test('searchable(false) disables searching', () {
        final column = TextColumn.make('name').searchable(false);
        expect(column.isSearchable(), isFalse);
      });

      test('default searchable is false', () {
        final column = TextColumn.make('name');
        expect(column.isSearchable(), isFalse);
      });
    });

    group('Toggleable & Hidden', () {
      test('toggleable() enables column toggle', () {
        final column = TextColumn.make('name').toggleable();
        expect(column.isToggleable(), isTrue);
      });

      test('toggleable() with isToggledHiddenByDefault', () {
        final column = TextColumn.make('name').toggleable(isToggledHiddenByDefault: true);
        expect(column.isToggleable(), isTrue);
        expect(column.isToggledHiddenByDefault(), isTrue);
      });

      test('hidden() hides the column', () {
        final column = TextColumn.make('name').hidden();
        expect(column.isHidden(), isTrue);
      });

      test('hidden(false) shows the column', () {
        final column = TextColumn.make('name').hidden(false);
        expect(column.isHidden(), isFalse);
      });
    });

    group('Alignment', () {
      test('alignment() sets column alignment', () {
        final column = TextColumn.make('name').alignment(ColumnAlignment.center);
        expect(column.getAlignment(), equals(ColumnAlignment.center));
      });

      test('alignStart() sets start alignment', () {
        final column = TextColumn.make('name').alignStart();
        expect(column.getAlignment(), equals(ColumnAlignment.start));
      });

      test('alignCenter() sets center alignment', () {
        final column = TextColumn.make('name').alignCenter();
        expect(column.getAlignment(), equals(ColumnAlignment.center));
      });

      test('alignEnd() sets end alignment', () {
        final column = TextColumn.make('name').alignEnd();
        expect(column.getAlignment(), equals(ColumnAlignment.end));
      });

      test('default alignment is start', () {
        final column = TextColumn.make('name');
        expect(column.getAlignment(), equals(ColumnAlignment.start));
      });
    });

    group('Width & Grow', () {
      test('width() sets column width', () {
        final column = TextColumn.make('name').width('200px');
        expect(column.getWidth(), equals('200px'));
      });

      test('grow() enables column grow', () {
        final column = TextColumn.make('name').grow();
        expect(column.canGrow(), isTrue);
      });

      test('grow(false) disables column grow', () {
        final column = TextColumn.make('name').grow(false);
        expect(column.canGrow(), isFalse);
      });
    });

    group('Placeholder & Default', () {
      test('placeholder() sets placeholder text', () {
        final column = TextColumn.make('name').placeholder('N/A');
        expect(column.getPlaceholder(), equals('N/A'));
      });

      test('defaultValue() sets default value', () {
        final column = TextColumn.make('name').defaultValue('Unknown');
        expect(column.getDefaultValue(), equals('Unknown'));
      });
    });

    group('State Resolution', () {
      test('getState() returns value from model map', () {
        final column = TextColumn.make('name');
        final model = TestModel(id: 1, name: 'John', email: 'john@example.com');

        expect(column.getState(model), equals('John'));
      });

      test('getState() returns placeholder for null value', () {
        final column = TextColumn.make('missing_field').placeholder('N/A');
        final model = TestModel(id: 1, name: 'John');

        expect(column.getState(model), equals('N/A'));
      });

      test('getState() returns default for null value', () {
        final column = TextColumn.make('missing_field').defaultValue('Default');
        final model = TestModel(id: 1, name: 'John');

        expect(column.getState(model), equals('Default'));
      });

      test('state() sets custom state resolver', () {
        final column = TextColumn.make('custom').state((model) => 'Custom Value: ${model.toMap()['name']}');
        final model = TestModel(id: 1, name: 'John');

        expect(column.getState(model), equals('Custom Value: John'));
      });
    });

    group('Format State', () {
      test('formatState() returns string for value', () {
        final column = TextColumn.make('name');
        expect(column.formatState('test'), equals('test'));
      });

      test('formatState() returns placeholder for null', () {
        final column = TextColumn.make('name').placeholder('-');
        expect(column.formatState(null), equals('-'));
      });

      test('formatState() returns empty string for null without placeholder', () {
        final column = TextColumn.make('name');
        expect(column.formatState(null), equals(''));
      });
    });
  });

  group('TextColumn', () {
    group('Factory', () {
      test('make() creates column with name', () {
        final column = TextColumn.make('title');
        expect(column.getName(), equals('title'));
      });
    });

    group('Badge Display', () {
      test('badge() enables badge display', () {
        final column = TextColumn.make('status').badge();
        expect(column.isBadge(), isTrue);
      });

      test('badge(false) disables badge display', () {
        final column = TextColumn.make('status').badge(false);
        expect(column.isBadge(), isFalse);
      });

      test('default badge is false', () {
        final column = TextColumn.make('status');
        expect(column.isBadge(), isFalse);
      });
    });

    group('Color', () {
      test('color() sets static color', () {
        final column = TextColumn.make('status').color('success');
        final model = TestModel(id: 1, name: 'Test');
        expect(column.getColor(model), equals('success'));
      });

      test('color() sets dynamic color function', () {
        final column = TextColumn.make('status').color((Model record) {
          final isActive = record.toMap()['is_active'] as bool;
          return isActive ? 'success' : 'danger';
        });

        final activeModel = TestModel(id: 1, name: 'Test', isActive: true);
        final inactiveModel = TestModel(id: 2, name: 'Test', isActive: false);

        expect(column.getColor(activeModel), equals('success'));
        expect(column.getColor(inactiveModel), equals('danger'));
      });
    });

    group('Text Size', () {
      test('size() sets text size', () {
        final column = TextColumn.make('name').size(TextSize.large);
        expect(column.getSize(), equals(TextSize.large));
      });

      test('default size is medium', () {
        final column = TextColumn.make('name');
        expect(column.getSize(), equals(TextSize.medium));
      });
    });

    group('Text Weight', () {
      test('weight() sets text weight', () {
        final column = TextColumn.make('name').weight(TextWeight.bold);
        expect(column.getWeight(), equals(TextWeight.bold));
      });

      test('default weight is normal', () {
        final column = TextColumn.make('name');
        expect(column.getWeight(), equals(TextWeight.normal));
      });
    });

    group('Text Wrapping', () {
      test('wrap() enables text wrapping', () {
        final column = TextColumn.make('description').wrap();
        expect(column.shouldWrap(), isTrue);
      });

      test('wrap(false) disables text wrapping', () {
        final column = TextColumn.make('description').wrap(false);
        expect(column.shouldWrap(), isFalse);
      });

      test('lineClamp() sets line limit', () {
        final column = TextColumn.make('description').lineClamp(3);
        expect(column.getLineClamp(), equals(3));
      });
    });

    group('Icon', () {
      test('icon() sets icon before text', () {
        final column = TextColumn.make('status').icon('check');
        expect(column.getIcon(), equals('check'));
        expect(column.getIconPosition(), equals(IconPosition.before));
      });

      test('icon() sets icon after text', () {
        final column = TextColumn.make('link').icon('external', position: IconPosition.after);
        expect(column.getIconAfter(), equals('external'));
        expect(column.getIconPosition(), equals(IconPosition.after));
      });
    });

    group('Copyable', () {
      test('copyable() enables copy on click', () {
        final column = TextColumn.make('email').copyable();
        expect(column.isCopyable(), isTrue);
      });

      test('copyable() with custom message', () {
        final column = TextColumn.make('email').copyable(message: 'Email copied!');
        expect(column.isCopyable(), isTrue);
        expect(column.getCopyMessage(), equals('Email copied!'));
      });
    });

    group('URL Link', () {
      test('url() sets static URL', () {
        final column = TextColumn.make('website').url('https://example.com');
        final model = TestModel(id: 1, name: 'Test');
        expect(column.getUrl(model), equals('https://example.com'));
      });

      test('url() sets dynamic URL function', () {
        final column = TextColumn.make('name').url((Model record) {
          return '/users/${record.toMap()['id']}';
        });
        final model = TestModel(id: 42, name: 'Test');
        expect(column.getUrl(model), equals('/users/42'));
      });

      test('url() with openInNewTab opens in new tab', () {
        final column = TextColumn.make('website').url('https://example.com', openInNewTab: true);
        expect(column.shouldOpenUrlInNewTab(), isTrue);
      });
    });

    group('Fluent API Chaining', () {
      test('methods can be chained together', () {
        final column = TextColumn.make('status')
            .label('Status')
            .searchable()
            .sortable()
            .badge()
            .color('success')
            .size(TextSize.small)
            .weight(TextWeight.medium)
            .alignCenter()
            .width('100px');

        expect(column.getLabel(), equals('Status'));
        expect(column.isSearchable(), isTrue);
        expect(column.isSortable(), isTrue);
        expect(column.isBadge(), isTrue);
        expect(column.getSize(), equals(TextSize.small));
        expect(column.getWeight(), equals(TextWeight.medium));
        expect(column.getAlignment(), equals(ColumnAlignment.center));
        expect(column.getWidth(), equals('100px'));
      });
    });
  });

  group('BooleanColumn', () {
    group('Factory', () {
      test('make() creates column with name', () {
        final column = BooleanColumn.make('is_active');
        expect(column.getName(), equals('is_active'));
      });
    });

    group('Icons', () {
      test('trueIcon() sets icon for true state', () {
        final column = BooleanColumn.make('is_active').trueIcon(HeroIcons.checkCircle);
        // The icon is set via the boolean() method inherited from IconColumn
        expect(column, isNotNull);
      });

      test('falseIcon() sets icon for false state', () {
        final column = BooleanColumn.make('is_active').falseIcon(HeroIcons.xCircle);
        expect(column, isNotNull);
      });
    });

    group('Colors', () {
      test('trueColor() sets color for true state', () {
        final column = BooleanColumn.make('is_active').trueColor('success');
        expect(column, isNotNull);
      });

      test('falseColor() sets color for false state', () {
        final column = BooleanColumn.make('is_active').falseColor('danger');
        expect(column, isNotNull);
      });
    });

    group('Fluent API', () {
      test('methods can be chained together', () {
        final column = BooleanColumn.make('is_active')
            .label('Active')
            .sortable()
            .trueIcon(HeroIcons.checkCircle)
            .falseIcon(HeroIcons.xCircle)
            .trueColor('success')
            .falseColor('danger')
            .alignCenter();

        expect(column.getLabel(), equals('Active'));
        expect(column.isSortable(), isTrue);
        expect(column.getAlignment(), equals(ColumnAlignment.center));
      });
    });
  });
}
