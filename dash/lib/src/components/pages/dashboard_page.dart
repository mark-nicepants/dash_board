import 'package:dash_board/src/components/partials/card.dart';
import 'package:dash_board/src/plugin/render_hook.dart';
import 'package:dash_board/src/widgets/widget.dart';
import 'package:jaspr/jaspr.dart';

/// Dashboard home page component.
///
/// Displays registered widgets in a responsive grid layout.
/// Widgets are sorted by their [Widget.sort] property and filtered
/// by their [Widget.canView] method.
///
/// Also renders dashboard render hooks at the start and end.
class DashboardPage extends StatelessComponent {
  /// The widgets to display on the dashboard.
  final List<Widget> widgets;

  /// Render hooks registry for dashboard hooks.
  final RenderHookRegistry? renderHooks;

  const DashboardPage({this.widgets = const [], this.renderHooks, super.key});

  @override
  Component build(BuildContext context) {
    // Filter and sort widgets
    final visibleWidgets = widgets.where((w) => w.canView()).toList()..sort((a, b) => a.sort.compareTo(b.sort));

    return div(classes: 'space-y-6', [
      // Render hook: dashboard start
      ...?renderHooks?.render(RenderHook.dashboardStart),

      // Dashboard header
      div(classes: 'mb-8', [
        h1(classes: 'text-3xl font-bold text-white', [text('Dashboard')]),
        p(classes: 'mt-2 text-gray-400', [text('Welcome to your admin panel')]),
      ]),

      // Widgets grid
      if (visibleWidgets.isNotEmpty)
        div(classes: 'grid grid-cols-12 gap-6', [
          for (final widget in visibleWidgets) div(classes: _getColumnClasses(widget.columnSpan), [widget.render()]),
        ])
      else
        // Default welcome card if no widgets
        Card(
          child: div([
            h3(classes: 'text-xl font-semibold text-gray-100 mb-3', [text('Welcome to DASH')]),
            p(classes: 'text-gray-400', [
              text('Your modern admin panel for Dart applications. '),
              text('Register widgets using panel.widgets([...]) to customize this dashboard.'),
            ]),
          ]),
        ),

      // Render hook: dashboard end
      ...?renderHooks?.render(RenderHook.dashboardEnd),
    ]);
  }

  /// Converts column span to responsive Tailwind classes.
  String _getColumnClasses(int span) {
    // Ensure span is within valid range
    final clampedSpan = span.clamp(1, 12);

    // On small screens, most widgets go full width
    // On medium screens, half width for smaller widgets
    // On large screens, use actual span
    if (clampedSpan <= 4) {
      return 'col-span-12 md:col-span-6 lg:col-span-$clampedSpan';
    } else if (clampedSpan <= 6) {
      return 'col-span-12 md:col-span-6 lg:col-span-$clampedSpan';
    } else {
      return 'col-span-12 lg:col-span-$clampedSpan';
    }
  }
}
