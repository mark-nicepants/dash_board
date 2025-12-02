# Dash - Admin Panel Framework for Dart

## Overview

Dash is a modern, full-featured admin panel framework for Dart, inspired by FilamentPHP. Built on top of Jaspr, it provides a powerful and elegant way to create beautiful admin interfaces for your Dart applications and websites.

### Core Philosophy

- **Easy Integration**: Drop-in solution that can be easily installed in any Dart project
- **Type-Safe**: Leverages Dart's strong typing system for better developer experience
- **Component-Based**: Modular architecture using Jaspr's component system
- **Customizable**: Highly flexible and themeable to match your brand
- **Full-Stack**: Works with any backend (Shelf, Serverpod, etc.)

## Main Functions

### 1. Resource Management
- CRUD operations for database models
- Automatic form generation from model schemas
- Data tables with sorting, filtering, and pagination
- Bulk actions and exports
- Relationship handling (hasMany, belongsTo, manyToMany)

### 2. Form Builder
- Declarative form creation with type-safe field definitions
- Rich set of form components (text, select, date, file upload, rich text, etc.)
- Validation rules and error handling
- Multi-step forms and wizards
- Conditional field visibility

### 3. Table Builder
- Dynamic data tables with server-side operations
- Customizable columns with formatters
- Advanced filtering system
- Search functionality
- Action buttons and bulk operations
- Export capabilities (CSV, Excel, PDF)

### 4. Dashboard & Widgets
- Customizable dashboard layouts
- Pre-built widget library (stats, charts, tables, etc.)
- Real-time data updates
- Drag-and-drop dashboard builder

### 5. Authentication & Authorization
- Built-in authentication system
- Role-based access control (RBAC)
- Permission management
- User profile management
- Multi-tenancy support

### 6. Navigation & Layout
- Flexible navigation system (sidebar, top bar, etc.)
- Breadcrumbs
- Search command palette
- Dark mode support
- Responsive design

### 7. Notifications & Actions
- Toast notifications
- Modal dialogs
- Confirmation prompts
- Action feedback system

## Recent Improvements (November 2025)

### 🗄️ Automatic Database Migrations
- ✅ **Schema Generation from Annotations**: `@DashModel` annotations auto-generate `TableSchema` definitions
- ✅ **Automatic Table Creation**: Detects missing tables and creates them on startup
- ✅ **Column Addition**: Adds missing columns to existing tables without data loss
- ✅ **Database Agnostic**: Abstract `MigrationBuilder`, `SchemaInspector` interfaces
- ✅ **SQLite Implementation**: Full SQLite support with `SqliteMigrationBuilder` and `SqliteSchemaInspector`
- ✅ **Migration Runner**: Orchestrates schema comparison and SQL execution
- ✅ **Type Mapping**: Automatic Dart → SQL type conversion (int→INTEGER, String→TEXT, DateTime→DATETIME, etc.)

### 📊 Table Builder System
- ✅ **Table Class**: Fluent API for configuring data tables
- ✅ **Column Types**: `TextColumn`, `IconColumn`, `BooleanColumn` with full feature set
- ✅ **Sorting**: Configurable sortable columns with default sort and direction
- ✅ **Searching**: Searchable columns with DashWire-powered live search
- ✅ **Pagination**: Configurable records per page with page size options
- ✅ **Column Visibility Toggle**: Alpine.js dropdown with localStorage persistence per resource
- ✅ **Toggleable Columns**: Mark columns as toggleable with optional hidden-by-default
- ✅ **Empty State**: Customizable heading, description, and icon for empty tables
- ✅ **Column Formatting**: Date/time, money, percentage, badge, icon support
- ✅ **Column Alignment**: Start, center, end alignment options
- ✅ **Column Width**: Fixed width or grow to fill available space

