# Automatic Database Migrations

Dash provides an opt-in automatic migration system that can detect and create tables and columns based on your schema definitions. The best part? **Schemas are automatically generated from your `@DashModel` annotations** - no manual schema definition needed!

## Features

- ✅ **Auto-Generated Schemas**: Schemas created automatically from model annotations
- ✅ **Automatic Table Creation**: Detects missing tables and creates them
- ✅ **Column Addition**: Adds missing columns to existing tables
- ✅ **Database Agnostic**: Abstracted interfaces for different databases
- ✅ **SQLite Support**: Full SQLite implementation included
- ✅ **Preserves Data**: Safe migrations that don't delete existing data
- ✅ **Testable**: Designed with single responsibility and composability
- ✅ **Opt-in**: Manual control when you need it

## Quick Start

### 1. Annotate Your Models

```dart
import 'package:dash/dash.dart';

part 'user.model.g.dart';

@DashModel(table: 'users')
class User extends Model with _$UserModelMixin {
  int? id;
  String? name;
  String? email;
  String? role;
  
  @Column(name: 'created_at')
  DateTime? createdAt;
}
```

### 2. Run Code Generation

```bash
dart run build_runner build
```

This generates a `schema` getter for each model that returns a `TableSchema`.

### 3. Add Schema to Your Resources

```dart
class UserResource extends Resource<User> {
  @override
  Type get model => User;

  @override
  User newModelInstance() => User();

  @override
  TableSchema? schema() => UserModel.schema;  // Add this line!
  
  // ... rest of your resource
}
```

### 4. Use `fromResources()` in Your App

```dart
import 'package:dash/dash.dart';
import 'resources/user_resource.dart';
import 'resources/post_resource.dart';

void main() async {
  final resources = <Resource>[
    UserResource(),
    PostResource(),
  ];

  final panel = Panel()
    ..database(
      DatabaseConfig.using(
        SqliteConnector('app.db'),
        // Automatically extract schemas from resources!
        migrations: MigrationConfig.fromResources(
          resources: resources,
          verbose: true,
        ),
      ),
    )
    ..registerResources(resources);

  await panel.serve(port: 8080);
}
```

### 5. That's It!

Tables and columns will be created automatically when your application starts. No need to manually define schemas - they're derived from your resources!

## How Schema Generation Works

The code generator analyzes your `@DashModel` annotations and field types to automatically create `TableSchema` definitions:

```dart
// Your model
@DashModel(table: 'users')
class User extends Model with _$UserModelMixin {
  int? id;
  String? name;
  String? email;
}

// Generated schema (automatic!)
static TableSchema get schema {
  return TableSchema(
    name: 'users',
    columns: [
      ColumnDefinition(
        name: 'id',
        type: ColumnType.integer,
        isPrimaryKey: true,
        autoIncrement: true,
        nullable: true,
      ),
      ColumnDefinition(
        name: 'name',
        type: ColumnType.text,
        nullable: true,
      ),
      ColumnDefinition(
        name: 'email',
        type: ColumnType.text,
        nullable: true,
      ),
    ],
  );
}
```

### Type Mapping

Dart types are automatically mapped to database column types:

| Dart Type | Database Type |
|-----------|---------------|
| `int` | `ColumnType.integer` |
| `String` | `ColumnType.text` |
| `double` | `ColumnType.real` |
| `bool` | `ColumnType.boolean` |
| `DateTime` | `ColumnType.datetime` |

## Manual Schema Definition (Alternative)

If you prefer manual control or need to define schemas for non-model tables, you have several options:

### Option 1: Direct Schema Access (Simpler)

If you just need schemas from models without resources:

```dart
final schemas = [
  UserModel.schema,
  PostModel.schema,
];

final config = DatabaseConfig.using(
  SqliteConnector('app.db'),
  migrations: MigrationConfig.enable(schemas: schemas),
);
```

### Option 2: Manual Schema Definition (Full Control)

Use `SchemaBuilder` for complete manual control:

```dart
final schemas = [
  SchemaBuilder.table(
    'custom_table',
    columns: [
      SchemaBuilder.id(),
      SchemaBuilder.text('name', nullable: false),
      SchemaBuilder.datetime('created_at'),
    ],
  ),
];
```

### Comparison

```dart
// ✅ Best: Automatic from resources (one source of truth)
MigrationConfig.fromResources(resources: [UserResource(), PostResource()])

// ✅ Good: Direct model schemas (when you don't use resources)
MigrationConfig.enable(schemas: [UserModel.schema, PostModel.schema])

// ✅ Valid: Manual definition (full control, more verbose)
MigrationConfig.enable(schemas: [SchemaBuilder.table(...)])
```

## Column Types

Dash supports the following column types:

| Type | Description | SQLite Mapping |
|------|-------------|----------------|
| `ColumnType.integer` | Integer numbers | `INTEGER` |
| `ColumnType.text` | Text strings | `TEXT` |
| `ColumnType.real` | Floating point numbers | `REAL` |
| `ColumnType.boolean` | Boolean values | `INTEGER` (0/1) |
| `ColumnType.datetime` | Date and time | `TEXT` (ISO8601) |
| `ColumnType.blob` | Binary data | `BLOB` |

## Column Options

```dart
ColumnDefinition(
  name: 'email',
  type: ColumnType.text,
  isPrimaryKey: false,      // Is this the primary key?
  autoIncrement: false,     // Auto-increment for integers?
  nullable: true,           // Can this be NULL?
  unique: false,            // Enforce uniqueness?
  defaultValue: null,       // Default value
)
```

