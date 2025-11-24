import 'package:jaspr/jaspr.dart';

class PageHeader extends StatelessComponent {
  final String title;
  final List<Component>? actions;

  const PageHeader({required this.title, this.actions, super.key});

  @override
  Component build(BuildContext context) {
    return div(classes: 'page-header', [
      h1(classes: 'page-header-title', [text(title)]),
      if (actions != null && actions!.isNotEmpty) div(classes: 'page-header-actions', actions!),
    ]);
  }
}
