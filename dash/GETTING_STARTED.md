# Dash - Getting Started

## What We've Built

We've successfully integrated Jaspr with Dash and created a working admin panel with authentication! 🎉

### ✅ Completed Features

1. **Jaspr Server Integration**
   - Shelf-based HTTP server
   - Jaspr component rendering
   - Request routing

2. **Authentication System**
   - Login page with form
   - Session-based authentication using cookies
   - Auth middleware to protect routes
   - Default admin user (email: `admin@example.com`, password: `password`)

3. **UI Components**
   - Login page
   - Dashboard layout with sidebar navigation
   - **Navigation groups** for organized resource display
   - Group headers with proper styling
   - Admin panel structure
   - Basic styling with custom CSS

4. **Database Integration**
   - SQLite connector
   - Model system with code generation
   - Database seeding
   - Configurable database path

5. **Resource System**
   - Smart defaults for `label` and `singularLabel` (auto-derived from model name)
   - Default `navigationGroup` set to 'Main'
   - Configurable `navigationSort` for ordering
   - Minimal resource definitions (only override what's needed)
   - Icon components support

## Running the Server

### Using the Run Configuration (VS Code)
The project includes run configurations that automatically set the correct database directory:
- **Dash Server** - Standard run
- **Dash Server (Hot Reload)** - With hot reload support

### Command Line
```bash
cd dash_example
dart run
```

Or specify a custom database directory:
```bash
dart run bin/dash_example.dart path/to/database
```

The server will start at:
- Main admin: http://localhost:8080/admin
- Login page: http://localhost:8080/admin/login

### Default Credentials
- **Email**: admin@example.com
- **Password**: password

## Project Structure

```
dash/
├── lib/
│   ├── src/
│   │   ├── components/        # Jaspr UI components
│   │   │   ├── app.dart       # Main app with routing
│   │   │   ├── layout.dart    # Admin layout
│   │   │   ├── styles.dart    # CSS styles
│   │   │   └── pages/
│   │   │       ├── login_page.dart
│   │   │       └── dashboard_page.dart
│   │   ├── auth/             # Authentication system
│   │   │   ├── auth_service.dart
│   │   │   └── auth_middleware.dart
│   │   ├── database/         # Database layer
│   │   ├── model/            # Model system
│   │   └── panel.dart        # Main Panel class
│   └── dash.dart
```

## Next Steps

### Immediate Priorities

1. **Improve Jaspr SSR Rendering**
   - Currently using basic HTML template
   - Need to properly integrate Jaspr server-side rendering
   - Add client-side hydration

2. **Resource CRUD Pages**
   - Implement list/table view for resources
   - Create/edit forms
   - Delete functionality

3. **Form Components**
   - Text input
   - Select dropdown
   - Checkbox/radio
   - Date picker
   - File upload

4. **Table Components**
   - Data table with sorting
   - Pagination
   - Filtering
   - Search

5. **Dashboard Widgets**
   - Stats cards
   - Charts
   - Recent activity

### Architecture Improvements

1. **Routing**
   - Use jaspr_router more effectively
   - Add route guards
   - Implement proper 404 pages

2. **State Management**
   - Add proper state management for forms
   - Session state handling
   - Flash messages/notifications

3. **Validation**
   - Client-side validation
   - Server-side validation
   - Error display in forms

## How It Works

### Server Flow

1. **Panel.serve()** starts a Shelf server
2. Requests go through middleware:
   - Logging middleware
   - Auth middleware (checks session cookie)
3. Custom handlers process:
   - POST /admin/login → authenticate and set session cookie
   - GET /admin/logout → clear session cookie
4. All other requests render Jaspr components

### Authentication Flow

1. User visits `/admin/login`
2. Submits email/password form
3. Server validates credentials via `AuthService`
4. On success: sets `dash_session` cookie and redirects to `/admin`
5. Protected routes check for valid session cookie
6. Invalid/missing session → redirect to login

## Development Notes

- The Jaspr integration is currently simplified - we're rendering basic HTML
- Proper SSR rendering with Jaspr components needs to be implemented
- The authentication is basic (in-memory sessions) - needs persistence for production
- No client-side JavaScript yet - forms use native HTML form submission

## Contributing

This is the foundation! The next phase involves:
- Building out the resource system
- Creating reusable form and table components
- Implementing proper Jaspr SSR
- Adding client-side interactivity

---

**Status**: Phase 1 Foundation Complete ✅
**Next Phase**: Resource CRUD & Components
