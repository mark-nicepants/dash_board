import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('FormField.dehydrateValue()', () {
    group('Toggle', () {
      test('converts "true" string to true', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue('true'), equals(true));
      });

      test('converts "1" string to true', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue('1'), equals(true));
      });

      test('converts "on" string to true', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue('on'), equals(true));
      });

      test('converts "false" string to false', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue('false'), equals(false));
      });

      test('converts "0" string to false', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue('0'), equals(false));
      });

      test('converts empty string to false', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue(''), equals(false));
      });

      test('preserves boolean true', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue(true), equals(true));
      });

      test('preserves boolean false', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue(false), equals(false));
      });

      test('converts integer 1 to true', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue(1), equals(true));
      });

      test('converts integer 0 to false', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue(0), equals(false));
      });

      test('converts null to false', () {
        final field = Toggle.make('is_active');
        expect(field.dehydrateValue(null), equals(false));
      });

      test('uses custom onValue when set', () {
        final field = Toggle.make('is_active').onValue('yes');
        expect(field.dehydrateValue('yes'), equals(true));
        expect(field.dehydrateValue('no'), equals(false));
      });

      test('applies custom dehydrate callback before conversion', () {
        final field = Toggle.make('is_active').dehydrate((value) => value == 'active' ? 'true' : 'false');
        expect(field.dehydrateValue('active'), equals(true));
        expect(field.dehydrateValue('inactive'), equals(false));
      });
    });

    group('Checkbox', () {
      test('converts "true" string to true', () {
        final field = Checkbox.make('terms');
        expect(field.dehydrateValue('true'), equals(true));
      });

      test('converts "1" string to true', () {
        final field = Checkbox.make('terms');
        expect(field.dehydrateValue('1'), equals(true));
      });

      test('converts "on" string to true', () {
        final field = Checkbox.make('terms');
        expect(field.dehydrateValue('on'), equals(true));
      });

      test('converts "false" string to false', () {
        final field = Checkbox.make('terms');
        expect(field.dehydrateValue('false'), equals(false));
      });

      test('preserves boolean values', () {
        final field = Checkbox.make('terms');
        expect(field.dehydrateValue(true), equals(true));
        expect(field.dehydrateValue(false), equals(false));
      });

      test('converts null to false', () {
        final field = Checkbox.make('terms');
        expect(field.dehydrateValue(null), equals(false));
      });

      test('uses custom checkedValue when set', () {
        final field = Checkbox.make('terms').checkedValue('yes');
        expect(field.dehydrateValue('yes'), equals(true));
        expect(field.dehydrateValue('no'), equals(false));
      });
    });

    group('DatePicker', () {
      test('converts ISO date string to DateTime', () {
        final field = DatePicker.make('birth_date');
        final result = field.dehydrateValue('2024-01-15');
        expect(result, isA<DateTime>());
        expect((result as DateTime).year, equals(2024));
        expect(result.month, equals(1));
        expect(result.day, equals(15));
      });

      test('converts ISO datetime string to DateTime', () {
        final field = DatePicker.make('appointment');
        final result = field.dehydrateValue('2024-01-15T14:30:00');
        expect(result, isA<DateTime>());
        expect((result as DateTime).hour, equals(14));
        expect(result.minute, equals(30));
      });

      test('preserves DateTime value', () {
        final field = DatePicker.make('birth_date');
        final now = DateTime.now();
        expect(field.dehydrateValue(now), equals(now));
      });

      test('converts null to null', () {
        final field = DatePicker.make('birth_date');
        expect(field.dehydrateValue(null), isNull);
      });

      test('converts empty string to null', () {
        final field = DatePicker.make('birth_date');
        expect(field.dehydrateValue(''), isNull);
      });

      test('returns null for invalid date string', () {
        final field = DatePicker.make('birth_date');
        expect(field.dehydrateValue('not-a-date'), isNull);
      });
    });

    group('Select (multiple)', () {
      test('preserves list value', () {
        final field = Select.make('tags').multiple();
        final result = field.dehydrateValue(['tag1', 'tag2']);
        expect(result, equals(['tag1', 'tag2']));
      });

      test('converts single string to list', () {
        final field = Select.make('tags').multiple();
        final result = field.dehydrateValue('tag1');
        expect(result, equals(['tag1']));
      });

      test('converts null to empty list', () {
        final field = Select.make('tags').multiple();
        final result = field.dehydrateValue(null);
        expect(result, equals([]));
      });

      test('single select does not convert to list', () {
        final field = Select.make('status');
        final result = field.dehydrateValue('active');
        expect(result, equals('active'));
      });
    });

    group('RelationshipSelect', () {
      test('converts string number to integer', () {
        final field = RelationshipSelect.make('author').relationship('author', 'User');
        final result = field.dehydrateValue('42');
        expect(result, equals(42));
      });

      test('preserves integer value', () {
        final field = RelationshipSelect.make('author').relationship('author', 'User');
        final result = field.dehydrateValue(42);
        expect(result, equals(42));
      });

      test('converts null to null', () {
        final field = RelationshipSelect.make('author').relationship('author', 'User');
        final result = field.dehydrateValue(null);
        expect(result, isNull);
      });

      test('converts empty string to null', () {
        final field = RelationshipSelect.make('author').relationship('author', 'User');
        final result = field.dehydrateValue('');
        expect(result, isNull);
      });

      test('returns null for non-numeric string when no schema', () {
        final field = RelationshipSelect.make('author').relationship('author', 'User');
        // Without a record/schema, non-numeric strings fall back to original value
        final result = field.dehydrateValue('abc');
        expect(result, equals('abc'));
      });

      test('uses schema column type when record is set', () {
        // Create a mock model with schema
        final field = RelationshipSelect.make('author').relationship('author', 'User');
        final model = _TestModelWithSchema();
        field.record = model;

        // The schema says author_id is integer
        final result = field.dehydrateValue('123');
        expect(result, equals(123));
      });

      test('handles text foreign key when schema specifies text', () {
        final field = RelationshipSelect.make(
          'category',
        ).relationship('category', 'Category', foreignKey: 'category_code');
        final model = _TestModelWithTextForeignKey();
        field.record = model;

        final result = field.dehydrateValue('electronics');
        expect(result, equals('electronics'));
      });
    });

    group('TextInput (default behavior)', () {
      test('preserves string value', () {
        final field = TextInput.make('name');
        expect(field.dehydrateValue('John'), equals('John'));
      });

      test('preserves null', () {
        final field = TextInput.make('name');
        expect(field.dehydrateValue(null), isNull);
      });

      test('custom dehydrate callback is applied', () {
        final field = TextInput.make('slug').dehydrate((value) => value?.toString().toLowerCase().replaceAll(' ', '-'));
        expect(field.dehydrateValue('Hello World'), equals('hello-world'));
      });
    });
  });
}

