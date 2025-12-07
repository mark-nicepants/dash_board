import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('PanelColors', () {
    group('defaults', () {
      test('creates colors with default values', () {
        const colors = PanelColors();

        expect(colors.primary, equals('cyan'));
        expect(colors.danger, equals('red'));
        expect(colors.warning, equals('amber'));
        expect(colors.success, equals('green'));
        expect(colors.info, equals('blue'));
      });

      test('PanelColors.defaults provides default instance', () {
        expect(PanelColors.defaults.primary, equals('cyan'));
        expect(PanelColors.defaults.danger, equals('red'));
      });
    });

    group('custom colors', () {
      test('creates colors with custom values', () {
        const colors = PanelColors(
          primary: 'indigo',
          danger: 'rose',
          warning: 'orange',
          success: 'emerald',
          info: 'sky',
        );

        expect(colors.primary, equals('indigo'));
        expect(colors.danger, equals('rose'));
        expect(colors.warning, equals('orange'));
        expect(colors.success, equals('emerald'));
        expect(colors.info, equals('sky'));
      });

      test('allows partial customization', () {
        const colors = PanelColors(primary: 'purple');

        expect(colors.primary, equals('purple'));
        expect(colors.danger, equals('red')); // default
        expect(colors.warning, equals('amber')); // default
      });
    });

    group('primary color classes', () {
      test('generates primary background classes', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.primaryBg, equals('bg-indigo-500'));
        expect(colors.primaryBgHover, equals('hover:bg-indigo-600'));
        expect(colors.primaryBgActive, equals('active:bg-indigo-700'));
      });

      test('generates primary text classes', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.primaryText, equals('text-indigo-500'));
        expect(colors.primaryTextLight, equals('text-indigo-400'));
        expect(colors.primaryTextHover, equals('hover:text-indigo-300'));
      });

      test('generates primary border and ring classes', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.primaryBorder, equals('border-indigo-500'));
        expect(colors.primaryFocusRing, equals('focus:ring-indigo-500'));
        expect(colors.primaryFocusRingFaded, equals('focus:ring-indigo-500/50'));
        expect(colors.primaryFocusWithinRing, equals('focus-within:ring-indigo-500'));
      });
    });

    group('danger color classes', () {
      test('generates danger background classes', () {
        const colors = PanelColors(danger: 'rose');

        expect(colors.dangerBg, equals('bg-rose-600'));
        expect(colors.dangerBgHover, equals('hover:bg-rose-700'));
        expect(colors.dangerBgActive, equals('active:bg-rose-800'));
      });

      test('generates danger text classes', () {
        const colors = PanelColors(danger: 'rose');

        expect(colors.dangerText, equals('text-rose-500'));
        expect(colors.dangerTextLight, equals('text-rose-400'));
      });
    });

    group('warning color classes', () {
      test('generates warning background classes', () {
        const colors = PanelColors(warning: 'orange');

        expect(colors.warningBg, equals('bg-orange-500'));
        expect(colors.warningBgHover, equals('hover:bg-orange-600'));
        expect(colors.warningBgActive, equals('active:bg-orange-700'));
      });

      test('generates warning text classes', () {
        const colors = PanelColors(warning: 'orange');

        expect(colors.warningText, equals('text-orange-500'));
        expect(colors.warningTextLight, equals('text-orange-400'));
      });
    });

    group('success color classes', () {
      test('generates success background classes', () {
        const colors = PanelColors(success: 'emerald');

        expect(colors.successBg, equals('bg-emerald-600'));
        expect(colors.successBgHover, equals('hover:bg-emerald-700'));
        expect(colors.successBgActive, equals('active:bg-emerald-800'));
      });

      test('generates success text classes', () {
        const colors = PanelColors(success: 'emerald');

        expect(colors.successText, equals('text-emerald-500'));
        expect(colors.successTextLight, equals('text-emerald-400'));
      });
    });

    group('info color classes', () {
      test('generates info background classes', () {
        const colors = PanelColors(info: 'sky');

        expect(colors.infoBg, equals('bg-sky-600'));
        expect(colors.infoBgHover, equals('hover:bg-sky-700'));
        expect(colors.infoBgActive, equals('active:bg-sky-800'));
      });

      test('generates info text classes', () {
        const colors = PanelColors(info: 'sky');

        expect(colors.infoText, equals('text-sky-500'));
        expect(colors.infoTextLight, equals('text-sky-400'));
      });
    });

    group('composite styles', () {
      test('generates button primary classes', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.buttonPrimary, contains('bg-indigo-500'));
        expect(colors.buttonPrimary, contains('text-white'));
        expect(colors.buttonPrimary, contains('hover:bg-indigo-600'));
        expect(colors.buttonPrimary, contains('focus:ring-indigo-500'));
      });

      test('generates button danger classes', () {
        const colors = PanelColors(danger: 'rose');

        expect(colors.buttonDanger, contains('bg-rose-600'));
        expect(colors.buttonDanger, contains('text-white'));
        expect(colors.buttonDanger, contains('hover:bg-rose-700'));
      });

      test('generates button warning classes', () {
        const colors = PanelColors(warning: 'orange');

        expect(colors.buttonWarning, contains('bg-orange-500'));
        expect(colors.buttonWarning, contains('text-white'));
      });

      test('generates button success classes', () {
        const colors = PanelColors(success: 'emerald');

        expect(colors.buttonSuccess, contains('bg-emerald-600'));
        expect(colors.buttonSuccess, contains('text-white'));
      });

      test('generates button info classes', () {
        const colors = PanelColors(info: 'sky');

        expect(colors.buttonInfo, contains('bg-sky-600'));
        expect(colors.buttonInfo, contains('text-white'));
      });

      test('generates subtle button classes', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.buttonPrimarySubtle, contains('text-indigo-400'));
        expect(colors.buttonPrimarySubtle, contains('bg-gray-700'));
      });

      test('generates input focus classes', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.inputFocus, contains('focus:ring-indigo-500/50'));
        expect(colors.inputFocus, contains('focus:outline-none'));
      });

      test('generates checkbox checked color', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.checkboxChecked, equals('text-indigo-500'));
      });

      test('generates accent text', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.accentText, equals('text-indigo-400'));
      });

      test('generates glow background with opacity', () {
        const colors = PanelColors(primary: 'indigo');

        expect(colors.glowBg(), equals('bg-indigo-500/20'));
        expect(colors.glowBg(30), equals('bg-indigo-500/30'));
        expect(colors.glowBg(50), equals('bg-indigo-500/50'));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const colors = PanelColors(primary: 'indigo', danger: 'rose');

        expect(
          colors.toString(),
          equals('PanelColors(primary: indigo, danger: rose, warning: amber, success: green, info: blue)'),
        );
      });
    });
  });
}
