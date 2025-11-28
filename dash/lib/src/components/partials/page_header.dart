import 'package:jaspr/jaspr.dart';

class PageHeader extends StatelessComponent {
  final String title;
  final List<Component>? actions;

  const PageHeader({required this.title, this.actions, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex justify-between items-center gap-4', [
      h1(classes: 'text-3xl font-bold text-gray-100', [text(title)]),
      div(classes: 'flex items-center gap-3', actions ?? []),
    ]);
  }
}
