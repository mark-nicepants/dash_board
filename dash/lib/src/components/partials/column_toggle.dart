import 'dart:convert';

import 'package:dash/src/table/columns/column.dart';
import 'package:jaspr/jaspr.dart';

/// Column visibility toggle component with Alpine.js-powered interactivity.
class ColumnToggle extends StatelessComponent {
  final List<TableColumn> columns;
  final String resourceSlug;

  const ColumnToggle({required this.columns, required this.resourceSlug, super.key});

  @override
  Component build(BuildContext context) {
    final defaults = {for (final column in columns) column.getName(): !column.isToggledHiddenByDefault()};
    final encodedDefaults = jsonEncode(defaults);

    return div(
      classes: 'relative',
      attributes: {'x-data': "columnVisibility('$resourceSlug', $encodedDefaults)", 'x-cloak': ''},
      [
        button(
          type: ButtonType.button,
          classes:
              'inline-flex items-center gap-2 px-3 py-2 text-sm font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 rounded-lg transition-all',
          attributes: {'x-on:click': 'open = !open', 'x-bind:aria-expanded': 'open', 'aria-haspopup': 'true'},
          [
            span(classes: 'text-base', [text('☰')]),
            span([text('Columns')]),
          ],
        ),
        div(
          classes:
              'absolute right-0 top-full mt-2 min-w-56 bg-gray-900 border border-gray-700 rounded-lg p-3 shadow-2xl z-50',
          attributes: {'x-show': 'open', 'x-transition.opacity': '', '@click.outside': 'open = false'},
          [
            div(classes: 'text-sm font-semibold text-gray-100 mb-2', [text('Toggle columns')]),
            ul(classes: 'space-y-1.5 mb-3', [
              for (final column in columns)
                li([
                  button(
                    type: ButtonType.button,
                    classes:
                        'w-full flex items-center gap-2 px-2 py-1.5 border border-transparent rounded-lg bg-transparent text-gray-200 hover:bg-gray-800 cursor-pointer transition-all',
                    attributes: {
                      'x-on:click': "toggle('${column.getName()}')",
                      'x-bind:class': "{'border-gray-600 bg-gray-950': isVisible('${column.getName()}')}",
                    },
                    [
                      span(
                        classes: 'w-5 text-center text-lime-500 font-bold',
                        attributes: {'x-show': "isVisible('${column.getName()}')"},
                        [text('✓')],
                      ),
                      span(classes: 'flex-1 text-sm text-left', [text(column.getLabel())]),
                    ],
                  ),
                ]),
            ]),
            div(classes: 'flex gap-2 flex-wrap', [
              button(
                type: ButtonType.button,
                classes:
                    'px-2 py-1 text-xs font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 rounded transition-all',
                attributes: {'x-on:click': 'showAll()'},
                [text('Show all')],
              ),
              button(
                type: ButtonType.button,
                classes:
                    'px-2 py-1 text-xs font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 rounded transition-all',
                attributes: {'x-on:click': 'hideAll()'},
                [text('Hide all')],
              ),
              button(
                type: ButtonType.button,
                classes:
                    'px-2 py-1 text-xs font-medium bg-gray-700 text-gray-300 hover:bg-gray-600 rounded transition-all',
                attributes: {'x-on:click': 'reset()'},
                [text('Reset')],
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