### 📝 Form Builder System
- ✅ **FormSchema Class**: Container for form fields with grid layout support
- ✅ **FormField Base Class**: Abstract base with common field behaviors
- ✅ **TextInput Field**: Text, email, password, URL, tel, search variants
- ✅ **Textarea Field**: Multi-line with rows, auto-resize, character count
- ✅ **Select Field**: Dropdown with options, groups, multiple selection
- ✅ **Checkbox Field**: Boolean toggle with accepted validation
- ✅ **Toggle Field**: Styled switch with on/off labels and colors
- ✅ **DatePicker Field**: Date, time, datetime-local with min/max constraints
- ✅ **RelationshipSelect Field**: BelongsTo relationships with async search, preloading
- ✅ **FieldGroup**: Organize fields with collapsible sections
- ✅ **FormRenderer**: Renders form schema with grid layout and buttons
- ✅ **Field Validation**: Required, Email, MinLength, MaxLength, Regex, URL, InList, etc.
- ✅ **Form Operations**: Create, Edit, View modes with appropriate defaults
- ✅ **Column Spanning**: Fields can span multiple columns with breakpoint support

### 🔄 CRUD Operations
- ✅ **ResourceCreate Page**: Form-based create page with breadcrumbs and card layout
- ✅ **ResourceEdit Page**: Pre-populated edit form with record data
- ✅ **Row Actions**: Edit and Delete buttons on each table row
- ✅ **Create Record**: `resource.createRecord(data)` with form data mapping
- ✅ **Update Record**: `resource.updateRecord(record, data)` with model hydration
- ✅ **Delete Record**: `resource.deleteRecord(record)` with confirmation dialog
- ✅ **Form Validation**: Server-side validation with error display
- ✅ **Form Repopulation**: Old input preserved on validation errors
- ✅ **Route Handling**: Full routing for index, create, edit, store, update, delete
- ✅ **Method Spoofing**: PUT/PATCH/DELETE via POST with `_method` field
- ✅ **DashWire Integration**: Wire directives for post-submission redirects

### 🧭 Navigation & Layout
- ✅ **Breadcrumbs Component**: Full breadcrumb navigation with links
- ✅ **Page Header Component**: Title with action buttons
- ✅ **Navigation Groups**: Organized sidebar with collapsible groups
- ✅ **Resource Sorting**: Sort resources within navigation groups
- ✅ **Heroicons Integration**: 300+ generated Heroicon components

### 🎨 UI Components (Tailwind CSS)
- ✅ **Button Component**: Primary, secondary, danger, ghost variants with sizes
- ✅ **Badge Component**: Status indicators with color variants
- ✅ **Card Component**: Container with consistent styling and padding options
- ✅ **Input Component**: Form inputs with labels and validation styling
- ✅ **Form Group**: Layout container for form fields

### 🔐 Authentication System
- ✅ **AuthService**: User authentication with bcrypt password hashing
- ✅ **Session Management**: Secure session tokens with expiration
- ✅ **Login Page**: Styled login form with remember me option
- ✅ **Auth Middleware**: Request authentication with session cookies
- ✅ **Logout Functionality**: Session cleanup and redirect

### 🏗️ Model System
- ✅ **@DashModel Annotation**: Mark classes for code generation
- ✅ **@Column Annotation**: Customize column names and nullability
- ✅ **@PrimaryKey Annotation**: Define primary keys with auto-increment
- ✅ **@BelongsTo/@HasMany Annotations**: Relationship definitions
- ✅ **Code Generator**: Auto-generates `toMap`, `fromMap`, `getFields`, `schema`
- ✅ **ModelQueryBuilder**: Eloquent-style typed query builder
- ✅ **Validation Rules**: Required, Email, MinLength, MaxLength, Numeric, Min, Max, InList
- ✅ **Lifecycle Hooks**: `onCreating`, `onCreated`, `onUpdating`, `onUpdated`, etc.

### ⚙️ Configuration & Developer Experience
- ✅ **Command-line database path**: Support for specifying database directory via CLI args
- ✅ **VS Code integration**: Launch configurations to pass database directory
- ✅ **Resource defaults**: Auto-generate labels from model names
- ✅ **Cleaner resources**: Minimal resource definitions with smart defaults
- ✅ **Service Locator**: Dependency injection for ResourceLoader and other services
- ✅ **Panel Server**: Shelf-based HTTP server with hot reload support

