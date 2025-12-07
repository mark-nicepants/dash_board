import 'package:dash_panel_cli/src/utils/console_utils.dart';
import 'package:test/test.dart';

void main() {
  group('ConsoleUtils', () {
    test('formatNumber adds thousand separators', () {
      expect(ConsoleUtils.formatNumber(1000), '1,000');
      expect(ConsoleUtils.formatNumber(1000000), '1,000,000');
      expect(ConsoleUtils.formatNumber(999), '999');
      expect(ConsoleUtils.formatNumber(0), '0');
    });

    test('formatDuration formats correctly', () {
      expect(ConsoleUtils.formatDuration(Duration(milliseconds: 500)), '500ms');
      expect(ConsoleUtils.formatDuration(Duration(seconds: 30)), '30s');
      expect(ConsoleUtils.formatDuration(Duration(minutes: 5, seconds: 30)), '5m 30s');
      expect(ConsoleUtils.formatDuration(Duration(hours: 2, minutes: 15)), '2h 15m');
    });

    test('color codes are valid ANSI escape sequences', () {
      expect(ConsoleUtils.red, startsWith('\x1B['));
      expect(ConsoleUtils.green, startsWith('\x1B['));
      expect(ConsoleUtils.yellow, startsWith('\x1B['));
      expect(ConsoleUtils.blue, startsWith('\x1B['));
      expect(ConsoleUtils.reset, startsWith('\x1B['));
    });
  });
}
