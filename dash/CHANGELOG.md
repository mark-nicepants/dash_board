# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-07

### Added

- **Core Framework**: DASH (Dart Admin/System Hub) - A FilamentPHP-inspired admin panel framework for Dart
- **Resource System**: Model + Table + Form pattern for managing entities with CRUD operations
- **Form Builder**: Declarative forms with built-in field types and validation
- **Data Tables**: Advanced tables with sorting, filtering, and pagination
- **Authentication & Authorization**: Complete auth system with roles, policies, and permissions
- **Middleware Stack**: Configurable middleware for request handling and security headers
- **Security Features**: File upload validation, security headers middleware, and bcrypt password hashing
- **Logging System**: LogWriter for efficient log file handling and debug support
- **Plugin Architecture**: Extensible plugin system with initial plugins:
  - Dash Activity Log Plugin - Track entity changes
  - Dash Analytics Plugin - Performance metrics and analytics
- **Model Context Protocol (MCP) Server**: LLM integration for AI-assisted development
- **CLI Tools**: DCli command-line interface with:
  - Database creation and schema management
  - Model and resource generation from YAML schemas
  - Database seeding capabilities
- **Component System**: Built on Jaspr for server-side rendered UI components
- **Settings Storage**: Key-value store for persisting application settings
- **Form Interactivity**: Dynamic field visibility and state management with Alpine.js
- **Type Safety**: Full Dart type system support with generics
- **Middleware Integration**: Request handling with security headers and file upload validation

### Technical Foundation

- Built with **Dart 3.10.1+** and **Jaspr 0.21.7** for server-side rendering
- **SQLite3** support with ORM using Active Record pattern
- **Shelf** HTTP server framework
- **Tailwind CSS** for styling
- **Heroicons** SVG library for icons
- **Alpine.js** for client-side interactivity
- Comprehensive unit and integration tests with Playwright