### Example Resource (Minimal):
```dart
class UserResource extends Resource<User> {
  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);

  @override
  String? get navigationGroup => 'Administration';

  @override
  Table<User> table(Table<User> table) {
    return table
        .columns([
          TextColumn.make('id').sortable().width('80px'),
          TextColumn.make('name').searchable().sortable().grow(),
          TextColumn.make('email').searchable().sortable(),
          TextColumn.make('created_at').dateTime().toggleable(isToggledHiddenByDefault: true),
        ])
        .defaultSort('name');
  }

  @override
  FormSchema<User> form(FormSchema<User> form) {
    return form
        .columns(2)
        .fields([
          TextInput.make('name')
              .required()
              .minLength(2)
              .columnSpanFull(),
          TextInput.make('email')
              .email()
              .required(),
          Select.make('role')
              .options([
                SelectOption('user', 'User'),
                SelectOption('admin', 'Administrator'),
                SelectOption('moderator', 'Moderator'),
              ])
              .required(),
          DatePicker.make('created_at')
              .label('Joined')
              .disabled(),
        ]);
  }
  // label, singularLabel, slug auto-derived from User model name!
}
```

### 📄 YAML Schema System (NEW)
- ✅ **JSON Schema Definition**: `dash-model.schema.json` for IDE validation and autocomplete
- ✅ **YAML Model Schemas**: Declarative model definitions in `.yaml` files
- ✅ **Schema Parser**: Parses YAML schemas into `ParsedSchema` objects
- ✅ **Model Generator**: Generates complete Dart model classes from schemas
- ✅ **CLI Tool**: `dart run dash:generate <schemas_dir> [output_dir]`
- ✅ **Field Types**: `int`, `string`, `bool`, `double`, `datetime`, `json`, `list`
- ✅ **Validation Properties**: `required`, `nullable`, `min`, `max`, `pattern`, `format`, `enum`
- ✅ **Format Validation**: `email`, `url`, `uuid`, `phone`, `slug`
- ✅ **Relationships**: `belongsTo`, `hasOne`, `hasMany` with custom `foreignKey` and `as`
- ✅ **Database Properties**: `primaryKey`, `autoIncrement`, `unique`
- ✅ **Model Config**: `timestamps`, `softDeletes`
- ✅ **IDE Support**: Full autocomplete and validation in VS Code/Cursor

See [Model Schema & Generator Documentation](./model-schema-generator.md) for full details.

### 🧩 Widget System (Phase 1 + 2)
- ✅ **Widget Base Class**: Abstract base with `sort`, `columnSpan`, `heading`, `description`, `canView()`, `build()`, `render()`
- ✅ **WidgetConfiguration**: Wrapper class for widget + additional properties
- ✅ **Stat Component**: Fluent API for stat cards with icon, description, trend indicators, sparkline charts
- ✅ **StatsOverviewWidget**: Multi-stat grid widget extending Widget base
- ✅ **Panel.widgets()**: Fluent method to register widgets with panel
- ✅ **DashboardPage Integration**: Renders widgets in 12-column responsive grid
- ✅ **Plugin Widget Support**: Plugins can register widgets via `panel.widgets([])`
- ✅ **Render Hooks**: Dashboard start/end hooks for additional content injection
- ✅ **SVG Sparklines**: Pure SVG sparkline charts in Stat component
- ✅ **ChartWidget**: Chart.js integration for line, bar, pie, doughnut, polar, radar charts
- ✅ **Convenience Chart Widgets**: `LineChartWidget`, `BarChartWidget`, `PieChartWidget`, `DoughnutChartWidget`
- ✅ **ChartData & ChartDataset**: Type-safe chart configuration classes
- ✅ **Dynamic Asset Loading**: `PageAssetCollector` and `AssetProvider` mixin for per-page JS/CSS
- ✅ **Chart.js CDN**: Automatic loading of Chart.js library when charts are used

### 🔌 Plugin System
- ✅ **Plugin Interface**: `getId()`, `register()`, `boot()` lifecycle
- ✅ **NavigationItem**: Custom sidebar navigation with icons, groups, sorting, external links
- ✅ **RenderHook System**: 15+ hook locations for content injection
- ✅ **Asset Registration**: CSS/JS asset loading via plugins
- ✅ **Example Plugin**: AnalyticsPlugin demonstrating widgets, navigation, render hooks

### Example Model with Annotations:
```dart
@DashModel(table: 'users')
class User extends Model with _$UserModelMixin {
  int? id;
  String? name;
  String? email;
  String? role;

  @Column(name: 'created_at')
  DateTime? createdAt;

  @override
  Map<String, List<ValidationRule>> get rules => {
    'name': [Required(), MinLength(2)],
    'email': [Required(), Email()],
    'role': [Required(), InList(['user', 'admin', 'moderator'])],
  };
}
```

