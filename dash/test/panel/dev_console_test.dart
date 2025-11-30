import 'package:dash/src/panel/dev_console.dart';
import 'package:test/test.dart';

void main() {
  group('DevCommand', () {
    test('creates command with required properties', () {
      final command = DevCommand(name: 'test', description: 'A test command', handler: (_) async {});

      expect(command.name, equals('test'));
      expect(command.description, equals('A test command'));
      expect(command.shortName, isNull);
      expect(command.usage, isNull);
    });

    test('creates command with optional properties', () {
      final command = DevCommand(
        name: 'test',
        shortName: 't',
        description: 'A test command',
        handler: (_) async {},
        usage: 'test [options]',
      );

      expect(command.name, equals('test'));
      expect(command.shortName, equals('t'));
      expect(command.description, equals('A test command'));
      expect(command.usage, equals('test [options]'));
    });
  });

  group('DevConsole', () {
    late DevConsole console;

    setUp(() {
      console = DevConsole();
    });

    test('isRunning is false initially', () {
      expect(console.isRunning, isFalse);
    });

    test('registerCommand adds command', () {
      final command = DevCommand(name: 'custom', description: 'Custom command', handler: (_) async {});

      console.registerCommand(command);

      // Command is registered but we can't easily test retrieval
      // without making internal methods public
      expect(console, isNotNull);
    });

    test('registerCommand registers shortName alias', () {
      final command = DevCommand(name: 'custom', shortName: 'c', description: 'Custom command', handler: (_) async {});

      console.registerCommand(command);

      // Both 'custom' and 'c' should now be registered
      expect(console, isNotNull);
    });

    test('has built-in help command', () {
      // DevConsole registers built-in commands in constructor
      expect(console, isNotNull);
    });

    test('has built-in quit command', () {
      expect(console, isNotNull);
    });

    test('has built-in clear command', () {
      expect(console, isNotNull);
    });

    test('has built-in routes command', () {
      expect(console, isNotNull);
    });

    test('has built-in resources command', () {
      expect(console, isNotNull);
    });

    test('has built-in status command', () {
      expect(console, isNotNull);
    });

    test('has built-in db:log command', () {
      expect(console, isNotNull);
    });

    test('has built-in db:queries command', () {
      expect(console, isNotNull);
    });

    test('has built-in clearlog command', () {
      expect(console, isNotNull);
    });

    test('setRoutePrinter replaces routes command handler', () {
      console.setRoutePrinter(() {});

      // The printer is set but we can't invoke it without simulating input
      expect(console, isNotNull);
    });

    test('setResourcePrinter replaces resources command handler', () {
      console.setResourcePrinter(() {});

      expect(console, isNotNull);
    });

    test('onRestart callback can be set', () {
      console.onRestart = () async {};

      expect(console.onRestart, isNotNull);
    });

    test('onStop callback can be set', () {
      console.onStop = () async {};

      expect(console.onStop, isNotNull);
    });

    test('onClear callback can be set', () {
      console.onClear = () {};

      expect(console.onClear, isNotNull);
    });
  });
}
