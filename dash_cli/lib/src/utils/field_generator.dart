import 'dart:math';

import 'package:dash_panel_cli/src/generators/schema_parser.dart';
import 'package:dash_panel_cli/src/utils/password_utils.dart';
import 'package:faker/faker.dart';

/// Generates fake/default values for schema fields.
///
/// This class extracts the field value generation logic to be shared
/// between db:seed (bulk generation) and db:create (interactive creation).
class FieldGenerator {
  FieldGenerator({Faker? faker, Random? random}) : _faker = faker ?? Faker(), _random = random ?? Random();

  final Faker _faker;
  final Random _random;

  /// Generate a fake value for a field based on its type and constraints.
  ///
  /// [field] - The schema field definition
  /// [modelName] - The model name (for context-aware generation)
  /// [hashPasswords] - Whether to hash password fields with bcrypt (default: true)
  ///
  /// Returns a generated value appropriate for the field, or null if the field
  /// should be skipped (e.g., auto-increment primary key).
  dynamic generateValue(SchemaField field, String modelName, {bool hashPasswords = true}) {
    // Skip primary keys (auto-increment)
    if (field.isPrimaryKey) return null;

    // Skip timestamp fields (let DB handle them)
    if (_isTimestampField(field.name)) return null;

    // Skip hasMany relations (handled separately)
    if (field.relation?.type == 'hasMany' || field.relation?.type == 'hasOne') {
      return null;
    }

    // Handle enum values
    if (field.enumValues != null && field.enumValues!.isNotEmpty) {
      return field.enumValues![_random.nextInt(field.enumValues!.length)];
    }

    // Handle default values (30% chance to use default if available)
    if (field.defaultValue != null && _random.nextDouble() < 0.3) {
      return field.defaultValue;
    }

    // Generate based on field type
    return _generateByType(field, modelName, hashPasswords: hashPasswords);
  }

  /// Generate a default value for interactive prompts.
  ///
  /// Similar to generateValue but always generates a value (no null returns
  /// for optional fields) and formats it for display.
  String generateDefaultForPrompt(SchemaField field, String modelName) {
    final value = _generateByType(field, modelName, hashPasswords: false);
    if (value == null) return '';

    if (value is bool) {
      return value ? 'true' : 'false';
    }
    return value.toString();
  }

  /// Generate a value for a database column based on its info.
  ///
  /// [column] - Column info map with: name, type, nullable, primaryKey, defaultValue
  /// [tableName] - The table name (for context-aware generation)
  /// [hashPasswords] - Whether to hash password fields with bcrypt (default: true)
  ///
  /// Returns a generated value appropriate for the column.
  dynamic generateValueForColumn(Map<String, dynamic> column, String tableName, {bool hashPasswords = true}) {
    final name = column['name'] as String;
    final type = (column['type'] as String?)?.toUpperCase() ?? 'TEXT';
    final isPrimaryKey = column['primaryKey'] as bool? ?? false;
    final defaultValue = column['defaultValue'];

    // Skip primary keys (auto-increment)
    if (isPrimaryKey) return null;

    // Skip timestamp fields (let DB handle them)
    if (_isTimestampColumn(name)) return null;

    // Use default value sometimes (30% chance)
    if (defaultValue != null && _random.nextDouble() < 0.3) {
      return defaultValue;
    }

    // Generate based on SQLite type
    return _generateByColumnType(name, type, hashPasswords: hashPasswords);
  }

  /// Generate a default value for interactive prompts (database column version).
  String generateDefaultForColumnPrompt(Map<String, dynamic> column) {
    final name = column['name'] as String;
    final type = (column['type'] as String?)?.toUpperCase() ?? 'TEXT';
    final value = _generateByColumnType(name, type, hashPasswords: false);
    if (value == null) return '';
    return value.toString();
  }