## Development Plan

### Phase 1: Foundation (Weeks 1-4)

#### 1.1 Project Structure Setup
- [x] Create documentation folder
- [x] Initialize Dart package structure
- [x] Set up Jaspr as the core framework
- [x] Define project architecture and folder structure
- [x] Create core interfaces and abstract classes (Model, Resource, Panel, Page)
- [x] Set up build system and tooling

#### 1.2 Core Architecture
- [ ] Design plugin/extension system
- [x] Create service container for dependency injection
- [ ] Implement event system for hooks and listeners
- [x] Design configuration system
- [x] Create base Panel class (main entry point)
- [x] Implement routing system integration with Jaspr
- [x] Set up Jaspr server with Shelf handler
- [x] Create server bootstrapping in Panel

#### 1.3 Basic Layout System
- [x] Create base Page component (abstract class)
- [x] Implement Layout component (sidebar, header, content)
- [x] Build Navigation component with group support
- [x] Add navigation group headers
- [x] Implement resource sorting within groups
- [x] Create Breadcrumb component
- [x] Implement basic theme system (CSS-based with Tailwind)
- [ ] Add responsive utilities

### Phase 2: Form & Field System (Weeks 5-8)

#### 2.1 Form Foundation
- [x] Create Form builder class (FormSchema)
- [x] Implement Field abstract class (FormField)
- [x] Build validation system (FieldValidationRule classes)
- [x] Create form state management (fill, getInitialData)
- [x] Implement error handling and display (FormRenderer)
- [x] Add form submission handling (FormRenderer with action/method)

#### 2.2 Basic Form Fields
- [x] TextInput field (with email, password, url, tel variants)
- [x] TextArea field (with auto-resize, character count)
- [x] Select field (with options, groups, placeholder)
- [x] Checkbox field (with accepted validation)
- [ ] Radio field
- [x] Toggle/Switch field (with on/off labels, colors)
- [x] Number input field (via TextInput.numeric())
- [x] DatePicker field (with date, time, datetime-local)

#### 2.3 Advanced Form Fields
- [ ] Rich text editor integration
- [x] File upload component
- [ ] Multi-select with search (Select.multiple().searchable())
- [x] Relationship select (async search) - RelationshipSelect field
- [ ] Repeater field (dynamic lists)
- [ ] Key-value field
- [ ] Color picker
- [ ] Tags input
- [x] FieldGroup (for organizing fields, collapsible)

### Phase 3: Table & Data Display (Weeks 9-12)

#### 3.1 Table Foundation
- [x] Create Table builder class
- [x] Implement Column system (TextColumn, IconColumn, BooleanColumn)
- [x] Build pagination component
- [x] Create sort functionality
- [x] Implement server-side data loading (DashWire)
- [x] Add loading states (DashWire indicators)

#### 3.2 Table Features
- [ ] Filter system architecture
- [x] Search functionality (DashWire live search)
- [ ] Bulk selection
- [ ] Bulk actions
- [x] Column visibility toggle
- [ ] Responsive table view
- [x] Empty state handling (customizable heading, description, icon)

#### 3.3 Advanced Table Features
- [ ] Advanced filters (date ranges, relationships, etc.)
- [ ] Column grouping
- [ ] Summary rows
- [ ] Export functionality (CSV)
- [ ] Saved filter presets
- [ ] Real-time updates (optional)

### Phase 4: Resource System (Weeks 13-16)

#### 4.1 Resource Foundation
- [x] Create Resource abstract class
- [x] Add smart defaults (label, singularLabel derived from model name)
- [x] Add default navigationGroup ('Main')
- [x] Implement navigationSort property
- [x] Build resource registration system
- [x] Implement resource navigation with groups
- [x] Implement resource schema getter (auto-generated)
- [x] Create ModelQueryBuilder for typed queries
- [x] Implement automatic CRUD operations (createRecord, updateRecord, deleteRecord)
- [x] Create resource routes (index, create, edit, store, update, delete)
- [ ] Add resource authorization

