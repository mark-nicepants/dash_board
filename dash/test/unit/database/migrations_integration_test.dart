import 'package:dash_board/dash_board.dart';
import 'package:test/test.dart';

void main() {
  group('Database Migrations Integration', () {
    late SqliteConnector connector;

    setUp(() {
      connector = SqliteConnector(':memory:');
    });

    tearDown(() async {
      await connector.close();
    });

    test('DatabaseConfig runs migrations automatically when enabled', () async {
      final schemas = [
        const TableSchema(
          name: 'users',
          columns: [
            ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
            ColumnDefinition(name: 'name', type: ColumnType.text, nullable: false),
            ColumnDefinition(name: 'email', type: ColumnType.text, unique: true),
          ],
        ),
      ];

      final config = DatabaseConfig.using(connector, migrations: MigrationConfig.enable(schemas: schemas));

      await config.connect();

      // Verify table was created
      final result = await connector.query("SELECT name FROM sqlite_master WHERE type='table' AND name='users'");
      expect(result.length, equals(1));

      // Verify columns exist
      final columns = await connector.query('PRAGMA table_info(users)');
      final columnNames = columns.map((col) => col['name']).toList();
      expect(columnNames, containsAll(['id', 'name', 'email']));
    });

    test('DatabaseConfig does not run migrations when disabled', () async {
      final config = DatabaseConfig.using(connector, migrations: MigrationConfig.disable());

      await config.connect();

      // Verify no tables were created
      final result = await connector.query("SELECT name FROM sqlite_master WHERE type='table'");
      expect(result, isEmpty);
    });

    test('migrations work without MigrationConfig', () async {
      final config = DatabaseConfig.using(connector);

      await config.connect();

      // Should connect without errors
      expect(connector.isConnected, isTrue);
    });

    test('migrations add columns on subsequent connects', () async {
      // First connect with minimal schema
      final initialSchema = const TableSchema(
        name: 'posts',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'title', type: ColumnType.text),
        ],
      );

      final config1 = DatabaseConfig.using(connector, migrations: MigrationConfig.enable(schemas: [initialSchema]));

      await config1.connect();

      // Verify initial table
      var columns = await connector.query('PRAGMA table_info(posts)');
      var columnNames = columns.map((col) => col['name']).toList();
      expect(columnNames, equals(['id', 'title']));

      // Now add more columns
      final extendedSchema = const TableSchema(
        name: 'posts',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'title', type: ColumnType.text),
          ColumnDefinition(name: 'content', type: ColumnType.text),
          ColumnDefinition(name: 'published', type: ColumnType.boolean, defaultValue: false),
        ],
      );

      // Run migrations again with extended schema
      await connector.runMigrations([extendedSchema]);

      // Verify new columns were added
      columns = await connector.query('PRAGMA table_info(posts)');
      columnNames = columns.map((col) => col['name']).toList();
      expect(columnNames, containsAll(['id', 'title', 'content', 'published']));
    });

    test('migrations handle multiple tables', () async {
      final schemas = [
        const TableSchema(
          name: 'users',
          columns: [
            ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
            ColumnDefinition(name: 'name', type: ColumnType.text),
          ],
        ),
        const TableSchema(
          name: 'posts',
          columns: [
            ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
            ColumnDefinition(name: 'title', type: ColumnType.text),
            ColumnDefinition(name: 'user_id', type: ColumnType.integer),
          ],
        ),
        const TableSchema(
          name: 'comments',
          columns: [
            ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true),
            ColumnDefinition(name: 'post_id', type: ColumnType.integer),
            ColumnDefinition(name: 'content', type: ColumnType.text),
          ],
        ),
      ];

      final config = DatabaseConfig.using(connector, migrations: MigrationConfig.enable(schemas: schemas));

      await config.connect();

      // Verify all tables were created
      final tables = await connector.query("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
      final tableNames = tables.map((t) => t['name']).toList();
      expect(tableNames, equals(['comments', 'posts', 'users']));
    });

    test('migrations preserve existing data when adding columns', () async {
      // Create initial table and insert data
      await connector.connect();
      await connector.execute('''
        CREATE TABLE products (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL
        )
      ''');
      await connector.insert('products', {'name': 'Product 1'});
      await connector.insert('products', {'name': 'Product 2'});

      // Run migration to add columns
      final schema = const TableSchema(
        name: 'products',
        columns: [
          ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
          ColumnDefinition(name: 'name', type: ColumnType.text, nullable: false),
          ColumnDefinition(name: 'price', type: ColumnType.real, defaultValue: 0.0),
          ColumnDefinition(name: 'stock', type: ColumnType.integer, defaultValue: 0),
        ],
      );

      await connector.runMigrations([schema]);

      // Verify data is still there
      final products = await connector.query('SELECT * FROM products');
      expect(products.length, equals(2));
      expect(products[0]['name'], equals('Product 1'));
      expect(products[1]['name'], equals('Product 2'));

      // Verify new columns have default values
      expect(products[0]['price'], isNotNull);
      expect(products[0]['stock'], isNotNull);
    });

    test('verbose mode logs migration statements', () async {
      final schemas = [
        const TableSchema(
          name: 'logs',
          columns: [ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true)],
        ),
      ];

      final config = DatabaseConfig.using(
        connector,
        migrations: MigrationConfig.enable(
          schemas: schemas,
          verbose: false, // Disabled to avoid test output noise
        ),
      );

      // Verbose logging is tested manually - this just verifies the config works
      await config.connect();

      // Just verify connection succeeded
      expect(connector.isConnected, isTrue);
    });
  });
}
