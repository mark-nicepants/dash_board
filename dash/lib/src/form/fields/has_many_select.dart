import 'dart:convert';

import 'package:dash_board/src/components/partials/forms/form_components.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:dash_board/src/form/fields/relationship_select.dart';
import 'package:dash_board/src/model/annotations.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shelf/shelf.dart';

/// A multi-select field for HasMany relationships with async search support.
///
/// This field provides a searchable multi-select dropdown for selecting
/// multiple related records via a pivot table. It supports:
/// - Async search with debouncing
/// - Preloading of initial options
/// - Custom display formatting
/// - Tag-style display of selected items
///
/// Example:
/// ```dart
/// HasManySelect.make('tags')
///   .relationship('tags', 'Tag')
///   .label('Tags')
///   .displayColumn('name')
///   .preload(limit: 20),
/// ```
class HasManySelect extends FormField {
  /// The relationship name (e.g., 'tags').
  String? _relationName;

  /// The related model type (e.g., 'Tag').
  String? _relatedModel;

  /// The display column on the related model (default: 'name').
  String _displayColumn = 'name';

  /// The value column on the related model (default: 'id').
  String _valueColumn = 'id';

  /// Optional additional columns to search.
  List<String> _searchColumns = [];

  /// Whether the select is searchable.
  bool _searchable = true;

  /// Whether to preload initial options.
  bool _preload = false;

  /// Number of options to preload.
  int _preloadLimit = 20;

  /// Minimum characters before searching.
  int _minSearchLength = 1;

  /// Debounce interval for search (in milliseconds).
  int _debounceMs = 300;

  /// Placeholder text for the search input.
  String? _searchPlaceholder;

  /// Text to show when no results are found.
  String _noResultsText = 'No results found';

  /// Text to show while loading.
  String _loadingText = 'Searching...';

  /// Custom function to format option display.
  String Function(Map<String, dynamic>)? _displayFormatter;

  /// Pre-loaded options (for non-async use).
  List<RelationshipOption> _options = [];

  /// The currently selected options (for display).
  List<RelationshipOption> _selectedOptions = [];

  HasManySelect(super.name);

