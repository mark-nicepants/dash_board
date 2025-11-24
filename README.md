# Dash

DASH (Dart Admin/System Hub) - A modern admin panel framework for Dart, inspired by FilamentPHP.

## Project Structure

This repository is organized as a monorepo:

```
dash_board/
├── dash/           # Core framework package
├── dash_example/   # Example application for testing
└── docs/          # Documentation and planning
```

## Packages

### dash
The core framework package that provides all the functionality for building admin panels.

### dash_example
A complete example application demonstrating how to use Dash. This serves as both documentation and a testing ground for new features.

## Getting Started

See the individual package READMEs for more information:
- [dash](./dash/README.md) - Core framework
- [dash_example](./dash_example/README.md) - Example application

## Development

To work on Dash:

1. Clone the repository
2. Navigate to the dash package: `cd dash`
3. Get dependencies: `dart pub get`
4. Run tests: `dart test`

To run the example:

```bash
cd dash_example
dart pub get
dart run lib/main.dart
```

## Documentation

See the [docs](./docs) folder for detailed documentation and development plans.

## Status

⚠️ **Early Development** - This project is in active development. APIs are subject to change.

## License

MIT License - see LICENSE file for details.