#### 4.2 Resource Pages
- [x] List page (with table) - ResourceIndex component with row actions
- [x] Create page (with form) - ResourceCreate component
- [x] Edit page (with form) - ResourceEdit component
- [x] View page (read-only display)
- [ ] Custom actions on pages
- [ ] Page hooks for customization

#### 4.3 Relationships
- [x] Define relationship types (@BelongsTo, @HasMany annotations)
- [ ] HasMany display and management
- [x] BelongsTo select handling (RelationshipSelect field with async search)
- [ ] ManyToMany with pivot tables
- [ ] Relationship eager loading
- [ ] Nested resource creation

### Phase 5: Dashboard & Widgets (Weeks 17-20)

#### 5.1 Dashboard System
- [x] Create Dashboard page (basic)
- [x] Implement widget system (Widget base class, WidgetConfiguration)
- [x] Build grid layout system (12-column responsive grid)
- [x] Add widget positioning (sort property, columnSpan)
- [x] Create dashboard registration (Panel.widgets())

#### 5.2 Core Widgets
- [x] Stats widget (Stat with trends, sparklines)
- [x] StatsOverviewWidget (multi-stat grid)
- [x] Chart widget (line, bar, pie) - Chart.js integration
- [ ] Table widget (embedded resource table)
- [ ] List widget
- [ ] Text/HTML widget
- [x] Custom widget support (extend Widget base class)

#### 5.3 Advanced Features
- [ ] Widget refresh intervals
- [ ] Real-time widget updates
- [ ] Widget filters
- [ ] Widget export
- [ ] Drag-and-drop customization (admin)

### Phase 6: Authentication & Authorization (Weeks 21-24)

#### 6.1 Authentication
- [x] Create Auth provider interface (AuthService)
- [x] Implement login system (bcrypt password hashing)
- [x] Build login page/component
- [x] Add session management (secure tokens with expiration)
- [x] Implement logout functionality
- [x] Auth middleware for protected routes
- [ ] Password reset flow
- [ ] Two-factor authentication (optional)

#### 6.2 Authorization
- [ ] Create Permission system
- [ ] Implement Role system
- [ ] Add resource-level permissions
- [ ] Create policy system
- [ ] Implement gate system for custom checks
- [ ] Add UI elements for permission management

#### 6.3 User Management
- [ ] User resource
- [ ] Role resource
- [ ] Permission resource
- [ ] User profile page

### Phase 7: UI Components & Polish (Weeks 25-28)

#### 7.1 Action System
- [x] Create Action class
- [x] Implement action modals
- [x] Add confirmation dialogs
- [ ] Build action forms
- [ ] Create bulk actions
- [x] Add action notifications

#### 7.2 Notification System
- [x] Toast notifications
- [ ] Notification center
- [ ] Database notifications
- [ ] Real-time notifications (optional)
- [ ] Email notifications integration

#### 7.3 Additional Components
- [x] Modal component
- [ ] Dropdown component
- [ ] Tabs component
- [ ] Accordion component
- [x] Card component
- [x] Badge component
- [ ] Avatar component
- [ ] Command palette (global search)

### Phase 8: Theming & Customization (Weeks 29-32)

#### 8.1 Theme System
- [x] Create theme configuration (Tailwind CSS)
- [x] Implement CSS variable system (dash.css)
- [x] Build default theme (dark theme)
- [x] Add dark mode support (default dark)
- [ ] Create theme builder/customizer
- [ ] Support custom themes

#### 8.2 Customization
- [ ] Logo and branding options
- [ ] Custom colors
- [ ] Font customization
- [ ] Layout customization options
- [ ] Component style overrides

### Phase 9: Developer Experience (Weeks 33-36)

#### 9.1 CLI Tool
- [x] Create schema generator CLI (`dart run dash:generate`)
- [ ] Add `init` command for new panels
- [x] Add `make:resource` command (via generator)
- [ ] Add `make:widget` command
- [ ] Add `make:page` command
- [ ] Add development server command

#### 9.2 Documentation
- [x] Getting started guide (GETTING_STARTED.md)
- [ ] Installation instructions
- [x] Resource documentation (overview-and-plan.md)
- [ ] Form builder documentation
- [ ] Table builder documentation
- [x] Database migrations documentation (database-migrations.md)
- [ ] Widget documentation
- [ ] Theming guide
- [ ] API reference
- [x] Example application (dash_example)

