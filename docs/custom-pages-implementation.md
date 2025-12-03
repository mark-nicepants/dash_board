# Custom Pages System Implementation

> Implementation tracking for the Custom Pages System feature in Dash

## Status: ✅ Complete

**Started:** December 3, 2025  
**Completed:** December 3, 2025  
**Last Updated:** December 3, 2025

---

## Overview

The Custom Pages System allows developers to register arbitrary pages beyond resources. This is foundational infrastructure that many plugins depend on (SEO, Settings, Activity Log, Backup, Media, Blog, Documentation, etc.).

### Goals

1. **Register arbitrary pages beyond resources** - Not everything fits the Resource CRUD pattern
2. **Page components with layout integration** - Custom pages should integrate with the admin layout
3. **Breadcrumb support for custom pages** - Navigation consistency across all page types

---

## Investigation Notes

### Current Architecture

**Panel Registration Flow:**
1. `Panel` is the main entry point with fluent configuration
2. `PanelConfig` holds all configuration data (resources, plugins, navigation items, custom routes)
3. `PanelServer` starts the HTTP server
4. `PanelRouter` routes requests to appropriate pages

**Page Rendering:**
1. `PanelRouter._getPageForPath()` determines which page to render based on URL
2. Pages are wrapped in `DashLayout` via `_wrapInLayout()` 
3. `DashLayout` provides sidebar navigation, header, and main content area
4. Individual pages like `ResourceIndex`, `ResourceForm`, `DashboardPage` are Components

**Existing Custom Route System:**
- `Panel.registerCustomRoute(path, handler)` - Registers raw route handlers (must return Response)
- These handlers don't get layout integration - they return raw Response objects
- This is too low-level for typical custom pages

**Navigation Items:**
- `NavigationItem` class provides sidebar links
- Can be added via `panel.navigationItems([...])`
- Support groups, icons, sorting, visibility conditions
- URLs resolve relative to panel base path

**Page Components:**
- `ResourcePageScaffold` - Wrapper with title, breadcrumbs, actions
- `BreadCrumbs` and `BreadCrumbItem` - Navigation breadcrumbs
- `PageHeader` - Title and action buttons

### Design Decisions

1. **Create `Page` abstract class** - Similar to `Resource` but for non-CRUD pages
2. **Pages render Jaspr Components** - Consistent with existing pages
3. **Automatic layout wrapping** - Pages get `DashLayout` automatically
4. **Built-in breadcrumb support** - Pages define their own breadcrumb trail
5. **Registration via Panel.registerPages()** - Similar to registerResources()
6. **Auto navigation registration** - Pages can optionally register navigation items

---

## Implementation Progress

### Phase 1: Investigation ✅
- [x] Examine current Panel registration system
- [x] Examine Router implementation
- [x] Examine current page rendering (ResourceIndex, ResourceForm, etc.)
- [x] Examine how render hooks work
- [x] Identify integration points

### Phase 2: Design ✅
- [x] Design Page base class/interface
- [x] Design registration API
- [x] Design breadcrumb system
- [x] Document public API

### Phase 3: Implementation ✅
- [x] Create Page base class
- [x] Add registration methods to Panel
- [x] Update Router to handle custom pages
- [x] Implement breadcrumb generation
- [x] Update layout components

### Phase 4: Testing ✅
- [x] Add example custom page
- [x] Test via Playwright
- [x] Write unit tests
- [x] Update documentation

---

## API Design (Final)

### Page Base Class

```dart
/// Base class for custom pages in Dash.
abstract class Page {
  /// Unique slug for URL routing (e.g., 'settings' -> /admin/pages/settings)
  String get slug;
  
  /// Page title displayed in header and browser tab
  String get title;
  
  /// Icon for navigation (optional, defaults to null)
  HeroIcons? get icon => null;
  
  /// Navigation group (optional, defaults to null = no navigation)
  String? get navigationGroup => null;
  
  /// Sort order in navigation (default: 0)
  int get navigationSort => 0;
  
  /// Whether to register in navigation (true if navigationGroup is set)
  bool get shouldRegisterNavigation => navigationGroup != null;
  
  /// Breadcrumb items for this page
  List<BreadCrumbItem> breadcrumbs(String basePath);
  
  /// Build the page component (receives request for query params, basePath for URLs)
  FutureOr<Component> build(Request request, String basePath);
  
  /// Page-specific assets (optional, defaults to null)
  PageAssetCollector? get assets => null;
}
```

