# Dash - Copilot Instructions

> **Dash** (Dart Admin/System Hub) is a FilamentPHP-inspired admin panel framework for Dart.

## Quick Reference

**What is Dash?** A server-side rendered admin panel framework for Dart, inspired by FilamentPHP. It provides CRUD operations, forms, tables, and authentication out of the box.

**Key Concepts:**
- **Resource** = Model + Table + Form (defines how an entity is managed in the admin)
- **Model** = Active Record ORM with fluent query builder
- **FormField** = Input component with `dehydrateValue()` for DB conversion and `hydrateValue()` for display
- **Panel** = The main app orchestrator

**Running the Example:**
```bash
cd /path/to/dash && dart run example/lib/main.dart
```
- Server runs on `http://localhost:8080`
- If needed login: `admin@example.com` / `password` (from `example/lib/commands/seed_commands.dart`)
- Sessions are saved between server restarts. So a simple refresh of the page after a restart should keep you logged in.
- **Database location**: `storage/app.db` (relative to where the app runs, NOT in `example/storage/`)

**Code Generation:**
```bash
cd /path/to/dash && dart run bin/generate.dart example/schemas/models example/lib
```
- Pass the **directory** containing schema YAML files (not individual files)
- Second argument is the output directory for generated code

---

## Development Workflow

### Running & Testing with Playwright

When fixing bugs or testing features interactively:

1. **Start the server** (background process):
   ```bash
   lsof -ti :8080 | xargs kill -9 2>/dev/null; sleep 1
   cd /path/to/dash && dart run example/lib/main.dart
   ```

2. **Use Playwright browser tools** to navigate and interact:
   - Navigate: `browser_navigate` to `http://localhost:8080/admin/login`
   - Fill forms: `browser_fill_form` or `browser_type`
   - Click: `browser_click` with element ref
   - Take snapshots: `browser_snapshot` to see current page state

3. **Login credentials**: `admin@example.com` / `password`

4. **After code changes**, restart the server to pick up changes
note: Sessions are saved between server restarts. So a simple refresh of the page after a restart should keep you logged in.

### Bug Fixing Approach

1. **Reproduce the bug** - Use Playwright to navigate and trigger the issue
2. **Check the logs** - Read `storage/logs/dash_YYYYMMDD.log` for errors and debug info
3. **Add debug output** - Print statements in key locations (router, resource methods)
4. **Trace the flow** - Follow data through: Form submission → Resource → Model → Database
5. **Identify the layer** - Is it presentation, application, domain, or infrastructure?
6. **Fix at the right level** - Each layer has specific responsibilities:
   - **FormField.dehydrateValue()** - Type conversion for database storage
   - **FormField.hydrateValue()** - Value transformation for display
   - **Resource._applyDataToModel()** - Maps form fields to model properties
   - **Model.fromMap()/toMap()** - Database serialization
7. **Test the fix** - Use Playwright to verify, then write unit tests
8. **Clean up debug output** - Remove print statements before committing

### Reading Application Logs

Dash writes logs to daily log files in `storage/logs/`. Always check these logs when debugging:

```bash
# Read today's logs
cat storage/logs/dash_$(date +%Y%m%d).log

# Tail the logs for real-time monitoring
tail -f storage/logs/dash_$(date +%Y%m%d).log

# Search for errors
grep -i error storage/logs/dash_*.log

# Show last 50 lines of today's log
tail -50 storage/logs/dash_$(date +%Y%m%d).log
```

**Log format:** `[YYYY-MM-DD HH:MM:SS] [LEVEL  ] message`

**Log levels:** `debug`, `info`, `warning`, `error`, `request`, `query`

The logs contain:
- HTTP request/response info (method, path, status code, duration)
- Database queries (when query logging is enabled)
- Errors and exceptions
- Application events

### Field Value Conversion

Each form field type is responsible for its own type conversion via `dehydrateValue()`:
- **Toggle/Checkbox** → converts strings ("true", "1", "on") to boolean
- **DatePicker** → converts ISO strings to DateTime
- **Select (multiple)** → ensures value is a List
- **RelationshipSelect** → uses model schema to determine foreign key type (int/text)
- **HasManySelect** → returns `List<int>` of related IDs for pivot table sync

### Relationships

**BelongsTo** (many-to-one):
- Foreign key stored in the model's table
- Use `RelationshipSelect` in forms
- Load via `model.loadRelationship(name, foreignKeyValue)`

**HasMany** (many-to-many via pivot):
- Data stored in a pivot table (e.g., `post_tag`)
- Use `HasManySelect` in forms
- Pivot tables are auto-migrated when defined in model schema
- Resource class handles sync via `_syncHasManyRelationships()`
- Form loading uses `fillAsync()` to query pivot table for existing IDs

---

## Tech Stack

- **Dart** - Primary language
- **Jaspr** - HTML/SSR component rendering framework
- **Alpine.js** - Client-side state management (toggles, collapsibles, modals)
- **Tailwind CSS** - Utility-first styling
- **Shelf** - HTTP server

