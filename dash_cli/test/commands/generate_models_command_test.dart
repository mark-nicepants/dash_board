import 'dart:io';

import 'package:dash_panel_cli/src/generators/schema_parser.dart';
import 'package:test/test.dart';

void main() {
  group('GenerateModelsCommand', () {
    late Directory tempDir;
    late File schemaFile;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('dash_cli_test_');

      // Create a test schema file
      final schemasDir = Directory('${tempDir.path}/schemas');
      schemasDir.createSync();

      schemaFile = File('${schemasDir.path}/test.yaml');
      schemaFile.writeAsStringSync('''
model: TestModel
table: test_models
timestamps: true

fields:
  id:
    type: int
    primaryKey: true
    autoIncrement: true

  name:
    type: string
    required: true

  email:
    type: string
    format: email
''');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('SchemaParser can parse a valid schema file', () {
      final parser = SchemaParser();
      final schema = parser.parseFile(schemaFile.path);

      expect(schema.modelName, 'TestModel');
      expect(schema.config.table, 'test_models');
      expect(schema.config.timestamps, isTrue);
      expect(schema.fields, hasLength(3));

      final idField = schema.fields.firstWhere((f) => f.name == 'id');
      expect(idField.isPrimaryKey, isTrue);
      expect(idField.autoIncrement, isTrue);

      final nameField = schema.fields.firstWhere((f) => f.name == 'name');
      expect(nameField.isRequired, isTrue);
      expect(nameField.dartType, 'String');

      final emailField = schema.fields.firstWhere((f) => f.name == 'email');
      expect(emailField.format, 'email');
    });

    test('SchemaParser throws on missing file', () {
      final parser = SchemaParser();
      expect(() => parser.parseFile('/nonexistent/path.yaml'), throwsA(isA<ArgumentError>()));
    });
  });
}
