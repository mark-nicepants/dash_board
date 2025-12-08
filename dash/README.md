# Dash

DASH (Dart Admin/System Hub) - A modern admin panel framework for Dart, inspired by FilamentPHP. Build beautiful admin interfaces with ease using Jaspr.

## Features

- 🎨 **Beautiful UI** - Modern, responsive design out of the box
- 🔧 **Easy to Use** - Intuitive API that follows Dart conventions
- 🚀 **Type-Safe** - Leverages Dart's strong typing system
- 🧩 **Component-Based** - Built on Jaspr's powerful component system
- 📦 **Modular** - Plugin architecture for extensibility
- 🔐 **Authentication** - Built-in auth and authorization
- 📊 **Data Tables** - Advanced tables with sorting, filtering, and pagination
- 📝 **Form Builder** - Declarative forms with validation
- 📈 **Dashboard** - Customizable widgets and charts

## Installation

Add Dash to your `pubspec.yaml`:

```yaml
dependencies:
  dash_panel: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

```dart
import 'package:dash_panel/dash_panel.dart';

void main() {
  print('🚀 Dash Example Admin Panel\n');

  // Register all generated models and resources
  registerAllModels();

  // Create and configure the admin panel
  await Panel()
      .applyConfig()
      .authModel<User>()
      .registerPages([
        // Register your custom pages
      ])
      .plugins([
        // Add plugins here
      ])
      .serve(host: 'localhost', port: 8080);
  // Integrate with your server
  // More documentation coming soon!
}
```

## Model generation 



## Documentation

Full documentation is coming soon. See the `docs/` directory for development plans and architecture details.

## Development Status

⚠️ **This project is in early development.** APIs are subject to change.

## License

MIT License - see LICENSE file for details.
