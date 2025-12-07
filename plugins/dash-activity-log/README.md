# Dash Activity Log Plugin

Activity logging plugin for the [Dash](https://github.com/mark-nicepants/dash_panel) admin panel framework. This plugin provides automatic tracking of model changes and user actions, creating a comprehensive audit trail for your application.

## Features

- 🔍 **Automatic Logging**: Automatically tracks all model CRUD operations (Create, Read, Update, Delete).
- 📊 **Audit Trail**: Stores detailed logs in a dedicated `activities` table.
- 👤 **User Tracking**: Records which user performed each action (Subject & Causer).
- 📝 **Change History**: Captures `before` and `after` states for updates.
- ⚙️ **Configurable**: Exclude specific tables and set retention policies.
- 🖥️ **Admin UI**: Includes a built-in "Activity Log" resource for viewing and searching logs.

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  dash_activity_log: ^0.1.0
```

## Usage

Register the plugin in your Dash panel configuration:

```dart
import 'package:dash_panel/dash_panel.dart';
import 'package:dash_activity_log/dash_activity_log.dart';

void main() {
  
  Panel()
      ..plugin(ActivityLogPlugin.make())
      ..serve();
  
}
```

## Configuration

You can configure the plugin to exclude certain tables or set a retention period for logs:

```dart
panel.plugin(
  ActivityLogPlugin.make()
    // Don't log changes to these tables
    .excludeTables(['sessions', 'cache', 'temporary_data'])
    
    // Automatically delete logs older than 90 days
    // Set to null to keep logs indefinitely (default)
    .retentionDays(90)
    
    // Toggle description logging (default: true)
    .logDescription(true)
);
```

## Viewing Activities

Once installed, an **Activity Log** item will appear in your admin panel's navigation. This view allows you to:

- **List** all system activities.
- **Search** by event name, subject, or description.
- **Filter** and sort logs.
- **View** detailed information about each activity, including changed properties.

## Data Model

The `Activity` model captures the following information:

- **Event**: The name of the event (e.g., `users.created`, `posts.updated`).
- **Subject**: The model that was changed (Type and ID).
- **Causer**: The user who performed the action.
- **Properties**: A JSON map containing the `old` and `new` values for updates.
- **Description**: A human-readable description of the event.
- **Created At**: Timestamp of when the event occurred.

## License

MIT