  /// Creates a new hasMany select field.
  static HasManySelect make(String name) {
    return HasManySelect(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  HasManySelect id(String id) {
    super.id(id);
    return this;
  }

  @override
  HasManySelect label(String label) {
    super.label(label);
    return this;
  }

  @override
  HasManySelect placeholder(String placeholder) {
    super.placeholder(placeholder);
    return this;
  }

  @override
  HasManySelect helperText(String text) {
    super.helperText(text);
    return this;
  }

  @override
  HasManySelect hint(String hint) {
    super.hint(hint);
    return this;
  }

  @override
  HasManySelect defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  HasManySelect required([bool required = true]) {
    super.required(required);
    return this;
  }

  @override
  HasManySelect disabled([bool disabled = true]) {
    super.disabled(disabled);
    return this;
  }

  @override
  HasManySelect readonly([bool readonly = true]) {
    super.readonly(readonly);
    return this;
  }

  @override
  HasManySelect hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  HasManySelect columnSpan(int span) {
    super.columnSpan(span);
    return this;
  }

  @override
  HasManySelect columnSpanBreakpoint(String breakpoint, int span) {
    super.columnSpanBreakpoint(breakpoint, span);
    return this;
  }

  @override
  HasManySelect columnSpanFull() {
    super.columnSpanFull();
    return this;
  }

  @override
  HasManySelect extraClasses(String classes) {
    super.extraClasses(classes);
    return this;
  }

  @override
  HasManySelect rule(ValidationRule rule) {
    super.rule(rule);
    return this;
  }

  @override
  HasManySelect rules(List<ValidationRule> rules) {
    super.rules(rules);
    return this;
  }

  @override
  HasManySelect validationMessage(String rule, String message) {
    super.validationMessage(rule, message);
    return this;
  }

  @override
  HasManySelect autofocus([bool autofocus = true]) {
    super.autofocus(autofocus);
    return this;
  }

  @override
  HasManySelect autocomplete(String value) {
    super.autocomplete(value);
    return this;
  }

  @override
  HasManySelect tabindex(int index) {
    super.tabindex(index);
    return this;
  }

  // ============================================================
  // HasMany-specific methods
  // ============================================================

  /// Sets the relationship configuration.
  ///
  /// [name] is the relationship name (e.g., 'tags').
  /// [model] is the related model type (e.g., 'Tag').
  HasManySelect relationship(String name, String model) {
    _relationName = name;
    _relatedModel = model;
    return this;
  }

  /// Gets the relationship name.
  String? getRelationName() => _relationName;

  /// Gets the related model type.
  String? getRelatedModel() => _relatedModel;

  /// Sets the display column on the related model.
  HasManySelect displayColumn(String column) {
    _displayColumn = column;
    return this;
  }

  /// Gets the display column.
  String getDisplayColumn() => _displayColumn;

  /// Sets the value column on the related model.
  HasManySelect valueColumn(String column) {
    _valueColumn = column;
    return this;
  }

  /// Gets the value column.
  String getValueColumn() => _valueColumn;

  /// Sets additional columns to search.
  HasManySelect searchColumns(List<String> columns) {
    _searchColumns = columns;
    return this;
  }

  /// Gets the search columns.
  List<String> getSearchColumns() => [_displayColumn, ..._searchColumns];

  /// Makes the select searchable.
  HasManySelect searchable([bool searchable = true]) {
    _searchable = searchable;
    return this;
  }

  /// Checks if the select is searchable.
  bool isSearchable() => _searchable;

  /// Enables preloading of options.
  HasManySelect preload({int limit = 20}) {
    _preload = true;
    _preloadLimit = limit;
    return this;
  }

  /// Checks if options should be preloaded.
  bool shouldPreload() => _preload;

  /// Gets the preload limit.
  int getPreloadLimit() => _preloadLimit;

  /// Sets the minimum search length.
  HasManySelect minSearchLength(int length) {
    _minSearchLength = length;
    return this;
  }

  /// Gets the minimum search length.
  int getMinSearchLength() => _minSearchLength;

  /// Sets the debounce interval for search.
  HasManySelect debounce(int milliseconds) {
    _debounceMs = milliseconds;
    return this;
  }

  /// Gets the debounce interval.
  int getDebounceMs() => _debounceMs;

  /// Sets the search placeholder text.
  HasManySelect searchPlaceholder(String placeholder) {
    _searchPlaceholder = placeholder;
    return this;
  }

  /// Gets the search placeholder.
  String getSearchPlaceholder() => _searchPlaceholder ?? getPlaceholder() ?? 'Search ${getLabel().toLowerCase()}...';

  /// Sets the no results text.
  HasManySelect noResultsText(String text) {
    _noResultsText = text;
    return this;
  }

  /// Gets the no results text.
  String getNoResultsText() => _noResultsText;

  /// Sets the loading text.
  HasManySelect loadingText(String text) {
    _loadingText = text;
    return this;
  }

  /// Gets the loading text.
  String getLoadingText() => _loadingText;

  /// Sets a custom display formatter.
  HasManySelect displayUsing(String Function(Map<String, dynamic>) formatter) {
    _displayFormatter = formatter;
    return this;
  }

  /// Gets the display formatter.
  String Function(Map<String, dynamic>)? getDisplayFormatter() => _displayFormatter;

  /// Formats a record for display.
  String formatDisplay(Map<String, dynamic> record) {
    if (_displayFormatter != null) {
      return _displayFormatter!(record);
    }
    return record[_displayColumn]?.toString() ?? '';
  }

  /// Sets the pre-loaded options (for static use).
  HasManySelect options(List<RelationshipOption> options) {
    _options = options;
    return this;
  }

  /// Gets the pre-loaded options.
  List<RelationshipOption> getOptions() => _options;

  /// Sets the currently selected options.
  HasManySelect selectedOptions(List<RelationshipOption> options) {
    _selectedOptions = options;
    return this;
  }

  /// Gets the currently selected options.
  List<RelationshipOption> getSelectedOptions() => _selectedOptions;

  /// HasManySelect is always multiple-select.
  bool isMultiple() => true;

  /// Converts form input to a list of IDs for the pivot table.
  @override
  dynamic dehydrateValue(dynamic value) {
    // First apply any custom dehydration callback
    final result = super.dehydrateValue(value);

    if (result == null) return [];

    // Handle various input formats
    if (result is List) {
      // Convert list items to appropriate types (integers if possible)
      return result.map((item) {
        if (item is int) return item;
        if (item is String) {
          final asInt = int.tryParse(item);
          return asInt ?? item;
        }
        return item;
      }).toList();
    }

    if (result is String) {
      if (result.isEmpty) return [];

      // Handle comma-separated values
      if (result.contains(',')) {
        return result.split(',').map((s) {
          final trimmed = s.trim();
          final asInt = int.tryParse(trimmed);
          return asInt ?? trimmed;
        }).toList();
      }

      // Handle JSON array
      if (result.startsWith('[')) {
        try {
          final parsed = jsonDecode(result) as List;
          return parsed.map((item) {
            if (item is int) return item;
            if (item is String) {
              final asInt = int.tryParse(item);
              return asInt ?? item;
            }
            return item;
          }).toList();
        } catch (_) {
          // Fall through to single value
        }
      }

      // Single value
      final asInt = int.tryParse(result);
      return [asInt ?? result];
    }

    return [result];
  }

  /// Creates metadata for this relationship field.
  RelationshipMeta? getRelationshipMeta() {
    if (_relationName == null || _relatedModel == null) return null;

    return RelationshipMeta(
      name: _relationName!,
      type: RelationshipType.hasMany,
      foreignKey: '', // Not used for hasMany
      relatedKey: _valueColumn,
      relatedModelType: _relatedModel!,
    );
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();
    final primary = inject<PanelConfig>().colors.primary;
    final defaultVal = getDefaultValue();

    // Build the multi-select combobox
    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (!isHidden()) FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // Multi-select container with Alpine.js
        div(
          attributes: {
            'x-data': _buildAlpineData(defaultVal),
            'x-on:click.away': 'close()',
            'x-on:keydown.escape.window': 'close()',
          },
          classes: 'relative',
          [
            // Hidden inputs for form submission (one per selected value)
            raw('''
              <template x-for="value in selectedValues" :key="value">
                <input type="hidden" :name="'${getName()}[]'" :value="value">
              </template>
            '''),

            // Selected tags and search input container
            div(
              classes:
                  'min-h-[42px] w-full px-2 py-1.5 bg-gray-900 border border-gray-700 rounded-lg '
                  'text-sm text-gray-200 focus-within:ring-2 focus-within:ring-$primary-500 '
                  'focus-within:border-transparent cursor-text flex flex-wrap gap-1 items-center',
              attributes: {'x-on:click': 'focusInput()'},
              [
                // Selected tags
                raw('''
                  <template x-for="option in selectedOptions" :key="option.value">
                    <span class="inline-flex items-center gap-1 px-2 py-0.5 bg-$primary-600 text-white text-xs rounded">
                      <span x-text="option.label"></span>
                      <button type="button" 
                              class="hover:bg-$primary-700 rounded-full p-0.5"
                              x-on:click.stop="removeSelection(option.value)"
                              tabindex="-1">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                        </svg>
                      </button>
                    </span>
                  </template>
                '''),

                // Search input
                input(
                  type: InputType.text,
                  id: inputId,
                  classes:
                      'flex-1 min-w-[120px] bg-transparent border-0 outline-none text-sm text-gray-200 '
                      'placeholder-gray-500 p-0.5',
                  attributes: {
                    'x-ref': 'searchInput',
                    'x-model': 'searchQuery',
                    'x-on:focus': 'open()',
                    'x-on:input.debounce.${_debounceMs}ms': 'search()',
                    'x-on:keydown.backspace':
                        'if (searchQuery === "" && selectedValues.length > 0) removeSelection(selectedValues[selectedValues.length - 1])',
                    'placeholder': getSearchPlaceholder(),
                    'autocomplete': 'off',
                    if (isDisabled()) 'disabled': '',
                    if (isReadonly()) 'readonly': '',
                    if (shouldAutofocus()) 'autofocus': '',
                  },
                ),
              ],
            ),

            // Dropdown
            div(
              classes:
                  'absolute z-50 w-full mt-1 bg-gray-800 border border-gray-700 '
                  'rounded-lg shadow-lg max-h-60 overflow-auto',
              attributes: {
                'x-show': 'isOpen',
                'x-transition:enter': 'transition ease-out duration-100',
                'x-transition:enter-start': 'opacity-0 scale-95',
                'x-transition:enter-end': 'opacity-100 scale-100',
                'x-transition:leave': 'transition ease-in duration-75',
                'x-transition:leave-start': 'opacity-100 scale-100',
                'x-transition:leave-end': 'opacity-0 scale-95',
              },
              [
                // Loading state
                div(
                  classes: 'px-4 py-3 text-sm text-gray-400',
                  attributes: {'x-show': 'loading'},
                  [text(_loadingText)],
                ),

                // No results
                div(
                  classes: 'px-4 py-3 text-sm text-gray-400',
                  attributes: {'x-show': '!loading && filteredOptions.length === 0 && searchQuery.length > 0'},
                  [text(_noResultsText)],
                ),

                // Options list
                ul(
                  classes: 'py-1',
                  attributes: {'x-show': '!loading && filteredOptions.length > 0'},
                  [
                    raw('''
                      <template x-for="option in filteredOptions" :key="option.value">
                        <li>
                          <button type="button"
                            class="w-full px-4 py-2 text-left text-sm text-gray-200 hover:bg-$primary-600 hover:text-white focus:outline-none focus:bg-$primary-600 focus:text-white flex items-center justify-between"
                            x-on:click="toggleSelection(option)"
                            x-bind:class="isSelected(option.value) ? 'bg-$primary-700' : ''">
                            <span x-text="option.label"></span>
                            <svg x-show="isSelected(option.value)" class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
                            </svg>
                          </button>
                        </li>
                      </template>
                    '''),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Helper text
        if (getHelperText() != null) FormHelperText(helperText: getHelperText()!),
      ],
    );
  }

  String _buildAlpineData(dynamic defaultVal) {
    final searchEndpoint = '/dash/relationship-search/${_relatedModel?.toLowerCase() ?? 'model'}';

    // Build initial options JSON
    final optionsJson = _options.isEmpty
        ? '[]'
        : '[${_options.map((o) => '{"value":"${o.value}","label":"${_escapeJs(o.label)}"}').join(',')}]';

    // Build selected values/options from default value or selected options
    String selectedValuesJson = '[]';
    String selectedOptionsJson = '[]';

    if (_selectedOptions.isNotEmpty) {
      selectedValuesJson = '[${_selectedOptions.map((o) => '"${o.value}"').join(',')}]';
      selectedOptionsJson =
          '[${_selectedOptions.map((o) => '{"value":"${o.value}","label":"${_escapeJs(o.label)}"}').join(',')}]';
    } else if (defaultVal != null) {
      if (defaultVal is List) {
        selectedValuesJson = '[${defaultVal.map((v) => '"$v"').join(',')}]';
      } else if (defaultVal is String && defaultVal.isNotEmpty) {
        if (defaultVal.contains(',')) {
          selectedValuesJson = '[${defaultVal.split(',').map((v) => '"${v.trim()}"').join(',')}]';
        } else {
          selectedValuesJson = '["$defaultVal"]';
        }
      }
    }

    return '''
      {
        isOpen: false,
        loading: false,
        searchQuery: '',
        selectedValues: $selectedValuesJson,
        selectedOptions: $selectedOptionsJson,
        options: $optionsJson,
        searchEndpoint: '$searchEndpoint',
        displayColumn: '$_displayColumn',
        valueColumn: '$_valueColumn',
        searchColumns: ${_buildSearchColumnsJson()},
        minSearchLength: $_minSearchLength,
        
        get filteredOptions() {
          // Filter out already selected options
          return this.options.filter(o => !this.isSelected(o.value));
        },
        
        init() {
          ${_preload ? 'this.preloadOptions();' : ''}
          // If we have selected values but no options, load them
          if (this.selectedValues.length > 0 && this.selectedOptions.length === 0) {
            this.loadSelectedOptions();
          }
        },
        
        focusInput() {
          this.\$refs.searchInput.focus();
        },
        
        toggle() {
          this.isOpen = !this.isOpen;
          if (this.isOpen && this.options.length === 0) {
            this.preloadOptions();
          }
        },
        
        open() {
          this.isOpen = true;
          if (this.options.length === 0) {
            this.preloadOptions();
          }
        },
        
        close() {
          this.isOpen = false;
          this.searchQuery = '';
        },
        
        isSelected(value) {
          return this.selectedValues.includes(String(value)) || this.selectedValues.includes(Number(value));
        },
        
        toggleSelection(option) {
          if (this.isSelected(option.value)) {
            this.removeSelection(option.value);
          } else {
            this.addSelection(option);
          }
        },
        
        addSelection(option) {
          if (!this.isSelected(option.value)) {
            this.selectedValues.push(option.value);
            this.selectedOptions.push(option);
          }
          this.searchQuery = '';
          this.\$refs.searchInput.focus();
        },
        
        removeSelection(value) {
          const strValue = String(value);
          const numValue = Number(value);
          this.selectedValues = this.selectedValues.filter(v => String(v) !== strValue && v !== numValue);
          this.selectedOptions = this.selectedOptions.filter(o => String(o.value) !== strValue && o.value !== numValue);
        },
        
        async loadSelectedOptions() {
          if (this.selectedValues.length === 0) return;
          
          try {
            const params = new URLSearchParams({
              ids: this.selectedValues.join(',')
            });
            const response = await fetch(this.searchEndpoint + '?' + params, {
              headers: { 'Accept': 'application/json' }
            });
            if (response.ok) {
              const data = await response.json();
              this.selectedOptions = (data.options || []).filter(o => this.selectedValues.includes(String(o.value)) || this.selectedValues.includes(Number(o.value)));
            }
          } catch (e) {
            console.error('Failed to load selected options:', e);
          }
        },
        
        async preloadOptions() {
          this.loading = true;
          try {
            const response = await fetch(this.searchEndpoint + '?limit=$_preloadLimit', {
              headers: { 'Accept': 'application/json' }
            });
            if (response.ok) {
              const data = await response.json();
              this.options = data.options || [];
            }
          } catch (e) {
            console.error('Failed to preload options:', e);
          }
          this.loading = false;
        },
        
        async search() {
          if (this.searchQuery.length < this.minSearchLength) {
            return;
          }
          
          this.loading = true;
          try {
            const params = new URLSearchParams({
              q: this.searchQuery,
              columns: this.searchColumns.join(',')
            });
            const response = await fetch(this.searchEndpoint + '?' + params, {
              headers: { 'Accept': 'application/json' }
            });
            if (response.ok) {
              const data = await response.json();
              this.options = data.options || [];
            }
          } catch (e) {
            console.error('Search failed:', e);
          }
          this.loading = false;
        }
      }
    ''';
  }

  String _buildSearchColumnsJson() {
    final columns = getSearchColumns();
    return '[${columns.map((c) => '"$c"').join(',')}]';
  }

  String _escapeJs(String value) {
    return value.replaceAll("'", "\\'").replaceAll('"', '\\"').replaceAll('\n', '\\n');
  }

  /// Infers configuration from relationship metadata.
  void inferFrom(RelationshipMeta meta) {
    _relationName ??= meta.name;
    _relatedModel ??= meta.relatedModelType;
    // Default search columns to display column if not set
    if (_searchColumns.isEmpty) {
      _searchColumns = [_displayColumn];
    }
  }
}

/// Handler for hasMany relationship search requests.
///
/// This extends the RelationshipSearchHandler to support loading
/// records by ID for the selected options.
class HasManySearchHandler {
  /// Handles a hasMany relationship search request.
  ///
  /// Query parameters:
  /// - `q` - Search query string
  /// - `ids` - Comma-separated list of IDs to load (for selected options)
  /// - `columns` - Comma-separated list of columns to search
  /// - `limit` - Maximum number of results (default: 20)
  /// - `display` - Column to use for display (default: 'name')
  /// - `value` - Column to use for value (default: 'id')
  Future<Response> handle(Request request, String modelSlug) async {
    final queryParams = request.url.queryParameters;
    final searchQuery = queryParams['q'] ?? '';
    final idsParam = queryParams['ids'];
    final columns = (queryParams['columns'] ?? 'name').split(',');
    final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
    final displayColumn = queryParams['display'] ?? 'name';
    final valueColumn = queryParams['value'] ?? 'id';

    try {
      // Find the resource that handles this model
      final resource = resourceFromSlug(modelSlug);
      final queryBuilder = resource.query();

      // If specific IDs are requested, load those
      if (idsParam != null && idsParam.isNotEmpty) {
        final ids = idsParam.split(',').map((s) {
          final trimmed = s.trim();
          return int.tryParse(trimmed) ?? trimmed;
        }).toList();

        queryBuilder.whereIn(valueColumn, ids);
      } else if (searchQuery.isNotEmpty) {
        // Add search conditions
        for (var i = 0; i < columns.length; i++) {
          final column = columns[i].trim();
          if (i == 0) {
            queryBuilder.where(column, 'LIKE', '%$searchQuery%');
          } else {
            queryBuilder.orWhere(column, 'LIKE', '%$searchQuery%');
          }
        }
        queryBuilder.limit(limit);
      } else {
        // Preload - just get first N results
        queryBuilder.limit(limit);
      }

      // Get results
      final records = await queryBuilder.get();

      // Convert to options
      final options = records.map((record) {
        final map = record.toMap();
        return RelationshipOption.fromMap(map, valueColumn: valueColumn, displayColumn: displayColumn).toJson();
      }).toList();

      return _jsonResponse({'options': options});
    } catch (e) {
      return _jsonResponse({'error': e.toString()}, status: 500);
    }
  }

  Response _jsonResponse(Map<String, dynamic> data, {int status = 200}) {
    return Response(status, body: jsonEncode(data), headers: {'Content-Type': 'application/json'});
  }
}
