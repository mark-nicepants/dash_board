import 'package:jaspr/jaspr.dart';

/// Empty state component for tables when no records are found.
///
/// Example:
/// ```dart
/// TableEmptyState(
///   icon: const Heroicon(HeroIcons.users),
///   heading: 'No users found',
///   description: 'Create your first user to get started.',
///   action: Button(label: 'Create User', href: '/users/create'),
/// )
/// ```
class TableEmptyState extends StatelessComponent {
  /// Optional icon to display.
  final Component? icon;

  /// The heading text.
  final String heading;

  /// The description text.
  final String description;

  /// Optional action button or component.
  final Component? action;

  const TableEmptyState({this.icon, required this.heading, required this.description, this.action, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'py-16 px-6 text-center', [
      div(classes: 'max-w-md mx-auto', [
        if (icon != null) div(classes: 'text-5xl mb-4', [icon!]),
        h3(classes: 'text-lg font-semibold text-gray-100 mb-2', [text(heading)]),
        p(classes: 'text-sm text-gray-400 mb-6', [text(description)]),
        if (action != null) action!,
      ]),
    ]);
  }
}
