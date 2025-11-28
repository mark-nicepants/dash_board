# Dash Model Schema & Generator

Dash provides a YAML-based schema definition system for defining models. This approach allows you to define your models in a declarative way and generate Dart code automatically.

## Overview

Instead of writing model classes manually with annotations, you can define your models in YAML files and use the Dash generator to create fully-featured Dart model classes.

**Benefits:**
- Declarative, readable model definitions
- IDE autocomplete and validation via JSON Schema
- Consistent code generation
- Easy to review and version control
- Reduces boilerplate code

## Quick Start

### 1. Create a Schema File

Create a YAML file in your `schemas/` directory (e.g., `schemas/user.yaml`):

```yaml
# yaml-language-server: $schema=../../schemas/dash-model.schema.json

model: User
table: users
timestamps: true

fields:
  id:
    type: int
    primaryKey: true
    autoIncrement: true

  name:
    type: string
    required: true
    min: 2
    max: 255

  email:
    type: string
    required: true
    unique: true
    format: email

  password:
    type: string
    required: true
    min: 8

  role:
    type: string
    required: true
    enum:
      - admin
      - user
      - guest
    default: user

  isActive:
    type: bool
    default: true
```

### 2. Run the Generator

```bash
dart run dash:generate schemas lib
```

This will generate `lib/models/user.dart` with a complete `User` model class.

### 3. Use the Generated Model

```dart
import 'package:your_app/models/user.dart';

// Create a new user
final user = User(
  name: 'John Doe',
  email: 'john@example.com',
  password: hashedPassword,
  role: 'user',
);

// Save to database
await user.save();

// Query users
final users = await User.query().where('role', '=', 'admin').get();
```

---

## Schema Reference

### Root Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `model` | string | ✅ | - | The Dart class name (PascalCase, e.g., `User`, `BlogPost`) |
| `table` | string | ✅ | - | The database table name (snake_case, e.g., `users`, `blog_posts`) |
| `timestamps` | boolean | ❌ | `true` | Adds `created_at` and `updated_at` columns |
| `softDeletes` | boolean | ❌ | `false` | Adds `deleted_at` column for soft deletes |
| `fields` | object | ✅ | - | Field definitions (see below) |

### Field Properties

Each field is defined as a key-value pair where the key is the field name (camelCase) and the value is an object with the following properties:

#### Core Properties

| Property | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `type` | string | ✅ | - | Data type: `int`, `string`, `bool`, `double`, `datetime`, `json`, `list` |
| `required` | boolean | ❌ | `false` | Field is required (non-nullable) |
| `nullable` | boolean | ❌ | `true` | Field can be null (opposite of required) |
| `default` | any | ❌ | - | Default value for the field |

#### Primary Key

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `primaryKey` | boolean | `false` | Marks field as primary key |
| `autoIncrement` | boolean | `false` | Auto-increment for integer primary keys |

#### Validation

| Property | Type | Applies To | Description |
|----------|------|------------|-------------|
| `min` | number | `int`, `double`, `string` | Minimum value (numbers) or minimum length (strings) |
| `max` | number | `int`, `double`, `string` | Maximum value (numbers) or maximum length (strings) |
| `format` | string | `string` | Format validation: `email`, `url`, `uuid`, `phone`, `slug` |
| `pattern` | string | `string` | Custom regex pattern for validation |
| `enum` | array | `string` | List of allowed values |

#### Database

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `unique` | boolean | `false` | Field must be unique in the database |

#### Relationships

| Property | Type | Description |
|----------|------|-------------|
| `belongsTo` | string | Related model name for belongsTo relationship (e.g., `User`) |
| `hasOne` | string | Related model name for hasOne relationship |
| `hasMany` | string | Related model name for hasMany relationship |
| `foreignKey` | string | Custom foreign key column name (snake_case) |
| `as` | string | Custom field name for the relationship in Dart (camelCase) |

---

## Field Types

### `int`
Integer values. Use for IDs, counts, etc.

```yaml
id:
  type: int
  primaryKey: true
  autoIncrement: true

age:
  type: int
  min: 0
  max: 150
```

### `string`
Text values. Most common field type.

```yaml
name:
  type: string
  required: true
  min: 2
  max: 255

email:
  type: string
  format: email
  unique: true

slug:
  type: string
  pattern: "^[a-z0-9-]+$"

status:
  type: string
  enum:
    - draft
    - published
    - archived
  default: draft
```

### `bool`
Boolean true/false values.

```yaml
isActive:
  type: bool
  default: true

isVerified:
  type: bool
  default: false
```

### `double`
Floating-point numbers. Use for prices, coordinates, etc.

```yaml
price:
  type: double
  required: true
  min: 0

latitude:
  type: double
  min: -90
  max: 90
```

### `datetime`
Date and time values.

```yaml
publishedAt:
  type: datetime

birthDate:
  type: datetime
  required: true
```

### `json`
JSON objects or arrays. Stored as TEXT in the database.

```yaml
metadata:
  type: json

settings:
  type: json
  default: {}
```

### `list`
List/array values. Stored as JSON in the database.

```yaml
tags:
  type: list

permissions:
  type: list
  default: []
```

---

## Relationships

### belongsTo

Defines a many-to-one relationship. The field stores the foreign key.

```yaml
# In post.yaml
author:
  type: int
  required: true
  belongsTo: User
  foreignKey: author_id  # Optional, defaults to {field}_id
  as: author             # Optional, relationship accessor name
```

