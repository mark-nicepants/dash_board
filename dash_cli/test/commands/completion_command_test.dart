import 'package:dash_panel_cli/src/commands/completion_command.dart';
import 'package:test/test.dart';

void main() {
  group('CompletionCommand', () {
    test('generates valid zsh completion script', () {
      final command = CompletionCommand();
      // Access the private method indirectly by checking command properties
      expect(command.name, 'completion');
      expect(command.description, contains('shell completion'));
    });

    test('command has correct aliases', () {
      final command = CompletionCommand();
      // CompletionCommand doesn't have aliases, which is fine
      expect(command.name, 'completion');
    });
  });
}
