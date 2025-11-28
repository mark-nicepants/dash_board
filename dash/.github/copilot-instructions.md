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
| Actions | `<Verb>Action` | `CreateAction`, `EditAction`, `DeleteAction` |
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
- Use `attributes` map for custom HTML attributes (`hx-*`, `x-*`, `data-*`)

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
- Use Heroicons for icons

### ❌ Don't
- Don't hardcode strings - use configuration methods
- Don't create one-off inline styles - use Tailwind classes
- Don't skip the `make()` factory pattern for configurable classes

---

*Last updated: 2025-11-28*