Generated code:
```dart
// Foreign key field
int? authorId;

// Relationship accessor
User? get author => _loadedRelations['author'] as User?;
```

### hasOne

Defines a one-to-one relationship.

```yaml
# In user.yaml
profile:
  type: int
  hasOne: Profile
  foreignKey: user_id
```

### hasMany

Defines a one-to-many relationship.

```yaml
# In user.yaml
posts:
  type: int
  hasMany: Post
  foreignKey: user_id
```

---

## Format Validation

The `format` property provides built-in validation patterns for common string formats:

| Format | Description | Pattern |
|--------|-------------|---------|
| `email` | Email addresses | Standard email regex |
| `url` | URLs | Valid HTTP/HTTPS URLs |
| `uuid` | UUIDs | UUID v4 format |
| `phone` | Phone numbers | International phone format |
| `slug` | URL slugs | Lowercase alphanumeric with hyphens |

```yaml
email:
  type: string
  format: email

website:
  type: string
  format: url

externalId:
  type: string
  format: uuid
```

---

## Complete Example

Here's a complete example showing a `Post` model with relationships and various field types:

```yaml
# yaml-language-server: $schema=../../schemas/dash-model.schema.json

model: Post
table: posts
timestamps: true
softDeletes: true

fields:
  id:
    type: int
    primaryKey: true
    autoIncrement: true

  title:
    type: string
    required: true
    min: 1
    max: 255

  slug:
    type: string
    required: true
    unique: true
    pattern: "^[a-z0-9-]+$"

  content:
    type: string

  excerpt:
    type: string
    max: 500

  status:
    type: string
    required: true
    enum:
      - draft
      - published
      - archived
    default: draft

  isPublished:
    type: bool
    default: false

  publishedAt:
    type: datetime

  viewCount:
    type: int
    default: 0

  metadata:
    type: json

  tags:
    type: list
    default: []

  author:
    type: int
    required: true
    belongsTo: User
    foreignKey: author_id
    as: author

  category:
    type: int
    belongsTo: Category
    foreignKey: category_id
```

---

## Generator CLI

### Usage

```bash
dart run dash:generate <schemas_dir> [output_dir]
```

### Arguments

| Argument | Required | Default | Description |
|----------|----------|---------|-------------|
| `schemas_dir` | ✅ | - | Directory containing `.yaml` or `.yml` schema files |
| `output_dir` | ❌ | `lib` | Output directory (models go in `{output_dir}/models/`) |

### Examples

```bash
# Generate from schemas/ to lib/models/
dart run dash:generate schemas lib

# Generate from custom paths
dart run dash:generate database/schemas src

# Generate in current directory
dart run dash:generate ./schemas .
```

### Output

For each schema file, the generator creates a corresponding Dart file:

| Schema | Generated File |
|--------|----------------|
| `schemas/user.yaml` | `lib/models/user.dart` |
| `schemas/blog_post.yaml` | `lib/models/blog_post.dart` |

### Generated Code Features

The generator creates model classes with:

- ✅ Field declarations with proper types and nullability
- ✅ Constructor with required/optional parameters
- ✅ `table` getter for database table name
- ✅ `primaryKey` getter
- ✅ `timestamps` getter
- ✅ `getKey()` / `setKey()` methods
- ✅ `getFields()` method returning column names
- ✅ `toMap()` for serialization
- ✅ `fromMap()` factory for deserialization
- ✅ `copyWith()` for immutable updates
- ✅ Static `query()` method for typed queries
- ✅ `schema` getter for migrations
- ✅ Relationship configuration

---

## IDE Support

### VS Code / Cursor

Add the schema reference to enable autocomplete and validation:

```yaml
# yaml-language-server: $schema=../../schemas/dash-model.schema.json
```

The path is relative to your schema file. Adjust based on your project structure.

### Features

- ✅ Property autocomplete
- ✅ Type validation
- ✅ Enum value suggestions
- ✅ Required field warnings
- ✅ Pattern validation

---

## Best Practices

### 1. Use Meaningful Field Names

```yaml
# ✅ Good
createdAt:
  type: datetime

publishedAt:
  type: datetime

# ❌ Avoid
date1:
  type: datetime
```

### 2. Always Define Primary Keys

```yaml
fields:
  id:
    type: int
    primaryKey: true
    autoIncrement: true
```

### 3. Use Validation Constraints

```yaml
email:
  type: string
  required: true
  format: email
  unique: true

password:
  type: string
  required: true
  min: 8
```

### 4. Define Relationships Explicitly

```yaml
author:
  type: int
  required: true
  belongsTo: User
  foreignKey: author_id
```

### 5. Use Enums for Fixed Values

```yaml
status:
  type: string
  enum:
    - pending
    - approved
    - rejected
  default: pending
```

### 6. Set Sensible Defaults

```yaml
isActive:
  type: bool
  default: true

viewCount:
  type: int
  default: 0
```

---

## Migration from Annotations

If you have existing models using `@DashModel` annotations, you can migrate to YAML schemas:

### Before (Annotations)

```dart
@DashModel()
class User extends Model {
  @PrimaryKey(autoIncrement: true)
  int? id;

  @Column(required: true)
  String name;

  @Column(required: true, unique: true)
  String email;
}
```

### After (YAML Schema)

```yaml
model: User
table: users
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
    required: true
    unique: true
```

Both approaches generate similar code, but YAML schemas are more portable and easier to review.
