import 'package:jaspr/jaspr.dart';

class BreadCrumbs extends StatelessComponent {
  final List<BreadCrumbItem> items;

  const BreadCrumbs({required this.items, super.key});

  @override
  Component build(BuildContext context) {
    return nav(classes: 'breadcrumbs', [
      ol(classes: 'breadcrumb-list', [
        for (int i = 0; i < items.length; i++) ...[
          li(classes: 'breadcrumb-item', [
            if (items[i].url != null)
              a(href: items[i].url!, classes: 'breadcrumb-link', [text(items[i].label)])
            else
              span(classes: 'breadcrumb-current', [text(items[i].label)]),
          ]),
          if (i < items.length - 1) li(classes: 'breadcrumb-separator', [text('›')]),
        ],
      ]),
    ]);
  }
}

class BreadCrumbItem {
  final String label;
  final String? url;

  const BreadCrumbItem({required this.label, this.url});
}
