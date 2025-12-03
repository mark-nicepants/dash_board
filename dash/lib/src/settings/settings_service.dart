import 'dart:convert';

import 'package:dash/src/database/database_connector.dart';
import 'package:dash/src/database/migrations/schema_definition.dart';
import 'package:dash/src/database/query_builder.dart';
import 'package:dash/src/service_locator.dart';

/// A cached setting with its value and type.
class _CachedSetting {
  final dynamic value;
  final String type;

  _CachedSetting(this.value, this.type);
}

/// A key-value store for application and plugin settings.
///
/// Provides type-safe access to settings with caching and dot notation support.
///
/// Example:
/// ```dart
/// final settings = inject<SettingsService>();
///
/// // Get values with type safety
/// final appName = await settings.getString('app.name', defaultValue: 'Dash');
/// final debug = await settings.getBool('app.debug', defaultValue: false);
///
/// // Set values (type auto-detected)
/// await settings.set('app.timezone', 'UTC');
/// await settings.set('app.max_users', 100);
///
/// // Bulk operations
/// await settings.setMany({
///   'mail.driver': 'smtp',
///   'mail.host': 'localhost',
/// });
///
/// // Get all settings with a prefix
/// final mailSettings = await settings.all(prefix: 'mail.');
/// ```
class SettingsService {
  final DatabaseConnector _connector;
  final Map<String, _CachedSetting> _cache = {};
  bool _initialized = false;

  /// The table name for settings storage.
  static const String tableName = 'settings';

  /// Creates a new SettingsService instance.
  SettingsService(this._connector);

  /// Creates a new SettingsService instance using the injected DatabaseConnector.
  factory SettingsService.create() {
    return SettingsService(inject<DatabaseConnector>());
  }

  /// Returns the schema definition for the settings table.
  ///
  /// This should be registered with the service locator for auto-migration.
  static TableSchema get schema => const TableSchema(
    name: tableName,
    columns: [
      ColumnDefinition(name: 'id', type: ColumnType.integer, isPrimaryKey: true, autoIncrement: true),
      ColumnDefinition(name: 'key', type: ColumnType.text, nullable: false, unique: true),
      ColumnDefinition(name: 'value', type: ColumnType.text, nullable: true),
      ColumnDefinition(name: 'type', type: ColumnType.text, nullable: false, defaultValue: "'string'"),
      ColumnDefinition(name: 'created_at', type: ColumnType.text, nullable: true),
      ColumnDefinition(name: 'updated_at', type: ColumnType.text, nullable: true),
    ],
    indexes: [
      IndexDefinition(name: 'idx_settings_key', columns: ['key']),
    ],
  );

  /// Initializes the service and loads all settings into cache.
  ///
  /// This should be called during Panel boot after database migrations.
  Future<void> init() async {
    if (_initialized) return;

    await _loadCache();
    _initialized = true;
  }

  /// Loads all settings from the database into the cache.
  Future<void> _loadCache() async {
    _cache.clear();

    final results = await QueryBuilder(_connector).table(tableName).get();

    for (final row in results) {
      final key = row['key'] as String;
      final rawValue = row['value'] as String?;
      final type = row['type'] as String? ?? 'string';

      _cache[key] = _CachedSetting(_deserializeValue(rawValue, type), type);
    }
  }

  /// Deserializes a value from its stored string representation.
  dynamic _deserializeValue(String? rawValue, String type) {
    if (rawValue == null) return null;

    switch (type) {
      case 'int':
        return int.tryParse(rawValue);
      case 'double':
        return double.tryParse(rawValue);
      case 'bool':
        return rawValue.toLowerCase() == 'true';
      case 'json':
        try {
          return jsonDecode(rawValue);
        } catch (_) {
          return null;
        }
      case 'string':
      default:
        return rawValue;
    }
  }

  /// Serializes a value to a string for storage.
  String? _serializeValue(dynamic value) {
    if (value == null) return null;
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }

