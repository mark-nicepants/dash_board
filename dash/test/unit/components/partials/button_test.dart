@TestOn('vm')
library;

import 'package:dash/src/components/partials/button.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

// Note: Tests with HeroIcons are skipped because the Heroicon component uses
// raw() which outputs raw HTML strings that don't work with testComponents.
// These components need to be tested with testServer or testBrowser instead.

void main() {
  group('Button Component', () {
    testComponents('renders button with label', (tester) async {
      tester.pumpComponent(
        const Button(label: 'Click Me'),
      );

      expect(find.text('Click Me'), findsOneComponent);
      expect(find.tag('button'), findsOneComponent);
    });

    testComponents('renders as anchor when href is provided', (tester) async {
      tester.pumpComponent(
        const Button(label: 'Link', href: '/some-page'),
      );

      expect(find.text('Link'), findsOneComponent);
      expect(find.tag('a'), findsOneComponent);
    });

    testComponents('renders disabled button', (tester) async {
      tester.pumpComponent(
        const Button(label: 'Disabled', disabled: true),
      );

      expect(find.tag('button'), findsOneComponent);
    });

    testComponents('renders full width button', (tester) async {
      tester.pumpComponent(
        const Button(label: 'Full Width', fullWidth: true),
      );

      expect(find.tag('button'), findsOneComponent);
    });

    testComponents('renders different sizes', (tester) async {
      tester.pumpComponent(
        div([
          const Button(label: 'XS', size: ButtonSize.xs),
          const Button(label: 'SM', size: ButtonSize.sm),
          const Button(label: 'MD', size: ButtonSize.md),
          const Button(label: 'LG', size: ButtonSize.lg),
        ]),
      );

      expect(find.tag('button'), findsNComponents(4));
    });

    testComponents('renders different variants', (tester) async {
      tester.pumpComponent(
        div([
          const Button(label: 'Primary', variant: ButtonVariant.primary),
          const Button(label: 'Secondary', variant: ButtonVariant.secondary),
          const Button(label: 'Danger', variant: ButtonVariant.danger),
          const Button(label: 'Warning', variant: ButtonVariant.warning),
          const Button(label: 'Success', variant: ButtonVariant.success),
          const Button(label: 'Info', variant: ButtonVariant.info),
          const Button(label: 'Ghost', variant: ButtonVariant.ghost),
        ]),
      );

      expect(find.tag('button'), findsNComponents(7));
    });

    testComponents('opens in new tab when specified', (tester) async {
      tester.pumpComponent(
        const Button(label: 'External', href: 'https://example.com', openInNewTab: true),
      );

      expect(find.tag('a'), findsOneComponent);
    });

    testComponents('renders subtle variant', (tester) async {
      tester.pumpComponent(
        const Button(label: 'Subtle', subtle: true),
      );

      expect(find.tag('button'), findsOneComponent);
    });
  });
}