## Core Principles

1. **SOLID Principles** - Follow single responsibility, open/closed, Liskov substitution, interface segregation, and dependency inversion
2. **Fluent Builder APIs** - All configuration uses method chaining for readability
3. **Convention over Configuration** - Smart defaults, minimal required setup
4. **Server-Side Rendering** - Full page renders with traditional navigation
5. **Type Safety** - Leverage Dart's type system with generics
6. **Reusable Components** - Create and use Jaspr components for UI elements
7. **Fields Own Their Conversion** - Each FormField type handles its own value conversion in `dehydrateValue()`

---

## Architecture Overview

### Layered Architecture

Dash follows a layered architecture with clear separation of concerns:

1. **Presentation Layer** - Jaspr components for rendering HTML
2. **Application Layer** - Panel, Router, and Request handling
3. **Domain Layer** - Resources, Models, and business logic
4. **Infrastructure Layer** - Database connectors, storage, and external services

### Core Domain Concepts

- **Panel** - The central orchestrator that configures and runs the admin interface
- **Resource** - Represents a model/entity with CRUD operations, tied to table and form configurations
- **Model** - Active Record pattern ORM with fluent query builder
- **Table** - Declarative configuration for list views with columns and actions
- **FormSchema** - Declarative configuration for create/edit forms with fields and validation
- **Action** - Reusable interactive elements for navigation and server-side operations

### Dependency Flow

Panel orchestrates Resources, which use Table, FormSchema, and Actions for UI configuration. Resources depend on Models, which use QueryBuilder to interact with DatabaseConnector. Validation Rules are applied at the form field level.

### Service Locator Pattern

Use GetIt-based dependency injection via `inject<T>()`:
- Register singletons during `Panel.boot()`
- Access `PanelConfig`, `DatabaseConnector`, `StorageManager` globally
- Register resource factories with `registerResourceFactory<Model>()`

---

## Project Structure

```
dash/lib/src/
├── auth/           # Authentication (sessions, bcrypt, middleware)
├── components/     # Jaspr UI components
│   ├── layout.dart # Main admin layout
│   ├── pages/      # Full page components (ResourceIndex, ResourceEdit, etc.)
│   └── partials/   # Reusable UI elements (Button, Badge, Card, etc.)
├── database/       # Database layer (connectors, query builder, migrations)
├── form/           # Form builder system
│   ├── form_schema.dart
│   └── fields/     # Field types (TextInput, Select, Toggle, etc.)
├── generators/     # Code generation (model generator)
├── model/          # ORM layer (Model base, annotations, query builder)
├── panel/          # Admin panel core (router, server, config)
├── plugin/         # Plugin system
│   ├── plugin.dart # Plugin interface
│   ├── render_hook.dart # Render hooks for content injection
│   ├── navigation_item.dart # Custom navigation items
│   └── asset.dart  # CSS/JS asset management
├── resources/      # Resource loading utilities
├── table/          # Table builder system
│   └── columns/    # Column types (TextColumn, BooleanColumn, etc.)
├── utils/          # Utilities (sanitization)
├── validation/     # Validation rules
├── resource.dart   # Base Resource class
└── service_locator.dart  # GetIt-based dependency injection
```

---

## Naming Conventions

### Classes
| Type | Pattern | Example |
|------|---------|---------|
| Resources | `<Model>Resource` | `UserResource`, `PostResource` |
| Models | Singular noun | `User`, `Post`, `Comment` |
| Components | Descriptive | `DashLayout`, `ResourceIndex`, `PageHeader` |
| Table Columns | `<Type>Column` | `TextColumn`, `BooleanColumn`, `IconColumn` |
| Form Fields | Descriptive | `TextInput`, `DatePicker`, `Toggle`, `Select`, `HasManySelect` |
| Actions | `<Verb>Action` | `CreateAction`, `EditAction`, `DeleteAction` |
| Plugins | `<Name>Plugin` | `BlogPlugin`, `AnalyticsPlugin` |
| Validation Rules | Descriptive noun | `Required`, `Email`, `MinLength`, `Pattern` |

### Methods
| Purpose | Convention | Example |
|---------|------------|---------|
| Getters | `get` prefix | `getLabel()`, `getColumns()`, `getName()` |
| Boolean checks | `is`/`should`/`has` | `isRequired()`, `shouldAutofocus()`, `hasOptions()` |
| Fluent setters | Property name | `label()`, `sortable()`, `required()` |
| Factory methods | `make()` | `TextInput.make('email')` |
| Build methods | `build` prefix | `buildIndexPage()`, `buildCreatePage()` |

### Files
- Use **snake_case** for file names: `text_input.dart`, `query_builder.dart`
- Generated files: `*.g.dart` (e.g., `user.model.g.dart`)
- One primary class per file

### Database
- Column names: **snake_case** (`created_at`, `user_id`)
- Table names: **plural** (`users`, `posts`, `comments`)
- Pivot table names: **singular_singular** alphabetically sorted (`post_tag`, not `tag_post`)
- Models auto-convert between camelCase (Dart) and snake_case (DB)

