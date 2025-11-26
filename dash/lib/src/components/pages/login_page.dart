import 'package:dash/src/components/partials/button.dart';
import 'package:jaspr/jaspr.dart';

/// Login page component for the admin panel.
class LoginPage extends StatelessComponent {
  final String basePath;
  const LoginPage({super.key, this.basePath = '/admin'});

  @override
  Component build(BuildContext context) {
    return div(
      classes:
          'min-h-screen flex items-center justify-center bg-gradient-to-br from-indigo-600 via-purple-600 to-purple-700',
      [
        div(classes: 'w-full max-w-md px-6', [
          div(classes: 'bg-white rounded-xl shadow-2xl p-10', [
            // Logo and title
            div(classes: 'text-center mb-8', [
              h1(classes: 'text-4xl font-bold text-indigo-600 mb-2', [text('DASH')]),
              p(classes: 'text-gray-600 text-sm', [text('Admin Panel Login')]),
            ]),
            // Login form
            form(action: '$basePath/login', method: FormMethod.post, classes: 'space-y-6', [
              div(classes: 'space-y-2', [
                label(
                  attributes: {'for': 'email'},
                  classes: 'block text-sm font-medium text-gray-700',
                  [text('Email')],
                ),
                input(
                  type: InputType.email,
                  id: 'email',
                  name: 'email',
                  classes:
                      'w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all',
                  attributes: {'placeholder': 'admin@example.com', 'required': 'true'},
                ),
              ]),
              div(classes: 'space-y-2', [
                label(
                  attributes: {'for': 'password'},
                  classes: 'block text-sm font-medium text-gray-700',
                  [text('Password')],
                ),
                input(
                  type: InputType.password,
                  id: 'password',
                  name: 'password',
                  classes:
                      'w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:border-transparent transition-all',
                  attributes: {'placeholder': '••••••••', 'required': 'true'},
                ),
              ]),
              div(classes: 'flex items-center', [
                label(classes: 'flex items-center gap-2 text-sm text-gray-700 cursor-pointer', [
                  input(
                    type: InputType.checkbox,
                    name: 'remember',
                    classes: 'w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-2 focus:ring-indigo-500',
                  ),
                  text('Remember me'),
                ]),
              ]),
              const Button(
                label: 'Login',
                variant: ButtonVariant.primary,
                size: ButtonSize.lg,
                type: ButtonType.submit,
                fullWidth: true,
              ),
            ]),
          ]),
        ]),
      ],
    );
  }
}
