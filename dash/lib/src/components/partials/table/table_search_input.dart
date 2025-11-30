import 'package:dash/src/panel/panel_config.dart';
import 'package:dash/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// A search input component for filtering table data.
class TableSearchInput extends StatelessComponent {
  final String? value;
  final String placeholder;

  const TableSearchInput({this.value, this.placeholder = 'Search...', super.key});

  @override
  Component build(BuildContext context) {
    final primary = inject<PanelConfig>().colors.primary;
    return div(classes: 'flex-1 max-w-xs', [
      input(
        id: 'resource-search-input',
        type: InputType.text,
        classes:
            'w-full px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-$primary-500 focus:border-transparent transition-all',
        value: value ?? '',
        name: 'search',
        attributes: {'placeholder': placeholder},
      ),
    ]);
  }
}
