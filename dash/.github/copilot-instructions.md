# Dash - Copilot Instructions

> **Dash** (Dart Admin/System Hub) is a FilamentPHP-inspired admin panel framework for Dart.

## Quick Reference

**What is Dash?** A server-side rendered website framework for Dart, inspired by FilamentPHP. It provides CRUD operations, forms, tables, and authentication out of the box.

**Key Concepts:**
- **Resource** = Model + Table + Form (defines how an entity is managed in the admin)
- **Model** = Active Record ORM with fluent query builder
- **FormField** = Input component with `dehydrateValue()` for DB conversion and `hydrateValue()` for display
- **Panel** = The main app orchestrator

## Development Workflow

### Running & Testing with Playwright

When fixing bugs or testing features interactively:

1. **Start the server with the example project** 
 - Run via VSCode task: Start Dash Example Server
 - Ensure it's running at `http://localhost:8080`.
 - If you get port in use errors. use `lsof -i :8080` to find and kill the process using it and restart the server.

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
2. **Check the logs** - Read `storage/logs/dash_YYYYMMDD_HHMM.log` for errors and debug info
3. **Add debug output** - Print statements in key locations (router, resource methods)
4. **Trace the flow** - Follow data through: Form submission → Resource → Model → Database
5. **Identify the layer** - Is it presentation, application, domain, or infrastructure?
7. **Test the fix** - Use Playwright to verify, then write unit tests
8. **Clean up debug output** - Remove print statements before committing

# Use the Dash MCP (Model context protocol)

The Dash MCP server provides tools to interact with a running Dash admin panel server. These tools allow querying logs, checking status, and managing resources. The server must be running for tools to work.

## Available Tools

### Server Status & Resources
- **mcp_dash_cli_get_server_status**: Get server status, uptime, registered resources, DB connection, and memory usage. No parameters required.
- **mcp_dash_cli_get_registered_resources**: List all registered resources with name and slug. No parameters required.

### Log Queries
- **mcp_dash_cli_get_all_logs**: Query all logs (requests, SQL, errors). Parameters: `level` (optional filter), `lines` (default 50, max 200), `since` (ISO timestamp).
- **mcp_dash_cli_get_request_logs**: Query HTTP request logs. Parameters: `lines` (default 50, max 200), `since` (ISO timestamp).
- **mcp_dash_cli_get_sql_logs**: Query SQL execution logs with parameters, time, row counts. Parameters: `lines` (default 50, max 200), `since` (ISO timestamp).
- **mcp_dash_cli_get_exceptions**: Query error and exception logs with stack traces. Parameters: `lines` (default 50, max 200), `since` (ISO timestamp).

### Performance Monitoring
- **mcp_dash_cli_get_slow_requests**: Find HTTP requests exceeding threshold. Parameters: `lines` (default 20), `threshold_ms` (default 100).
- **mcp_dash_cli_get_slow_queries**: Find SQL queries exceeding threshold. Parameters: `lines` (default 20), `threshold_ms` (default 10).

### Code Generation
- **mcp_dash_cli_generate_models**: Generate Dart model and resource classes from YAML schemas. Parameters: `force` (overwrite, default false), `output_path` (default 'lib'), `schemas_path` (default 'schemas/models').

## Usage Tips
- Use status tools first to verify server health.
- For debugging, start with all logs, then drill into specific types.
- Performance tools help identify bottlenecks.
- Generate models after updating schemas.
- All tools return data in JSON format for easy parsing.

## Tech Stack

- **Language**: Dart 3.x+
- **Web Framework**: Jaspr (server-side rendering)
- **Client-side**: Alpine.js for interactivity
- **Styling**: Tailwind CSS
- **HTTP Server**: Shelf
- **Testing**: Dart test (unit), Playwright (integration)
- **ORM**: Custom Active Record pattern (in `lib/src/models/`)
- **Database**: SQLite (example), supports PostgreSQL/MySQL
- **Icons**: Heroicons SVG library

## Core Principles

1. **SOLID Principles** - Follow single responsibility, open/closed, Liskov substitution, interface segregation, and dependency inversion
2. **Fluent Builder APIs** - All configuration uses method chaining for readability
3. **Convention over Configuration** - Smart defaults, minimal required setup
4. **Server-Side Rendering** - Full page renders with traditional navigation
5. **Type Safety** - Leverage Dart's type system with generics
6. **Reusable Components** - Create and use Jaspr components for UI elements
7. **Fields Own Their Conversion** - Each FormField type handles its own value conversion in `dehydrateValue()`

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

### DRY (Don't Repeat Yourself)
Extract common patterns into reusable components. Code should be written once, used many times.

#### When to Extract
- Code appears **3+ times** → Extract to method or class
- Duplication across **multiple files** → Create shared utility/mixin
- **Repeated parameter patterns** → Create builder or factory class
- **Repeated validation logic** → Create reusable validator rule

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

*Last updated: 2025-12-06*
