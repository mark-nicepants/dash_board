import 'package:dash_board/src/components/partials/button.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Login page component for the admin panel.
///
/// A modern, sleek login page with a split-screen design featuring
/// branding on the left and the login form on the right.
class LoginPage extends StatelessComponent {
  final String basePath;
  const LoginPage({super.key, this.basePath = '/admin'});

  @override
  Component build(BuildContext context) {
    return div(classes: 'min-h-screen flex', [
      // Left side - Branding panel
      _buildBrandingPanel(),
      // Right side - Login form
      _buildLoginPanel(),
    ]);
  }

  /// Builds the left branding panel with logo and tagline.
  Component _buildBrandingPanel() {
    final primary = panelColors.primary;
    return div(
      classes:
          'hidden lg:flex lg:w-1/2 bg-gradient-to-br from-zinc-900 via-zinc-800 to-zinc-900 relative overflow-hidden',
      [
        // Glow effect
        div(classes: 'absolute top-1/4 -left-20 w-80 h-80 bg-$primary-500/20 rounded-full blur-3xl', []),
        div(classes: 'absolute bottom-1/4 -right-20 w-80 h-80 bg-$primary-400/10 rounded-full blur-3xl', []),
        // Content
        div(classes: 'relative z-10 flex flex-col items-center justify-center w-full px-12', [
          // Logo
          img(src: '$basePath/assets/img/logo_long.png', alt: 'Dash Logo', classes: 'h-16 mb-8'),
          // Tagline
          p(classes: 'text-zinc-400 text-lg text-center max-w-md leading-relaxed', [
            text('A modern admin panel framework for Dart. '),
            span(classes: 'text-$primary-400 font-medium', [text('Build beautiful interfaces with ease.')]),
          ]),
          // Feature highlights
          div(classes: 'mt-12 space-y-4', [
            _buildFeatureItem('Type-safe models with automatic migrations'),
            _buildFeatureItem('Fluent builder APIs for tables and forms'),
            _buildFeatureItem('Real-time server-side rendering'),
          ]),
        ]),
      ],
    );
  }

  /// Builds a feature item with a checkmark icon.
  Component _buildFeatureItem(String featureText) {
    final primary = panelColors.primary;
    return div(classes: 'flex items-center gap-3 text-zinc-400', [
      div(classes: 'w-5 h-5 rounded-full bg-$primary-500/20 flex items-center justify-center', [
        Heroicon(HeroIcons.check, size: 12, color: 'text-$primary-400'),
      ]),
      span(classes: 'text-sm', [text(featureText)]),
    ]);
  }

  /// Builds the right login panel with the form.
  Component _buildLoginPanel() {
    final primary = panelColors.primary;
    return div(classes: 'w-full lg:w-1/2 flex items-center justify-center bg-zinc-950 px-6 py-12', [
      div(classes: 'w-full max-w-md', [
        // Mobile logo (hidden on large screens)
        div(classes: 'lg:hidden flex justify-center mb-8', [
          img(src: '$basePath/assets/img/logo_square.png', alt: 'Dash Logo', classes: 'h-16'),
        ]),
        // Welcome text
        div(classes: 'mb-8', [
          h1(classes: 'text-2xl font-semibold text-white mb-2', [text('Welcome back')]),
          p(classes: 'text-zinc-400 text-sm', [text('Sign in to your admin panel')]),
        ]),
        // Login form
        form(action: '$basePath/login', method: FormMethod.post, classes: 'space-y-5', [
          // Email field
          div(classes: 'space-y-2', [
            label(
              attributes: {'for': 'email'},
              classes: 'block text-sm font-medium text-zinc-300',
              [text('Email address')],
            ),
            input(
              type: InputType.email,
              id: 'email',
              name: 'email',
              classes:
                  'w-full px-4 py-3 bg-zinc-900 border border-zinc-800 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:ring-2 focus:ring-$primary-500/50 focus:border-$primary-500 transition-all',
              attributes: {'placeholder': 'you@example.com', 'required': 'true', 'autocomplete': 'email'},
            ),
          ]),
          // Password field
          div(classes: 'space-y-2', [
            div(classes: 'flex items-center justify-between', [
              label(
                attributes: {'for': 'password'},
                classes: 'block text-sm font-medium text-zinc-300',
                [text('Password')],
              ),
            ]),
            input(
              type: InputType.password,
              id: 'password',
              name: 'password',
              classes:
                  'w-full px-4 py-3 bg-zinc-900 border border-zinc-800 rounded-lg text-white placeholder-zinc-500 focus:outline-none focus:ring-2 focus:ring-$primary-500/50 focus:border-$primary-500 transition-all',
              attributes: {'placeholder': '••••••••', 'required': 'true', 'autocomplete': 'current-password'},
            ),
          ]),
          // Remember me
          div(classes: 'flex items-center justify-between', [
            label(classes: 'flex items-center gap-2 cursor-pointer group', [
              input(
                type: InputType.checkbox,
                name: 'remember',
                classes:
                    'w-4 h-4 bg-zinc-900 border-zinc-700 rounded text-$primary-500 focus:ring-$primary-500/50 focus:ring-offset-0',
              ),
              span(classes: 'text-sm text-zinc-400 group-hover:text-zinc-300 transition-colors', [text('Remember me')]),
            ]),
          ]),
          // Submit button
          div(classes: 'pt-2', [
            const Button(
              label: 'Sign in',
              variant: ButtonVariant.primary,
              size: ButtonSize.lg,
              type: ButtonType.submit,
              fullWidth: true,
            ),
          ]),
        ]),
        // Footer
        div(classes: 'mt-8 pt-6 border-t border-zinc-800 text-center', [
          p(classes: 'text-xs text-zinc-500', [
            text('Powered by '),
            span(classes: 'text-$primary-500 font-medium', [text('Dash')]),
            text(' — The Dart Admin Panel Framework'),
          ]),
        ]),
      ]),
    ]);
  }
}