  /// Detects the type of a value for storage.
  String _detectType(dynamic value) {
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is Map || value is List) return 'json';
    return 'string';
  }

  /// Gets a setting value with optional default.
  ///
  /// Returns the value cast to type [T], or [defaultValue] if not found.
  ///
  /// Example:
  /// ```dart
  /// final name = await settings.get<String>('app.name', defaultValue: 'Dash');
  /// final port = await settings.get<int>('server.port', defaultValue: 8080);
  /// ```
  Future<T?> get<T>(String key, {T? defaultValue}) async {
    await _ensureInitialized();

    final cached = _cache[key];
    if (cached == null) return defaultValue;

    final value = cached.value;
    if (value is T) return value;

    return defaultValue;
  }

  /// Gets a string setting value.
  ///
  /// Example:
  /// ```dart
  /// final appName = await settings.getString('app.name', defaultValue: 'Dash');
  /// ```
  Future<String?> getString(String key, {String? defaultValue}) async {
    await _ensureInitialized();

    final cached = _cache[key];
    if (cached == null) return defaultValue;

    final value = cached.value;
    if (value == null) return defaultValue;

    return value.toString();
  }

  /// Gets an integer setting value.
  ///
  /// Example:
  /// ```dart
  /// final maxUsers = await settings.getInt('app.max_users', defaultValue: 100);
  /// ```
  Future<int?> getInt(String key, {int? defaultValue}) async {
    await _ensureInitialized();

    final cached = _cache[key];
    if (cached == null) return defaultValue;

    final value = cached.value;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  /// Gets a double setting value.
  ///
  /// Example:
  /// ```dart
  /// final rate = await settings.getDouble('app.tax_rate', defaultValue: 0.21);
  /// ```
  Future<double?> getDouble(String key, {double? defaultValue}) async {
    await _ensureInitialized();

    final cached = _cache[key];
    if (cached == null) return defaultValue;

    final value = cached.value;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;

    return defaultValue;
  }

  /// Gets a boolean setting value.
  ///
  /// Example:
  /// ```dart
  /// final debug = await settings.getBool('app.debug', defaultValue: false);
  /// ```
  Future<bool?> getBool(String key, {bool? defaultValue}) async {
    await _ensureInitialized();

    final cached = _cache[key];
    if (cached == null) return defaultValue;

    final value = cached.value;
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true' || value == '1') return true;
      if (value.toLowerCase() == 'false' || value == '0') return false;
    }
    if (value is num) return value != 0;

    return defaultValue;
  }

  /// Gets a JSON setting value as a Map.
  ///
  /// Example:
  /// ```dart
  /// final config = await settings.getJson('app.config', defaultValue: {});
  /// ```
  Future<Map<String, dynamic>?> getJson(String key, {Map<String, dynamic>? defaultValue}) async {
    await _ensureInitialized();

    final cached = _cache[key];
    if (cached == null) return defaultValue;

    final value = cached.value;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }

    return defaultValue;
  }

  /// Gets a JSON setting value as a List.
  ///
  /// Example:
  /// ```dart
  /// final items = await settings.getList('app.features', defaultValue: []);
  /// ```
  Future<List<dynamic>?> getList(String key, {List<dynamic>? defaultValue}) async {
    await _ensureInitialized();

    final cached = _cache[key];
    if (cached == null) return defaultValue;

    final value = cached.value;
    if (value is List) return value;
    if (value is String) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) return decoded;
      } catch (_) {}
    }

    return defaultValue;
  }

  /// Sets a setting value.
  ///
  /// The value type is auto-detected for storage.
  ///
  /// Example:
  /// ```dart
  /// await settings.set('app.name', 'My App');
  /// await settings.set('app.debug', true);
  /// await settings.set('app.max_users', 100);
  /// await settings.set('app.config', {'key': 'value'});
  /// ```
  Future<void> set(String key, dynamic value) async {
    await _ensureInitialized();

    final type = _detectType(value);
    final serialized = _serializeValue(value);
    final now = DateTime.now().toIso8601String();

    // Check if exists
    final existing = await QueryBuilder(_connector).table(tableName).where('key', '=', key).first();

    if (existing != null) {
      // Update
      await QueryBuilder(
        _connector,
      ).table(tableName).where('key', '=', key).update({'value': serialized, 'type': type, 'updated_at': now});
    } else {
      // Insert
      await QueryBuilder(
        _connector,
      ).table(tableName).insert({'key': key, 'value': serialized, 'type': type, 'created_at': now, 'updated_at': now});
    }

    // Update cache
    _cache[key] = _CachedSetting(value, type);
  }

  /// Sets multiple settings at once.
  ///
  /// Example:
  /// ```dart
  /// await settings.setMany({
  ///   'mail.driver': 'smtp',
  ///   'mail.host': 'localhost',
  ///   'mail.port': 587,
  /// });
  /// ```
  Future<void> setMany(Map<String, dynamic> values) async {
    for (final entry in values.entries) {
      await set(entry.key, entry.value);
    }
  }

  /// Checks if a setting exists.
  ///
  /// Example:
  /// ```dart
  /// if (await settings.has('app.api_key')) {
  ///   // Use API key
  /// }
  /// ```
  Future<bool> has(String key) async {
    await _ensureInitialized();
    return _cache.containsKey(key);
  }

  /// Deletes a setting.
  ///
  /// Returns true if the setting existed and was deleted.
  ///
  /// Example:
  /// ```dart
  /// await settings.delete('app.deprecated_setting');
  /// ```
  Future<bool> delete(String key) async {
    await _ensureInitialized();

    final rows = await QueryBuilder(_connector).table(tableName).where('key', '=', key).delete();

    _cache.remove(key);

    return rows > 0;
  }

  /// Deletes all settings, optionally filtered by prefix.
  ///
  /// Returns the number of settings deleted.
  ///
  /// Example:
  /// ```dart
  /// // Delete all mail settings
  /// await settings.clear(prefix: 'mail.');
  ///
  /// // Delete all settings
  /// await settings.clear();
  /// ```
  Future<int> clear({String? prefix}) async {
    await _ensureInitialized();

    int deleted;

    if (prefix != null) {
      // Use LIKE for prefix matching
      deleted = await QueryBuilder(_connector).table(tableName).where('key', 'LIKE', '$prefix%').delete();

      // Remove from cache
      _cache.removeWhere((key, _) => key.startsWith(prefix));
    } else {
      deleted = await QueryBuilder(_connector).table(tableName).delete();
      _cache.clear();
    }

    return deleted;
  }

  /// Gets all settings, optionally filtered by prefix.
  ///
  /// Returns a map of key-value pairs.
  ///
  /// Example:
  /// ```dart
  /// // Get all mail settings
  /// final mailSettings = await settings.all(prefix: 'mail.');
  ///
  /// // Get all settings
  /// final allSettings = await settings.all();
  /// ```
  Future<Map<String, dynamic>> all({String? prefix}) async {
    await _ensureInitialized();

    final result = <String, dynamic>{};

    for (final entry in _cache.entries) {
      if (prefix == null || entry.key.startsWith(prefix)) {
        result[entry.key] = entry.value.value;
      }
    }

    return result;
  }

  /// Reloads the cache from the database.
  ///
  /// This is useful if settings were modified directly in the database.
  Future<void> refresh() async {
    await _loadCache();
  }

  /// Ensures the service is initialized before use.
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await init();
    }
  }
}