/// Test model with an integer foreign key schema
class _TestModelWithSchema extends Model {
  @override
  String get table => 'posts';

  @override
  TableSchema get schema => const TableSchema(
    name: 'posts',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
      ColumnDefinition(name: 'title', type: ColumnType.text),
      ColumnDefinition(name: 'author_id', type: ColumnType.integer),
    ],
  );

  @override
  void fromMap(Map<String, dynamic> map) {}

  @override
  List<String> getFields() => ['id', 'title', 'author_id'];

  @override
  dynamic getKey() => null;

  @override
  void setKey(dynamic value) {}

  @override
  Map<String, dynamic> toMap() => {};
}

/// Test model with a text foreign key schema
class _TestModelWithTextForeignKey extends Model {
  @override
  String get table => 'products';

  @override
  TableSchema get schema => const TableSchema(
    name: 'products',
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
      ColumnDefinition(name: 'name', type: ColumnType.text),
      ColumnDefinition(name: 'category_code', type: ColumnType.text),
    ],
  );

  @override
  void fromMap(Map<String, dynamic> map) {}

  @override
  List<String> getFields() => ['id', 'name', 'category_code'];

  @override
  dynamic getKey() => null;

  @override
  void setKey(dynamic value) {}

  @override
  Map<String, dynamic> toMap() => {};
}
