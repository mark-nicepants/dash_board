import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// A search input component for filtering table data.
class TableSearchInput extends StatelessComponent {
  final String? value;
  final String placeholder;
  final String modelProperty;
  final String debounceInterval;

  const TableSearchInput({
    this.value,
    this.placeholder = 'Search...',
    this.modelProperty = 'searchQuery',
    this.debounceInterval = '500ms',
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final primary = inject<PanelConfig>().colors.primary;
    final bindingAttribute = 'wire:model.debounce.$debounceInterval';
    final attributes = <String, String>{
      'placeholder': placeholder,
      bindingAttribute: modelProperty,
      'autocomplete': 'off',
      'inputmode': 'search',
    };

    return div(classes: 'flex-1 max-w-xs', [
      input(
        id: 'resource-search-input',
        type: InputType.text,
        classes:
            'w-full px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:ring-2 focus:ring-$primary-500 focus:border-transparent transition-all',
        value: value ?? '',
        name: 'search',
        attributes: attributes,
      ),
    ]);
  }
}
