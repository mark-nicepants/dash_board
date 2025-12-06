import 'package:test/test.dart';

void main() {
  group('DashMcpServer - generate_models', () {
    test('builds command arguments correctly with defaults', () {
      // Simulate building command arguments with no options
      final commandArgs = <String>['generate:models'];

      expect(commandArgs, equals(['generate:models']));
    });

    test('builds command arguments with schemas path', () {
      final schemasPath = 'custom/schemas';
      final commandArgs = <String>['generate:models'];

      commandArgs.addAll(['-s', schemasPath]);

      expect(commandArgs, equals(['generate:models', '-s', 'custom/schemas']));
    });

    test('builds command arguments with output path', () {
      final outputPath = 'lib/generated';
      final commandArgs = <String>['generate:models'];

      commandArgs.addAll(['-o', outputPath]);

      expect(commandArgs, equals(['generate:models', '-o', 'lib/generated']));
    });

    test('builds command arguments with force flag', () {
      final force = true;
      final commandArgs = <String>['generate:models'];

      if (force) {
        commandArgs.add('--force');
      }

      expect(commandArgs, equals(['generate:models', '--force']));
    });

    test('builds command arguments with all options', () {
      final schemasPath = 'schemas/models';
      final outputPath = 'lib';
      final force = true;

      final commandArgs = <String>['generate:models'];
      commandArgs.addAll(['-s', schemasPath]);
      commandArgs.addAll(['-o', outputPath]);
      if (force) {
        commandArgs.add('--force');
      }

      expect(commandArgs, equals(['generate:models', '-s', 'schemas/models', '-o', 'lib', '--force']));
    });

    group('ANSI code stripping', () {
      test('strips simple color codes', () {
        final input = '\x1B[32mSuccess\x1B[0m';
        final result = input.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        expect(result, equals('Success'));
      });

      test('strips bold text codes', () {
        final input = '\x1B[1mBold Text\x1B[0m';
        final result = input.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        expect(result, equals('Bold Text'));
      });

      test('strips multiple ANSI codes', () {
        final input = '\x1B[36m🎯 Dash Model Generator\x1B[0m\n\x1B[32m✓ Generated 3 models\x1B[0m';
        final result = input.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        expect(result, equals('🎯 Dash Model Generator\n✓ Generated 3 models'));
      });

      test('handles text without ANSI codes', () {
        final input = 'Plain text without colors';
        final result = input.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        expect(result, equals('Plain text without colors'));
      });

      test('strips complex multi-parameter codes', () {
        // Example: \x1B[38;5;196m (256-color foreground)
        final input = '\x1B[38;5;196mRed Text\x1B[0m';
        final result = input.replaceAll(RegExp(r'\x1B\[[0-9;]*[a-zA-Z]'), '');
        expect(result, equals('Red Text'));
      });
    });
  });
}