#### 9.3 Testing & Examples
- [x] Create example application
- [ ] Build demo site
- [x] Write unit tests (auth, database, utils)
- [x] Create integration tests (migrations)
- [ ] Performance benchmarks
- [ ] Migration guides

### Phase 10: Advanced Features & Extensions (Weeks 37-40)

#### 10.1 Plugin System
- [x] Finalize plugin architecture (Plugin interface with register/boot lifecycle)
- [ ] Create plugin marketplace concept
- [x] Build example plugins (AnalyticsPlugin)
- [ ] Plugin documentation

#### 10.2 Advanced Features
- [ ] Import/Export system
- [ ] Audit logging
- [ ] Activity timeline
- [ ] Global search
- [ ] Saved filters
- [ ] Report builder
- [ ] Scheduled tasks UI
- [ ] API resource endpoints

#### 10.3 Integrations
- [ ] Shelf middleware integration
- [ ] Serverpod integration helpers
- [ ] Popular Dart ORM adapters
- [ ] File storage adapters (S3, local, etc.)
- [ ] Email service integrations

## Technical Architecture

### Package Structure

```
dash/
├── packages/
│   ├── dash/              # Core framework
│   ├── dash_cli/          # CLI tool
│   ├── dash_forms/        # Form system (could be separate)
│   ├── dash_tables/       # Table system (could be separate)
│   └── dash_widgets/      # Widget library (could be separate)
├── examples/
│   ├── basic_admin/
│   ├── blog_admin/
│   └── ecommerce_admin/
└── docs/
    └── ...
```

### Core Technologies

- **Frontend Framework**: Jaspr (for component-based UI)
- **Styling**: TailwindCSS (via Jaspr integration) or custom CSS
- **State Management**: Built-in with Jaspr signals/state
- **Routing**: Jaspr router
- **HTTP**: shelf or dart:http
- **Database**: Agnostic (support multiple ORMs)

### Key Design Patterns

- **Builder Pattern**: For forms, tables, and resources
- **Factory Pattern**: For field and widget creation
- **Observer Pattern**: For events and hooks
- **Strategy Pattern**: For authentication providers
- **Decorator Pattern**: For middleware and plugins

## Installation Vision

The goal is to make installation as simple as:

```bash
# Add dependency
dart pub add dash

# Initialize panel
dart run dash:init

# Create first resource
dart run dash:make:resource User
```

Then in your application:

```dart
import 'package:dash/dash.dart';

void main() {
  final panel = Panel()
    ..resources([
      UserResource(),
      PostResource(),
    ])
    ..dashboard(CustomDashboard())
    ..theme(DarkTheme());
  
  // Integrate with your server
  runApp(panel);
}
```

## Success Metrics

- Easy to install and get started (< 5 minutes)
- Intuitive API that follows Dart conventions
- Comprehensive documentation
- Active community and plugin ecosystem
- Performance on par with or better than web alternatives
- Type-safety throughout the entire stack

## Next Steps

1. ✅ Create initial documentation
2. Set up the monorepo package structure
3. Initialize the core `dartboard` package with Jaspr
4. Define the base interfaces (Panel, Resource, Form, Table)
5. Create a proof-of-concept with a single resource
6. Iterate and build out Phase 1

---

## Architecture Guidelines

### Do's ✅

#### Fluent Builder Pattern
All configurable classes MUST use method chaining for a consistent, readable API:

```dart
// ✅ DO: Use fluent methods
TextColumn.make('name')
    .label('Full Name')
    .searchable()
    .sortable()
    .grow();

Stat.make('Users', '1,234')
    .icon(HeroIcons.users)
    .description('+12%')
    .chart([10, 15, 20, 25]);
```

#### Factory Methods
Always provide a `make()` static factory method for configurable classes:

```dart
// ✅ DO: Provide make() factory
class TextColumn extends TableColumn {
  static TextColumn make(String name) => TextColumn._(name);
  TextColumn._(this._name);
}

class MyWidget extends Widget {
  static MyWidget make() => MyWidget();
}
```

#### Generic Typing for Fluent Methods
Use generic type parameters in base classes to preserve concrete type through method chains:

```dart
// ✅ DO: Use generics to preserve type
abstract class TableColumn<T extends TableColumn<T>> {
  T label(String label) {
    _label = label;
    return this as T;
  }
}

class TextColumn extends TableColumn<TextColumn> {
  // label() returns TextColumn, not TableColumn
}
```

#### Jaspr Component Conventions
Follow Jaspr patterns for UI components:

```dart
// ✅ DO: Use const constructors, children as list
class MyComponent extends StatelessComponent {
  final String title;
  const MyComponent({required this.title, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'container', [
      h1(classes: 'title', [text(title)]),
    ]);
  }
}
```

#### Separation of Concerns
- **Configuration classes** (Table, FormSchema, Widget) hold settings, not rendering logic
- **Component classes** (ResourceIndex, DashboardPage) handle rendering
- **Service classes** (AuthService, PanelRouter) handle business logic

#### Server-Side Rendering with DashWire
Use DashWire for partial page updates, not SPA patterns:

```dart
// ✅ DO: Use DashWire attributes for interactivity
input(
  attributes: {
    'wire:model.debounce.300ms': 'search',
  },
)
```

#### Alpine.js for Client-Only State
Use Alpine.js for UI state that doesn't need server interaction:

```dart
// ✅ DO: Use Alpine for toggles, dropdowns, modals
div(
  attributes: {'x-data': '{ open: false }'},
  [
    button(attributes: {'@click': 'open = !open'}, [text('Toggle')]),
    div(attributes: {'x-show': 'open'}, [text('Content')]),
  ],
)
```

#### Dependency Injection
Use the service locator for cross-cutting concerns:

```dart
// ✅ DO: Register and inject services
await setupServiceLocator(config: config, connector: connector);
final config = inject<PanelConfig>();
```

### Don'ts ❌

#### Don't Use Constructor Configuration
Avoid configuring through constructors - use fluent methods:

```dart
// ❌ DON'T: Configure via constructor
TextColumn('name', label: 'Full Name', searchable: true, sortable: true);

// ✅ DO: Use fluent API
TextColumn.make('name').label('Full Name').searchable().sortable();
```

#### Don't Hardcode Strings
Use configuration methods or constants:

```dart
// ❌ DON'T: Hardcode
div(classes: 'bg-blue-500 text-white', [...]);

// ✅ DO: Use theme colors
div(classes: 'bg-${panelColors.primary}-500 text-white', [...]);
```

#### Don't Create One-Off Inline Styles
Always use Tailwind CSS classes:

```dart
// ❌ DON'T: Inline styles
div(styles: Styles.raw({'background': 'blue'}), [...]);

// ✅ DO: Use Tailwind classes
div(classes: 'bg-blue-500', [...]);
```

#### Don't Skip the make() Pattern
Even simple configurable classes need factory methods:

```dart
// ❌ DON'T: Only constructor
class MyAction extends Action {
  MyAction(String label) : super(label);
}

// ✅ DO: Provide make() factory
class MyAction extends Action {
  static MyAction make(String label) => MyAction._(label);
  MyAction._(String label) : super(label);
}
```

#### Don't Mix Concerns
Keep rendering, configuration, and logic separate:

```dart
// ❌ DON'T: Mix rendering into configuration class
class Table {
  Component render() { ... } // Configuration shouldn't render
}

// ✅ DO: Separate concerns
class Table { /* configuration only */ }
class DataTable extends StatelessComponent {
  final Table tableConfig;
  Component build() { /* rendering logic */ }
}
```

#### Don't Use SPA Patterns
Avoid client-side routing and state management:

```dart
// ❌ DON'T: Client-side navigation
button(attributes: {'onclick': 'navigate("/users")'}, [...]);

// ✅ DO: Server-side with traditional links
a(href: '/users', [...]);
```

#### Don't Bypass the Panel Registration
Always register components through Panel methods:

```dart
// ❌ DON'T: Direct manipulation
panel._config._widgets.add(myWidget);

// ✅ DO: Use public API
panel.widgets([MyWidget.make()]);
```

### Widget System Guidelines

#### Creating Custom Widgets

