# Dash - Copilot Instructions

> **Dash** (Dart Admin/System Hub) is a FilamentPHP-inspired admin panel framework for Dart.

## Tech Stack

- **Dart** - Primary language
- **Jaspr** - HTML/SSR component rendering framework
- **HTMX** - Frontend interactivity (search, sorting, pagination, partial page updates)
- **Alpine.js** - Client-side state management (toggles, collapsibles, modals)
- **Tailwind CSS** - Utility-first styling
- **Shelf** - HTTP server

## Core Principles

1. **SOLID Principles** - Follow single responsibility, open/closed, Liskov substitution, interface segregation, and dependency inversion
2. **Fluent Builder APIs** - All configuration uses method chaining for readability
3. **Convention over Configuration** - Smart defaults, minimal required setup
4. **Server-Side Rendering** - HTMX for partial updates, not SPA patterns
5. **Type Safety** - Leverage Dart's type system with generics
6. **Reusable Components** - Create and use Jaspr components for UI elements

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
| Form Fields | Descriptive | `TextInput`, `DatePicker`, `Toggle`, `Select` |

### Methods
| Purpose | Convention | Example |
|---------|------------|---------|
| Getters | `get` prefix | `getLabel()`, `getColumns()`, `getName()` |
| Boolean checks | `is`/`should`/`has` | `isRequired()`, `shouldAutofocus()`, `hasOptions()` |
| Fluent setters | Property name | `label()`, `sortable()`, `required()` |
| Factory methods | `make()` | `TextInput.make('email')` |

### Files
- Use **snake_case** for file names: `text_input.dart`, `query_builder.dart`
- Generated files: `*.g.dart` (e.g., `user.model.g.dart`)
- One primary class per file

### Database
- Column names: **snake_case** (`created_at`, `user_id`)
- Table names: **plural** (`users`, `posts`, `comments`)
- Models auto-convert between camelCase (Dart) and snake_case (DB)

---

## Code Patterns

### 1. Fluent Builder API

All configurable classes use method chaining:

```dart
// ✅ Correct - fluent configuration
table.columns([
  TextColumn.make('name').searchable().sortable().grow(),
  TextColumn.make('email').searchable(),
]).defaultSort('name');

form.columns(2).fields([
  TextInput.make('name').required<TextInput>().minLength(2),
  Select.make('role').options(roleOptions).required<Select>(),
]);
```

### 2. Static Factory Methods

Always provide a `make()` factory method for configurable classes:

```dart
class TextInput extends FormField {
  TextInput(super.name);
  
  /// Factory method - primary way to create instances
  static TextInput make(String name) => TextInput(name);
}
```

### 3. Generic Typing for Fluent Methods

Use generic type parameters to preserve type through chaining:

```dart
// In base class
T required<T extends FormField>() {
  _required = true;
  rule(RequiredRule());
  return this as T;
}

// Usage - type is preserved
TextInput.make('name').required<TextInput>().minLength(2)
```

### 4. Jaspr Components

Extend `StatelessComponent` and implement `build()`:

```dart
class Button extends StatelessComponent {
  final String label;
  final ButtonVariant variant;
  
  const Button({
    required this.label, 
    this.variant = ButtonVariant.primary, 
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return button(
      type: ButtonType.button,
      classes: _getClasses(),
      [text(label)],
    );
  }
  
  String _getClasses() => switch (variant) {
    ButtonVariant.primary => 'px-4 py-2 bg-lime-500 text-white rounded-lg',
    ButtonVariant.secondary => 'px-4 py-2 bg-gray-700 text-gray-300 rounded-lg',
  };
}
```

**Component Rules:**
- Use `const` constructors where possible
- Children go in a list as the last positional argument
- Use `classes` for Tailwind CSS classes
- Use `attributes` map for custom HTML attributes (`hx-*`, `x-*`, `data-*`)
- Use `raw()` for SVG or complex HTML strings

### 5. Resource Definition

```dart
class UserResource extends Resource<User> {
  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);

  @override
  String? get navigationGroup => 'Administration';

  @override
  Table<User> table(Table<User> table) {
    return table.columns([
      TextColumn.make('id').sortable().width('80px'),
      TextColumn.make('name').searchable().sortable().grow(),
      TextColumn.make('email').searchable(),
    ]).defaultSort('name');
  }

  @override
  FormSchema<User> form(FormSchema<User> form) {
    return form.columns(2).fields([
      TextInput.make('name').required<TextInput>().minLength(2),
      TextInput.make('email').email().required<TextInput>(),
    ]);
  }
}
```

### 6. Model Definition with Code Generation

```dart
@DashModel(table: 'users')
class User extends Model with _$UserModelMixin {
  int? id;
  String? name;
  String? email;
  
  @Column(name: 'created_at')
  DateTime? createdAt;
}

// Generated: UserModel.schema, UserModel.query(), toMap(), fromMap()
```

---

## HTMX Patterns

Use HTMX for server-driven interactivity:

```dart
// Search with debounce
input(
  type: InputType.search,
  name: 'search',
  attributes: {
    'hx-get': basePath,
    'hx-trigger': 'keyup changed delay:300ms',
    'hx-target': '#resource-table-container',
    'hx-select': '#resource-table-container',
    'hx-swap': 'outerHTML',
  },
)

// Sorting
a(
  href: '$basePath?sort=$column&direction=asc',
  attributes: {
    'hx-get': '$basePath?sort=$column&direction=asc',
    'hx-target': '#resource-table-container',
    'hx-select': '#resource-table-container',
  },
)

// Form method spoofing (PUT/PATCH)
input(type: InputType.hidden, name: '_method', value: 'PUT')
```

---

## Alpine.js Patterns

Use Alpine for client-side state that doesn't need server interaction:

```dart
// Toggle/Collapsible
div(
  attributes: {'x-data': '{open: false}'},
  [
    button(
      attributes: {'x-on:click': 'open = !open'},
      [text('Toggle')],
    ),
    div(
      attributes: {'x-show': 'open', 'x-collapse': ''},
      [text('Content')],
    ),
  ],
)

// Conditional classes
span(
  attributes: {'x-bind:class': "{'rotate-180': open}"},
  [text('▼')],
)
```

---

## Styling Guidelines

### Color Palette (Dark Theme)
| Purpose | Color |
|---------|-------|
| Primary action | `bg-lime-500`, `hover:bg-lime-600` |
| Secondary action | `bg-gray-700`, `hover:bg-gray-600` |
| Background | `bg-gray-900`, `bg-gray-800` |
| Card/Surface | `bg-gray-800`, `bg-gray-800/50` |
| Text primary | `text-white`, `text-gray-200` |
| Text secondary | `text-gray-400` |
| Borders | `border-gray-700` |
| Error | `text-red-400`, `bg-red-500` |
| Success | `text-green-400`, `bg-green-500` |

### Common Patterns
```dart
// Button primary
'px-4 py-2 text-sm font-medium text-white bg-lime-500 hover:bg-lime-600 rounded-lg transition-colors'

// Button secondary
'px-4 py-2 text-sm font-medium text-gray-300 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors'

// Card
'bg-gray-800 rounded-lg border border-gray-700 p-4'

// Form field container
'space-y-2'

// Grid layouts
'grid grid-cols-1 md:grid-cols-2 gap-4'
```

---

## Form Field Creation

When creating a new form field type:

```dart
class CustomField extends FormField {
  // Private state
  String? _customOption;
  
  CustomField(super.name);
  
  /// Factory method
  static CustomField make(String name) => CustomField(name);
  
  /// Fluent configuration - always return this
  CustomField customOption(String value) {
    _customOption = value;
    return this;
  }
  
  /// Getter for the option
  String? getCustomOption() => _customOption;
  
  @override
  Component build(BuildContext context) {
    return div(classes: 'space-y-2', [
      // Label
      if (getLabel().isNotEmpty)
        label(
          classes: 'block text-sm font-medium text-gray-300',
          attributes: {'for': getName()},
          [
            text(getLabel()),
            if (isRequired()) span(classes: 'text-red-400 ml-1', [text('*')]),
          ],
        ),
      
      // Field input
      // ... your custom field implementation
      
      // Hint text
      if (getHint() != null)
        p(classes: 'text-sm text-gray-500', [text(getHint()!)]),
    ]);
  }
}
```

---

## Table Column Creation

When creating a new table column type:

```dart
class CustomColumn extends TableColumn {
  CustomColumn(super.name);
  
  static CustomColumn make(String name) => CustomColumn(name);
  
  @override
  Component renderCell(dynamic value, Map<String, dynamic> record) {
    // Render the cell content
    return span(classes: 'text-gray-300', [
      text(formatValue(value)),
    ]);
  }
  
  String formatValue(dynamic value) {
    // Custom formatting logic
    return value?.toString() ?? '';
  }
}
```

---

## Testing Guidelines

```dart
import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureName', () {
    late SomeService service;

    setUp(() {
      service = SomeService();
    });

    test('should do something specific', () {
      final result = service.doSomething();
      expect(result, equals(expectedValue));
    });

    test('should handle edge case', () {
      expect(() => service.edgeCase(), throwsA(isA<SomeException>()));
    });
  });
}
```

---

## Do's and Don'ts

### ✅ Do
- Use fluent builder APIs for all configuration
- Provide `make()` factory methods
- Follow the established naming conventions
- Use HTMX for server interactions, Alpine for client-only state
- Create reusable Jaspr components for UI elements
- Write tests for new functionality
- Use generics to preserve types through method chains
- Keep components focused (single responsibility)

### ❌ Don't
- Don't hardcode strings - use configuration methods
- Don't create one-off inline styles - use Tailwind classes
- Don't skip the `make()` factory pattern for configurable classes

---

*Last updated: 2025-11-26*