### Registration

```dart
// In Panel:
Panel registerPages(List<Page> pages);

// In application:
await Panel()
    .registerPages([
      SettingsPage.make(),
      AboutPage.make(),
    ])
    .serve();

// In plugins:
class MyPlugin implements Plugin {
  @override
  void register(Panel panel) {
    panel.registerPages([MyCustomPage.make()]);
  }
}

// URL: /admin/pages/{slug}
```

### Example Usage

```dart
class SettingsPage extends Page {
  static SettingsPage make() => SettingsPage();
  
  @override
  String get slug => 'settings';
  
  @override
  String get title => 'Settings';
  
  @override
  HeroIcons? get icon => HeroIcons.cog6Tooth;
  
  @override
  String? get navigationGroup => 'System';
  
  @override
  int get navigationSort => 100;
  
  @override
  List<BreadCrumbItem> breadcrumbs(String basePath) => [
    BreadCrumbItem(label: 'Dashboard', url: basePath),
    const BreadCrumbItem(label: 'Settings'),
  ];
  
  @override
  FutureOr<Component> build(Request request, String basePath) {
    return div(classes: 'space-y-6', [
      // Page header with breadcrumbs
      div(classes: 'flex flex-col gap-2', [
        BreadCrumbs(items: breadcrumbs(basePath)),
        h1(classes: 'text-3xl font-bold text-gray-100', [text(title)]),
      ]),
      // Page content
      Card(child: div([text('Settings content here')])),
    ]);
  }
}
```

---

## Files Changed

### New Files
- `lib/src/page/page.dart` - Page base class with slug, title, icon, navigationGroup, breadcrumbs, build, assets
- `test/page/page_test.dart` - 24 unit tests for Page and PanelConfig pages functionality
- `example/lib/pages/settings_page.dart` - Example Settings page demonstrating the feature

### Modified Files
- `lib/dash.dart` - Added exports for Page, BreadCrumbs, Card, PageHeader, ResourcePageScaffold
- `lib/src/panel/panel.dart` - Added `registerPages()` method and Page import
- `lib/src/panel/panel_config.dart` - Added `_pages` list, `pages` getter, and `registerPages()` method
- `lib/src/panel/panel_router.dart` - Added routing for `/admin/pages/{slug}` paths
- `example/lib/main.dart` - Added SettingsPage registration

---

## Notes

### URL Structure
Custom pages are served at `/admin/pages/{slug}`. For example:
- `SettingsPage` with slug `settings` → `/admin/pages/settings`
- `AboutPage` with slug `about` → `/admin/pages/about`

### Navigation Registration
Pages can optionally register themselves in sidebar navigation by setting `navigationGroup`:
- If `navigationGroup` is set, a `NavigationItem` is auto-created
- The navigation item uses the page's `icon` (or defaults to `HeroIcons.document`)
- Sort order is controlled by `navigationSort`

### Breadcrumbs
Pages define their own breadcrumb trail via the `breadcrumbs(basePath)` method:
- The `basePath` parameter provides the panel's base URL (e.g., `/admin`)
- Returns a `List<BreadCrumbItem>` with label and optional URL
- Last item typically has no URL (current page)

### Assets
Pages can provide page-specific CSS/JS assets via the `assets` getter:
- Returns a `PageAssetCollector` or `null`
- Assets are injected into the HTML template head/body sections
- Useful for pages that need external libraries (e.g., charts, rich text editors)

### Integration with Plugins
Plugins can register custom pages in their `register()` method:
```dart
class MyPlugin implements Plugin {
  @override
  void register(Panel panel) {
    panel.registerPages([
      MyCustomPage.make(),
    ]);
  }
}
```