```dart
// ✅ Correct widget implementation
class MyStatsWidget extends StatsOverviewWidget {
  static MyStatsWidget make() => MyStatsWidget();

  @override
  int get sort => 1;  // Display order

  @override
  int get columnSpan => 12;  // Full width

  @override
  String? get heading => 'My Statistics';

  @override
  bool canView() => true;  // Authorization check

  @override
  List<Stat> getStats() => [
    Stat.make('Metric', '123')
        .icon(HeroIcons.chartBar)
        .chart([1, 2, 3, 4, 5]),
  ];
}
```

#### Creating Chart Widgets

```dart
// ✅ Line chart widget
class RevenueChartWidget extends LineChartWidget {
  static RevenueChartWidget make() => RevenueChartWidget();

  @override
  int get sort => 10;

  @override
  int get columnSpan => 8;  // Takes 8 of 12 columns

  @override
  String? get heading => 'Monthly Revenue';

  @override
  ChartData getData() => const ChartData(
    labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
    datasets: [
      ChartDataset(
        label: 'Revenue',
        data: [1200, 1900, 3000, 5000, 4000, 6000],
        borderColor: 'rgb(6, 182, 212)',
        tension: 0.3,
      ),
    ],
  );
}

// ✅ Doughnut chart widget
class TrafficChartWidget extends DoughnutChartWidget {
  static TrafficChartWidget make() => TrafficChartWidget();

  @override
  int get columnSpan => 4;

  @override
  String? get heading => 'Traffic Sources';

  @override
  ChartData getData() => const ChartData(
    labels: ['Direct', 'Organic', 'Referral'],
    datasets: [
      ChartDataset(
        label: 'Sources',
        data: [35, 40, 25],
        backgroundColor: [
          'rgb(6, 182, 212)',
          'rgb(139, 92, 246)',
          'rgb(245, 158, 11)',
        ],
      ),
    ],
  );
}
```

#### Dynamic Asset Loading

Widgets can declare required assets via the `AssetProvider` mixin:

```dart
// ✅ Widget with custom assets
class MyMapWidget extends Widget {
  @override
  List<Asset> get requiredAssets => [
    JsAsset.url('mapbox', 'https://cdn.mapbox.com/v2/mapbox-gl.js'),
    CssAsset.url('mapbox', 'https://cdn.mapbox.com/v2/mapbox-gl.css'),
  ];

  @override
  Component build() {
    // Widget can use Mapbox because assets are auto-loaded
    return div(classes: 'h-96', [raw('<div id="map"></div>')]);
  }
}
```

Assets are automatically:
- Collected from all widgets on the page
- Deduplicated by ID
- CSS injected into `<head>`
- JS injected at end of `<body>`

#### Registering Widgets

```dart
// Via Panel directly
panel.widgets([
  MyStatsWidget.make(),
  AnotherWidget.make(),
]);

// Via Plugin
class MyPlugin implements Plugin {
  @override
  void register(Panel panel) {
    panel.widgets([MyStatsWidget.make()]);
  }
}
```

### Plugin System Guidelines

#### Plugin Lifecycle

```dart
class MyPlugin implements Plugin {
  static MyPlugin make() => MyPlugin();

  @override
  String getId() => 'my-plugin';  // Unique identifier

  @override
  void register(Panel panel) {
    // Called immediately during panel.plugin()
    // Register resources, navigation, hooks, widgets
    panel.registerResources([...]);
    panel.navigationItems([...]);
    panel.widgets([...]);
    panel.renderHook(RenderHook.sidebarFooter, () => ...);
  }

  @override
  void boot(Panel panel) {
    // Called during Panel.boot()
    // Runtime initialization, service setup
  }
}
```

#### Render Hook Locations

| Hook | Location |
|------|----------|
| `headStart` / `headEnd` | Document `<head>` |
| `bodyStart` / `bodyEnd` | Document `<body>` |
| `sidebarNavStart` / `sidebarNavEnd` | Sidebar navigation |
| `sidebarFooter` | Above logout button |
| `contentBefore` / `contentAfter` | Main content area |
| `dashboardStart` / `dashboardEnd` | Dashboard page |
| `resourceIndexBefore` / `resourceIndexAfter` | Resource list page |
| `resourceFormBefore` / `resourceFormAfter` | Resource form pages |
| `loginFormBefore` / `loginFormAfter` | Login page |

---

**Note**: This is a living document. Timeline estimates are flexible and will be adjusted based on complexity and feedback during development.
