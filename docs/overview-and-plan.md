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

### Configuration & Developer Experience
- ✅ **Command-line database path**: Added support for specifying database directory via CLI args
- ✅ **VS Code integration**: Updated launch configurations to pass database directory
- ✅ **Resource defaults**: Auto-generate labels from model names, reducing boilerplate
- ✅ **Navigation groups**: Organized sidebar navigation with collapsible groups
- ✅ **Cleaner resources**: Minimal resource definitions with smart defaults
- ✅ **Column visibility toggles**: Alpine.js-powered dropdown with client-side persistence per resource

### Example Resource Before:
```dart
class UserResource extends Resource<User> {
  @override
  Type get model => User;
  @override
  String get label => 'Users';
  @override
  String get singularLabel => 'User';
  @override
  String? get navigationGroup => 'Administration';
  @override
  int get navigationSort => 1;
  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);
}
```

### Example Resource After:
```dart
class UserResource extends Resource<User> {
  @override
  Type get model => User;
  @override
  Heroicon get iconComponent => const Heroicon(HeroIcons.userGroup);
  @override
  String? get navigationGroup => 'Administration';
  // label and singularLabel auto-derived from User model name!
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
- [ ] Create service container for dependency injection
- [ ] Implement event system for hooks and listeners
- [ ] Design configuration system
- [x] Create base Panel class (main entry point)
- [IN PROGRESS] Implement routing system integration with Jaspr
- [IN PROGRESS] Set up Jaspr server with Shelf handler
- [IN PROGRESS] Create server bootstrapping in Panel

#### 1.3 Basic Layout System
- [x] Create base Page component (abstract class)
- [x] Implement Layout component (sidebar, header, content)
- [x] Build Navigation component with group support
- [x] Add navigation group headers
- [x] Implement resource sorting within groups
- [ ] Create Breadcrumb component
- [x] Implement basic theme system (CSS-based)
- [ ] Add responsive utilities

### Phase 2: Form & Field System (Weeks 5-8)

#### 2.1 Form Foundation
- [ ] Create Form builder class
- [ ] Implement Field abstract class
- [ ] Build validation system
- [ ] Create form state management
- [ ] Implement error handling and display
- [ ] Add form submission handling

#### 2.2 Basic Form Fields
- [ ] TextInput field
- [ ] TextArea field
- [ ] Select field
- [ ] Checkbox field
- [ ] Radio field
- [ ] Toggle/Switch field
- [ ] Number input field
- [ ] Date/DateTime picker

#### 2.3 Advanced Form Fields
- [ ] Rich text editor integration
- [ ] File upload component
- [ ] Multi-select with search
- [ ] Relationship select (async search)
- [ ] Repeater field (dynamic lists)
- [ ] Key-value field
- [ ] Color picker
- [ ] Tags input

### Phase 3: Table & Data Display (Weeks 9-12)

#### 3.1 Table Foundation
- [ ] Create Table builder class
- [ ] Implement Column system
- [ ] Build pagination component
- [ ] Create sort functionality
- [ ] Implement server-side data loading
- [ ] Add loading states

#### 3.2 Table Features
- [ ] Filter system architecture
- [ ] Search functionality
- [ ] Bulk selection
- [ ] Bulk actions
- [x] Column visibility toggle
- [ ] Responsive table view
- [ ] Empty state handling

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
- [ ] Implement automatic CRUD operations
- [ ] Create resource routes
- [ ] Add resource authorization

#### 4.2 Resource Pages
- [ ] List page (with table)
- [ ] Create page (with form)
- [ ] Edit page (with form)
- [ ] View page (read-only display)
- [ ] Custom actions on pages
- [ ] Page hooks for customization

#### 4.3 Relationships
- [ ] Define relationship types
- [ ] HasMany display and management
- [ ] BelongsTo select handling
- [ ] ManyToMany with pivot tables
- [ ] Relationship eager loading
- [ ] Nested resource creation

### Phase 5: Dashboard & Widgets (Weeks 17-20)

#### 5.1 Dashboard System
- [ ] Create Dashboard class
- [ ] Implement widget system
- [ ] Build grid layout system
- [ ] Add widget positioning
- [ ] Create dashboard registration

#### 5.2 Core Widgets
- [ ] Stats widget (with trends)
- [ ] Chart widget (line, bar, pie)
- [ ] Table widget
- [ ] List widget
- [ ] Text/HTML widget
- [ ] Custom widget support

#### 5.3 Advanced Features
- [ ] Widget refresh intervals
- [ ] Real-time widget updates
- [ ] Widget filters
- [ ] Widget export
- [ ] Drag-and-drop customization (admin)

### Phase 6: Authentication & Authorization (Weeks 21-24)

#### 6.1 Authentication
- [IN PROGRESS] Create Auth provider interface
- [IN PROGRESS] Implement login system
- [IN PROGRESS] Build login page/component
- [IN PROGRESS] Add session management
- [IN PROGRESS] Implement logout functionality
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
- [ ] Team/tenant switching (multi-tenancy)

### Phase 7: UI Components & Polish (Weeks 25-28)

#### 7.1 Action System
- [ ] Create Action class
- [ ] Implement action modals
- [ ] Add confirmation dialogs
- [ ] Build action forms
- [ ] Create bulk actions
- [ ] Add action notifications

#### 7.2 Notification System
- [ ] Toast notifications
- [ ] Notification center
- [ ] Database notifications
- [ ] Real-time notifications (optional)
- [ ] Email notifications integration

#### 7.3 Additional Components
- [ ] Modal component
- [ ] Dropdown component
- [ ] Tabs component
- [ ] Accordion component
- [ ] Card component
- [ ] Badge component
- [ ] Avatar component
- [ ] Command palette (global search)

### Phase 8: Theming & Customization (Weeks 29-32)

#### 8.1 Theme System
- [ ] Create theme configuration
- [ ] Implement CSS variable system
- [ ] Build default theme
- [ ] Add dark mode support
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
- [ ] Create dash CLI package
- [ ] Add `init` command for new panels
- [ ] Add `make:resource` command
- [ ] Add `make:widget` command
- [ ] Add `make:page` command
- [ ] Add development server command

#### 9.2 Documentation
- [ ] Getting started guide
- [ ] Installation instructions
- [ ] Resource documentation
- [ ] Form builder documentation
- [ ] Table builder documentation
- [ ] Widget documentation
- [ ] Theming guide
- [ ] API reference
- [ ] Example applications

#### 9.3 Testing & Examples
- [ ] Create example application
- [ ] Build demo site
- [ ] Write unit tests
- [ ] Create integration tests
- [ ] Performance benchmarks
- [ ] Migration guides

### Phase 10: Advanced Features & Extensions (Weeks 37-40)

#### 10.1 Plugin System
- [ ] Finalize plugin architecture
- [ ] Create plugin marketplace concept
- [ ] Build example plugins
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

**Note**: This is a living document. Timeline estimates are flexible and will be adjusted based on complexity and feedback during development.