---

## Component Architecture

### Component Hierarchy

- **Layout Components** - Page wrappers with navigation (`DashLayout`)
- **Page Components** - Full pages (`ResourceIndex`, `ResourceForm`, `ResourceView`)
- **Partial Components** - Reusable UI elements (`Button`, `Badge`, `Card`, `PageHeader`)
- **Form Components** - Input wrappers with styling and validation feedback

### Component Composition

Build complex UIs by composing smaller components:
- Pages compose layout + partials + form/table renderers
- Partials are self-contained with their own styling logic
- Use enums for variants rather than string-based configuration

---

## Code Patterns

### 1. Fluent Builder API

All configurable classes use method chaining. Configure tables and forms by chaining methods like `columns()`, `searchable()`, `sortable()`, `required()`, and `defaultSort()`.

### 2. Static Factory Methods

Always provide a `make()` factory method for configurable classes. This is the primary way to create instances and enables the fluent API pattern.

### 3. Generic Typing for Fluent Methods

Use generic type parameters in base class methods to preserve the concrete type through method chaining. Return `this as T` to maintain type safety.

### 4. Jaspr Components

Extend `StatelessComponent` and implement `build()`. Use `const` constructors, pass children as list arguments, and apply Tailwind classes via the `classes` parameter.

**Component Rules:**
- Use `const` constructors where possible
- Children go in a list as the last positional argument
- Use `classes` for Tailwind CSS classes
- Use `attributes` map for custom HTML attributes (`x-*`, `data-*`)

### 5. Resource Pattern

Resources bridge models to the admin UI:
- Override `table()` to configure list view columns, sorting, and actions
- Override `form()` to configure create/edit fields and validation
- Override action hooks (`indexHeaderActions`, `formActions`) for custom behaviors
- Resources own CRUD operations (`getRecords`, `createRecord`, `updateRecord`, `deleteRecord`)

### 6. Model Pattern (Active Record)

Models represent database entities:
- Extend `Model` base class
- Implement `table`, `toMap()`, `fromMap()`, `getKey()`, `setKey()`
- Use static `query()` method for fluent query building
- Support timestamps, soft deletes, and relationships via mixins

### 7. Validation Pattern

Validation rules are composable classes:
- Each rule extends `ValidationRule` with `name` and `validate()`
- Fields collect rules via `.rule()` method or convenience methods (`.required()`, `.email()`)
- Validation runs through `FormSchema.validate()` returning field → error maps

### 8. Query Builder Pattern

Fluent interface for database operations:
- Chain methods: `where()`, `orderBy()`, `limit()`, `offset()`
- Execute with: `get()`, `first()`, `count()`, `insert()`, `update()`, `delete()`
- `ModelQueryBuilder` wraps base builder to return typed model instances

### 9. Plugin Pattern

Plugins extend panel functionality with a two-phase lifecycle:

**Plugin Interface:**
```dart
class MyPlugin implements Plugin {
  static MyPlugin make() => MyPlugin();
  
  @override
  String getId() => 'my-plugin';
  
  @override
  void register(Panel panel) {
    // Called immediately - configure resources, navigation, hooks
    panel.registerResources([...]);
    panel.navigationItems([...]);
    panel.renderHook(RenderHook.sidebarFooter, () => ...);
  }
  
  @override
  void boot(Panel panel) {
    // Called during Panel.boot() - runtime initialization
  }
}
```

**Plugin Capabilities:**
- Register resources via `panel.registerResources()`
- Add navigation items via `panel.navigationItems()`
- Inject content via `panel.renderHook()`
- Load assets via `panel.assets()`
- Access panel config during boot

**Render Hooks:** `sidebarNavStart`, `sidebarNavEnd`, `sidebarFooter`, `contentBefore`, `contentAfter`, `dashboardStart`, `dashboardEnd`, etc.

### 10. Form Data Parsing

The router parses form submissions with support for array fields:
- Standard fields: `field=value`
- Array fields: `field[]=value1&field[]=value2` → collected into a `List`
- Used by multi-select fields like `HasManySelect`

---



## Do's and Don'ts

### ✅ Do
- Use fluent builder APIs for all configuration
- Provide `make()` factory methods
- Follow the established naming conventions
- Use Alpine.js for client-side interactivity
- Create reusable Jaspr components for UI elements
- Write tests for new functionality
- Use generics to preserve types through method chains
- Keep components focused (single responsibility)
- Use Heroicons for icons
- Put type conversion logic in `dehydrateValue()` on field classes
- Use Playwright for interactive testing and bug reproduction

### ❌ Don't
- Don't hardcode strings - use configuration methods
- Don't create one-off inline styles - use Tailwind classes
- Don't skip the `make()` factory pattern for configurable classes
- Don't put field type conversion logic in Resource - fields own their conversion
- Don't assume foreign key types - use model schema to determine column types
- Don't use Dart mirrors/reflection - use direct method calls or fallback patterns

---

*Last updated: 2025-12-03*
