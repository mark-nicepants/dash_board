import 'package:dash_board/src/components/partials/breadcrumbs.dart';
import 'package:dash_board/src/components/partials/page_header.dart';
import 'package:jaspr/jaspr.dart';

/// Shared scaffold for resource pages that need a header and body stack.
class ResourcePageScaffold extends StatelessComponent {
  final String title;
  final List<BreadCrumbItem> breadcrumbs;
  final List<Component> children;
  final List<Component> actions;

  const ResourcePageScaffold({
    required this.title,
    required this.breadcrumbs,
    required this.children,
    this.actions = const [],
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return div(classes: 'flex flex-col gap-6', [
      PageHeader(
        title: title,
        breadcrumbs: BreadCrumbs(items: breadcrumbs),
        actions: actions,
      ),
      ...children,
    ]);
  }
}
