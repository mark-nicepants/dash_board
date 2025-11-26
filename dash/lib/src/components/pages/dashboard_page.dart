import 'package:dash/src/components/partials/button.dart';
import 'package:dash/src/components/partials/card.dart';
import 'package:jaspr/jaspr.dart';

/// Dashboard home page component.
class DashboardPage extends StatelessComponent {
  final String? resource;

  const DashboardPage({this.resource, super.key});

  @override
  Component build(BuildContext context) {
    final title = resource != null ? resource!.toUpperCase() : 'Dashboard';

    return div(classes: 'space-y-6', [
      if (resource == null) ...[
        // Dashboard widgets
        div(classes: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6', [
          Card(
            child: div([
              h3(classes: 'text-xl font-semibold text-gray-100 mb-3', [text('Welcome to DASH')]),
              p(classes: 'text-gray-400', [text('Your modern admin panel for Dart applications.')]),
            ]),
          ),
          Card(
            child: div([
              h3(classes: 'text-xl font-semibold text-gray-100 mb-3', [text('Quick Stats')]),
              ul(classes: 'space-y-2 text-gray-300', [
                li(classes: 'py-2 border-b border-gray-700 last:border-0', [text('Total Users: 10')]),
                li(classes: 'py-2 border-b border-gray-700 last:border-0', [text('Total Posts: 25')]),
                li(classes: 'py-2 border-b border-gray-700 last:border-0', [text('Active Sessions: 3')]),
              ]),
            ]),
          ),
        ]),
      ] else ...[
        // Resource list view
        Card(
          child: div([
            div(classes: 'flex justify-between items-center mb-6', [
              h2(classes: 'text-2xl font-bold text-gray-100', [text(title)]),
              const Button(label: '+ New', variant: ButtonVariant.primary),
            ]),
            div([
              p(classes: 'text-gray-400', [text('Resource table for $resource will be displayed here.')]),
            ]),
          ]),
        ),
      ],
    ]);
  }
}