  /// Parse user input into the appropriate type for a database column.
  ///
  /// [input] - The user's input string
  /// [column] - Column info map
  /// [hashPasswords] - Whether to hash password fields
  ///
  /// Returns the parsed value in the correct type for database storage.
  dynamic parseInputForColumn(String input, Map<String, dynamic> column, {bool hashPasswords = true}) {
    if (input.isEmpty) return null;

    final name = column['name'] as String;
    final type = (column['type'] as String?)?.toUpperCase() ?? 'TEXT';

    // Boolean-like columns (SQLite uses INTEGER for bools) - check first
    if (_isBooleanColumn(name) && type.contains('INT')) {
      final lower = input.toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'y') {
        return 1;
      }
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'n') {
        return 0;
      }
      return null;
    }

    // INTEGER type
    if (type.contains('INT')) {
      return int.tryParse(input);
    }

    // REAL/DOUBLE type
    if (type.contains('REAL') || type.contains('DOUBLE') || type.contains('FLOAT')) {
      return double.tryParse(input);
    }

    // TEXT type - default
    if (name.toLowerCase().contains('password') && hashPasswords && !PasswordUtils.isBcryptHash(input)) {
      return PasswordUtils.hash(input);
    }
    return input;
  }

  bool _isTimestampField(String name) {
    return name == 'createdAt' || name == 'updatedAt' || name == 'deletedAt';
  }

  bool _isTimestampColumn(String name) {
    final lower = name.toLowerCase();
    return lower == 'created_at' || lower == 'updated_at' || lower == 'deleted_at';
  }

  bool _isBooleanColumn(String name) {
    final lower = name.toLowerCase();
    return lower.startsWith('is_') ||
        lower.startsWith('has_') ||
        lower.contains('_is_') ||
        lower.contains('active') ||
        lower.contains('enabled') ||
        lower.contains('published') ||
        lower.contains('deleted') ||
        lower.contains('archived') ||
        lower.contains('hidden') ||
        lower.contains('verified') ||
        lower.contains('default');
  }

  bool _isForeignKeyColumn(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('_id') && lower != 'id';
  }

  dynamic _generateByType(SchemaField field, String modelName, {bool hashPasswords = true}) {
    final name = field.name.toLowerCase();
    final type = field.dartType;

    // String fields - use field name hints
    if (type == 'String') {
      return _generateStringValue(name, field, hashPasswords: hashPasswords);
    }

    // Integer fields
    if (type == 'int') {
      final min = field.min?.toInt() ?? 0;
      final max = field.max?.toInt() ?? 1000;
      return min + _random.nextInt(max - min + 1);
    }

    // Double fields
    if (type == 'double') {
      final min = field.min?.toDouble() ?? 0.0;
      final max = field.max?.toDouble() ?? 1000.0;
      return min + _random.nextDouble() * (max - min);
    }

    // Boolean fields
    if (type == 'bool') {
      return _generateBoolValue(name);
    }

    // DateTime fields
    if (type == 'DateTime') {
      return _generateDateTimeValue(name);
    }

    return null;
  }

  /// Generate value based on SQLite column type.
  dynamic _generateByColumnType(String columnName, String sqliteType, {bool hashPasswords = true}) {
    final name = columnName.toLowerCase();

    // Check for boolean-like INTEGER columns
    if (sqliteType.contains('INT') && _isBooleanColumn(name)) {
      return _generateBoolValue(name) ? 1 : 0;
    }

    // INTEGER type
    if (sqliteType.contains('INT')) {
      return _random.nextInt(1000);
    }

    // REAL/DOUBLE type
    if (sqliteType.contains('REAL') || sqliteType.contains('DOUBLE') || sqliteType.contains('FLOAT')) {
      return _random.nextDouble() * 1000;
    }

    // TEXT type - generate string based on column name hints
    if (sqliteType.contains('TEXT') || sqliteType.contains('VARCHAR') || sqliteType.contains('CHAR')) {
      return _generateStringValueFromColumnName(name, hashPasswords: hashPasswords);
    }

    // BLOB type
    if (sqliteType.contains('BLOB')) {
      return null; // Skip blob fields
    }

    // Default to text generation
    return _generateStringValueFromColumnName(name, hashPasswords: hashPasswords);
  }

  /// Generate string value based on column name pattern recognition.
  String _generateStringValueFromColumnName(String columnName, {bool hashPasswords = true}) {
    // Email fields
    if (columnName.contains('email')) {
      return _faker.internet.email();
    }

    // Name fields
    if (columnName == 'name' || columnName == 'fullname' || columnName == 'full_name') {
      return _faker.person.name();
    }
    if (columnName == 'firstname' || columnName == 'first_name') {
      return _faker.person.firstName();
    }
    if (columnName == 'lastname' || columnName == 'last_name') {
      return _faker.person.lastName();
    }

    // Username
    if (columnName.contains('username') || columnName.contains('user_name')) {
      return _faker.internet.userName();
    }

    // Password - generate and optionally hash
    if (columnName.contains('password')) {
      final plainPassword = _generateSecurePassword();
      if (hashPasswords) {
        return PasswordUtils.hash(plainPassword);
      }
      return plainPassword;
    }

    // Title fields
    if (columnName == 'title') {
      return _faker.lorem.sentence();
    }

    // Slug fields
    if (columnName == 'slug') {
      return _faker.lorem.words(3).join('-').toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    }

    // Content/body/description
    if (columnName == 'content' || columnName == 'body' || columnName == 'text') {
      return _faker.lorem.sentences(_random.nextInt(5) + 3).join(' ');
    }
    if (columnName == 'description' || columnName == 'summary' || columnName == 'excerpt') {
      return _faker.lorem.sentence();
    }

    // URL fields
    if (columnName.contains('url') || columnName.contains('link') || columnName.contains('website')) {
      return _faker.internet.httpsUrl();
    }

    // Avatar/image fields
    if (columnName.contains('avatar') || columnName.contains('image') || columnName.contains('photo')) {
      return 'https://i.pravatar.cc/150?u=${_faker.internet.email()}';
    }

    // Phone fields
    if (columnName.contains('phone') || columnName.contains('mobile') || columnName.contains('tel')) {
      return _faker.phoneNumber.us();
    }

    // Address fields
    if (columnName.contains('address')) {
      return _faker.address.streetAddress();
    }
    if (columnName == 'city') {
      return _faker.address.city();
    }
    if (columnName == 'country') {
      return _faker.address.country();
    }
    if (columnName.contains('zip') || columnName.contains('postal')) {
      return _faker.address.zipCode();
    }

    // Company fields
    if (columnName.contains('company') || columnName.contains('organization')) {
      return _faker.company.name();
    }

    // Color fields
    if (columnName.contains('color')) {
      return '#${_random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }

    // IP address
    if (columnName.contains('ip')) {
      return '${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}';
    }

    // Role/permission fields
    if (columnName == 'role') {
      return ['admin', 'user', 'moderator', 'guest'][_random.nextInt(4)];
    }

    // Default: lorem words
    return _faker.lorem.words(_random.nextInt(3) + 1).join(' ');
  }

  bool _generateBoolValue(String fieldName) {
    // Handle common boolean patterns
    if (fieldName.contains('active') || fieldName.contains('enabled') || fieldName.contains('published')) {
      return _random.nextDouble() < 0.8; // 80% true
    }
    if (fieldName.contains('deleted') || fieldName.contains('archived') || fieldName.contains('hidden')) {
      return _random.nextDouble() < 0.1; // 10% true
    }
    if (fieldName.contains('default')) {
      return _random.nextDouble() < 0.2; // 20% true (for is_default)
    }
    return _random.nextBool();
  }

  String _generateDateTimeValue(String fieldName) {
    final now = DateTime.now();
    if (fieldName.contains('birth') || fieldName.contains('dob')) {
      // Birth date: 18-80 years ago
      return now.subtract(Duration(days: 365 * (18 + _random.nextInt(62)))).toIso8601String();
    }
    // Default: within last year
    return now.subtract(Duration(days: _random.nextInt(365))).toIso8601String();
  }

  String _generateStringValue(String fieldName, SchemaField field, {bool hashPasswords = true}) {
    // Email fields
    if (fieldName.contains('email')) {
      return _faker.internet.email();
    }

    // Name fields
    if (fieldName == 'name' || fieldName == 'fullname' || fieldName == 'full_name') {
      return _faker.person.name();
    }
    if (fieldName == 'firstname' || fieldName == 'first_name') {
      return _faker.person.firstName();
    }
    if (fieldName == 'lastname' || fieldName == 'last_name') {
      return _faker.person.lastName();
    }

    // Username
    if (fieldName.contains('username') || fieldName.contains('user_name')) {
      return _faker.internet.userName();
    }

    // Password - generate and optionally hash
    if (fieldName.contains('password')) {
      final plainPassword = _generateSecurePassword();
      if (hashPasswords) {
        return PasswordUtils.hash(plainPassword);
      }
      return plainPassword;
    }

    // Title fields
    if (fieldName == 'title') {
      return _faker.lorem.sentence();
    }

    // Slug fields
    if (fieldName == 'slug') {
      return _faker.lorem.words(3).join('-').toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]'), '');
    }

    // Content/body/description
    if (fieldName == 'content' || fieldName == 'body' || fieldName == 'text') {
      return _faker.lorem.sentences(_random.nextInt(5) + 3).join(' ');
    }
    if (fieldName == 'description' || fieldName == 'summary' || fieldName == 'excerpt') {
      return _faker.lorem.sentence();
    }

    // URL fields
    if (fieldName.contains('url') || fieldName.contains('link') || fieldName.contains('website')) {
      return _faker.internet.httpsUrl();
    }

    // Avatar/image fields
    if (fieldName.contains('avatar') || fieldName.contains('image') || fieldName.contains('photo')) {
      return 'https://i.pravatar.cc/150?u=${_faker.internet.email()}';
    }

    // Phone fields
    if (fieldName.contains('phone') || fieldName.contains('mobile') || fieldName.contains('tel')) {
      return _faker.phoneNumber.us();
    }

    // Address fields
    if (fieldName.contains('address')) {
      return _faker.address.streetAddress();
    }
    if (fieldName == 'city') {
      return _faker.address.city();
    }
    if (fieldName == 'country') {
      return _faker.address.country();
    }
    if (fieldName.contains('zip') || fieldName.contains('postal')) {
      return _faker.address.zipCode();
    }

    // Company fields
    if (fieldName.contains('company') || fieldName.contains('organization')) {
      return _faker.company.name();
    }

    // Color fields
    if (fieldName.contains('color')) {
      return '#${_random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }

    // IP address
    if (fieldName.contains('ip')) {
      return '${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}.${_random.nextInt(256)}';
    }

    // Default: lorem words with length constraint
    final maxLen = field.max?.toInt() ?? 255;
    final minLen = field.min?.toInt() ?? 1;
    var result = _faker.lorem.words(_random.nextInt(3) + 1).join(' ');

    if (result.length > maxLen) {
      result = result.substring(0, maxLen);
    }
    if (result.length < minLen) {
      result = result.padRight(minLen, 'x');
    }

    return result;
  }

  /// Generate a secure random password.
  String _generateSecurePassword({int length = 16}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Convert a boolean to SQLite integer (0 or 1).
  int boolToSqlite(bool value) => value ? 1 : 0;

  /// Parse user input into the appropriate type for a field.
  ///
  /// [input] - The user's input string
  /// [field] - The schema field definition
  /// [hashPasswords] - Whether to hash password fields
  ///
  /// Returns the parsed value in the correct type for database storage.
  dynamic parseInput(String input, SchemaField field, {bool hashPasswords = true}) {
    if (input.isEmpty) return null;

    final type = field.dartType;
    final name = field.name.toLowerCase();

    switch (type) {
      case 'int':
        return int.tryParse(input);
      case 'double':
        return double.tryParse(input);
      case 'bool':
        final lower = input.toLowerCase();
        if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'y') {
          return 1; // SQLite stores booleans as integers
        }
        if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'n') {
          return 0;
        }
        return null;
      case 'DateTime':
        // Accept various date formats
        final parsed = DateTime.tryParse(input);
        return parsed?.toIso8601String();
      case 'String':
      default:
        // Hash password fields if they're not already hashed
        if (name.contains('password') && hashPasswords && !PasswordUtils.isBcryptHash(input)) {
          return PasswordUtils.hash(input);
        }
        return input;
    }
  }

  /// Check if a column name looks like a foreign key.
  bool isForeignKeyColumn(String columnName) => _isForeignKeyColumn(columnName);
}