## Advanced Usage

### Running Migrations Manually

If you prefer manual control:

```dart
final config = DatabaseConfig.using(
  SqliteConnector('app.db'),
  // No migrations config
);

await config.connect();

// Later, run migrations manually
await config.connector.runMigrations(
  schemas,
  verbose: true,
);
```

### Checking if Migrations are Needed

```dart
final connector = SqliteConnector('app.db');
await connector.connect();

final inspector = connector.createSchemaInspector();
final builder = SqliteMigrationBuilder();
final runner = MigrationRunner(
  connector: connector,
  inspector: inspector,
  builder: builder,
);

final schema = TableSchema(name: 'users', columns: [...]);

if (await runner.needsMigration(schema)) {
  print('Migration needed!');
  final missing = await runner.getMissingColumns(schema);
  print('Missing columns: ${missing.map((c) => c.name).join(', ')}');
}
```

### Disabling Migrations

```dart
final config = DatabaseConfig.using(
  SqliteConnector('app.db'),
  migrations: MigrationConfig.disable(), // Explicit disable
);
```

## How It Works

The migration system follows a clear separation of concerns:

1. **SchemaDefinition**: Database-agnostic representation of tables and columns
2. **SchemaInspector**: Detects existing tables and columns in the database
3. **MigrationBuilder**: Generates SQL statements for creating/altering tables
4. **MigrationRunner**: Orchestrates the migration process

```
┌─────────────────┐
│ DatabaseConfig  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Connector     │
│  .runMigrations │
└────────┬────────┘
         │
         ▼
┌─────────────────┐      ┌──────────────────┐
│ MigrationRunner │─────▶│ SchemaInspector  │
│                 │      │  (check DB)      │
└────────┬────────┘      └──────────────────┘
         │
         ▼
┌─────────────────┐
│ MigrationBuilder│
│  (generate SQL) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Execute SQL   │
└─────────────────┘
```

## Safety Features

- **Non-destructive**: Migrations only add tables and columns, never delete or modify existing ones
- **Idempotent**: Running migrations multiple times is safe
- **Data preservation**: Existing data is never lost
- **Default values**: New columns use specified default values

## Testing

Migrations are designed to be testable using in-memory databases:

```dart
import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  test('migrations create tables', () async {
    final connector = SqliteConnector(':memory:');
    await connector.connect();

    final schemas = [
      TableSchema(
        name: 'test_table',
        columns: [
          ColumnDefinition(
            name: 'id',
            type: ColumnType.integer,
            isPrimaryKey: true,
          ),
        ],
      ),
    ];

    await connector.runMigrations(schemas);

    final result = await connector.query(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='test_table'",
    );

    expect(result.length, equals(1));
  });
}
```

## Limitations

### Current Limitations

- **Column modification**: Cannot alter existing column types or constraints
- **Column deletion**: Cannot remove columns
- **Table deletion**: Cannot drop tables
- **Indexes**: No automatic index creation (yet)
- **Foreign keys**: No automatic foreign key constraints (yet)

### Workarounds

For complex schema changes not supported by automatic migrations:

1. Use manual SQL migrations
2. Create a new table and copy data
3. Manage schema changes outside of Dash

```dart
// Manual migration example
await connector.execute('''
  ALTER TABLE users RENAME TO users_old;
''');

await connector.runMigrations([newUsersSchema]);

await connector.execute('''
  INSERT INTO users (id, name, email)
  SELECT id, name, email FROM users_old;
''');

await connector.execute('DROP TABLE users_old');
```

## Best Practices

1. **Version control your schemas**: Keep schema definitions in version control
2. **Test migrations**: Use in-memory databases for testing
3. **Enable verbose mode in development**: See what migrations are being run
4. **Disable in production if needed**: Use manual migrations for critical production databases
5. **Backup before changes**: Always backup production databases before schema changes

## Example: Complete Application

```dart
import 'package:dash/dash.dart';
import 'resources/user_resource.dart';
import 'resources/post_resource.dart';

void main() async {
  final resources = <Resource>[
    UserResource(),
    PostResource(),
  ];

  final panel = Panel()
    ..setId('admin')
    ..setPath('/admin')
    ..database(
      DatabaseConfig.using(
        SqliteConnector('database/app.db'),
        // Schemas automatically extracted from resources!
        migrations: MigrationConfig.fromResources(
          resources: resources,
          verbose: true,
        ),
      ),
    )
    ..registerResources(resources);

  await panel.serve(port: 8080);
}
```

The resources need to override the `schema()` method:

```dart
class UserResource extends Resource<User> {
  @override
  Type get model => User;

  @override
  User newModelInstance() => User();

  @override
  TableSchema? schema() => UserModel.schema;

  @override
  Table<User> table(Table<User> table) {
    return table.columns([
      TextColumn.make('name').sortable(),
      TextColumn.make('email'),
    ]);
  }
}
```

And the model just needs the `@DashModel` annotation:

```dart
part 'user.model.g.dart';

@DashModel(table: 'users')
class User extends Model with _$UserModelMixin {
  int? id;
  String? name;
  String? email;
  String? role;
  DateTime? createdAt;
}
```

Run `dart run build_runner build` and everything is wired up automatically!

## Contributing

The migration system is designed to be extensible. To add support for other databases:

1. Implement `MigrationBuilder` for your database
2. Implement `SchemaInspector` for your database
3. Override `runMigrations` in your connector

See `SqliteMigrationBuilder` and `SqliteSchemaInspector` for examples.
