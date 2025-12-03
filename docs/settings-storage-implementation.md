# Settings Storage Implementation

> Implementation tracking for the Settings Storage feature in Dash

## Status: In Progress

**Started:** December 3, 2025  
**Last Updated:** December 3, 2025

---

## Overview

The Settings Storage system provides a key-value store for application and plugin configuration. This is foundational infrastructure that all plugins need for configuration persistence.

### Goals

1. **Key-value store API** - Simple get/set interface for storing settings
2. **Type-safe setting access** - Strongly typed getters (string, int, bool, json)
3. **Cache layer** - In-memory caching for performance
4. **Dot notation support** - Access nested settings like `app.name`, `mail.smtp.host`

---

## Investigation Notes

### Current Architecture Analysis

**Service Locator Pattern:**
- GetIt-based DI via `inject<T>()` function
- Core services registered in `setupServiceLocator()`: PanelConfig, DatabaseConnector
- Plugins register schemas via `registerModelSchema()` for auto-migration
- Services created and registered as singletons in `Panel.boot()` or plugin `boot()`

**Analytics Plugin Pattern (reference):**
- `register()`: Adds model schemas, dashboard widgets, navigation
- `boot()`: Creates `MetricsService` instance and registers in inject
- Access via `inject<MetricsService>()` throughout codebase

**QueryBuilder CRUD:**
- `QueryBuilder().table('settings').where('key', '=', key).first()` for reads
- `insert(Map<String, dynamic>)` returns inserted ID
- `update(Map<String, dynamic>)` updates matching records
- `delete()` removes matching records

### Design Decisions

1. **No Setting Model** - Use QueryBuilder directly (simpler than full Model class)
2. **Schema Registration** - Register table schema in setupServiceLocator for auto-migration
3. **Singleton Service** - SettingsService registered via inject<SettingsService>()
4. **Eager Cache** - Load all settings on init for fast sync access
5. **Panel Accessor** - Add `settings` getter on Panel for convenience

---

## Implementation Progress

### Phase 1: Investigation
- [x] Analyze service locator pattern in dash
- [x] Review how plugins access panel configuration
- [x] Understand database schema registration
- [x] Identify integration points for settings

### Phase 2: Design
- [x] Design Settings service interface
- [x] Design database schema
- [x] Design caching strategy
- [x] Design plugin integration API

### Phase 3: Implementation
- [ ] Create SettingsService class with schema
- [ ] Add caching layer
- [ ] Integrate with Panel and service locator
- [ ] Export from dash.dart

### Phase 4: Testing
- [ ] Add example settings usage
- [ ] Test via Playwright
- [ ] Write unit tests
- [ ] Update documentation

---

## API Design

### SettingsService

```dart
class SettingsService {
  /// Initialize and load cache
  Future<void> init();
  
  /// Get a setting value with type coercion
  Future<T?> get<T>(String key, {T? defaultValue});
  
  /// Type-safe accessors
  Future<String?> getString(String key, {String? defaultValue});
  Future<int?> getInt(String key, {int? defaultValue});
  Future<bool?> getBool(String key, {bool? defaultValue});
  Future<double?> getDouble(String key, {double? defaultValue});
  Future<Map<String, dynamic>?> getJson(String key, {Map<String, dynamic>? defaultValue});
  Future<List<dynamic>?> getList(String key, {List<dynamic>? defaultValue});
  
  /// Set a setting value (auto-detects type)
  Future<void> set(String key, dynamic value);
  
  /// Check if a setting exists
  Future<bool> has(String key);
  
  /// Delete a setting
  Future<bool> delete(String key);
  
  /// Delete all settings (or by prefix)
  Future<int> clear({String? prefix});
  
  /// Get all settings (optionally filtered by prefix)
  Future<Map<String, dynamic>> all({String? prefix});
  
  /// Bulk set multiple settings
  Future<void> setMany(Map<String, dynamic> settings);
}
```

### Dot Notation Support

Settings keys support dot notation for organization:
- `app.name` 
- `app.debug`
- `mail.driver`
- `mail.smtp.host`
- `mail.smtp.port`

The `all(prefix: 'mail')` method returns all settings starting with 'mail.'.

### Database Schema

```sql
CREATE TABLE settings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  key TEXT NOT NULL UNIQUE,
  value TEXT,
  type TEXT NOT NULL DEFAULT 'string',
  created_at TEXT,
  updated_at TEXT
);

CREATE INDEX idx_settings_key ON settings(key);
```

### Type System

Supported types stored in the `type` column:
- `string` - Plain text
- `int` - Integer numbers
- `double` - Floating point numbers  
- `bool` - Boolean (stored as "true"/"false")
- `json` - JSON encoded objects/arrays

### Caching Strategy
- In-memory cache using `Map<String, _CachedSetting>`
- Cache populated eagerly on `init()`
- Cache invalidated on `set()`, `delete()`, `clear()`
- Sync access possible after init via cache

### Usage Pattern
```dart
// In a resource or page
final settings = inject<SettingsService>();
final appName = await settings.getString('app.name', defaultValue: 'Dash');
final debug = await settings.getBool('app.debug', defaultValue: false);

// Set a value
await settings.set('app.timezone', 'UTC');

// Set multiple values
await settings.setMany({
  'mail.driver': 'smtp',
  'mail.smtp.host': 'localhost',
  'mail.smtp.port': 587,
});
```

---

## Files to Create/Modify

### New Files
1. `lib/src/settings/settings_service.dart` - Core settings service with schema
2. `test/settings/settings_service_test.dart` - Unit tests

### Modified Files
1. `lib/src/panel/panel.dart` - Add settings accessor, create service in boot()
2. `lib/src/service_locator.dart` - Register settings schema for auto-migration
3. `lib/dash.dart` - Export SettingsService

---

## Notes

- Following analytics plugin pattern for service registration
- Schema registered in service_locator for auto-migration
- Service created in Panel.boot() after database is ready
- Access via inject<SettingsService>() or panel.settings
