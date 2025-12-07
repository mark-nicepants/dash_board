import 'dart:convert';

import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:dash_board/src/table/columns/column.dart';
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
    final primary = panelColors.primary;

    return div(
      classes: 'relative',
      attributes: {'x-data': "columnVisibility('$resourceSlug', $encodedDefaults)", 'x-cloak': ''},
      [
        button(
          type: ButtonType.button,
          classes:
              'inline-flex items-center justify-center px-3 py-2 text-sm font-medium bg-gray-700 border border-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 rounded-lg transition-all',
          attributes: {'x-on:click': 'open = !open', 'x-bind:aria-expanded': 'open', 'aria-haspopup': 'true'},
          [const Heroicon(HeroIcons.viewColumns, size: 20)],
        ),
        div(
          classes:
              'absolute right-0 top-full mt-2 min-w-48 bg-gray-900 border border-gray-700 rounded-lg p-2 shadow-2xl z-50',
          attributes: {'x-show': 'open', 'x-transition.opacity': '', '@click.outside': 'open = false'},
          [
            ul(classes: 'space-y-0.5', [
              for (final column in columns)
                li([
                  label(
                    classes:
                        'flex items-center gap-2.5 px-2 py-1.5 rounded-lg text-gray-200 hover:bg-gray-800 cursor-pointer transition-all',
                    [
                      input(
                        classes:
                            'w-4 h-4 rounded border-gray-600 bg-gray-800 text-$primary-500 focus:ring-$primary-500 focus:ring-offset-gray-900 cursor-pointer',
                        type: InputType.checkbox,
                        attributes: {
                          'x-bind:checked': "isVisible('${column.getName()}')",
                          'x-on:change': "toggle('${column.getName()}')",
                        },
                      ),
                      span(classes: 'text-sm select-none', [text(column.getLabel())]),
                    ],
                  ),
                ]),
            ]),
          ],
        ),
      ],
    );
  }
}
