import 'dart:convert';

import 'package:dash_board/src/components/partials/forms/form_components.dart';
import 'package:dash_board/src/database/migrations/schema_definition.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:dash_board/src/model/annotations.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';
import 'package:shelf/shelf.dart';

/// A select field for BelongsTo relationships with async search support.
///
/// This field provides a searchable dropdown for selecting related records.
/// It uses DashWire for server-side search and supports:
/// - Async search with debouncing
/// - Preloading of initial options
/// - Custom display formatting
/// - Option to create new records (optional)
///
/// Example:
/// ```dart
/// RelationshipSelect.make('author')
///   .relationship('author', 'User')
///   .label('Author')
///   .searchable()
///   .placeholder('Search for a user...')
///   .displayUsing((record) => record['name'])
///   .preload(limit: 10),
/// ```
class RelationshipSelect extends FormField {
  /// The relationship name (e.g., 'author').
  String? _relationName;

  /// The related model type (e.g., 'User').
  String? _relatedModel;

  /// The foreign key column in the current model.
  String? _foreignKey;

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
  int _preloadLimit = 10;

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

  /// Whether to allow creating new records.
  bool _creatable = false;

  /// The URL for creating new records.
  String? _createUrl;

  /// Custom function to format option display.
  String Function(Map<String, dynamic>)? _displayFormatter;

  /// Pre-loaded options (for non-async use).
  List<RelationshipOption> _options = [];

  /// The currently selected option (for display).
  RelationshipOption? _selectedOption;

  RelationshipSelect(super.name);

  /// Creates a new relationship select field.
  static RelationshipSelect make(String name) {
    return RelationshipSelect(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  RelationshipSelect id(String id) {
    super.id(id);
    return this;
  }

  @override
  RelationshipSelect label(String label) {
    super.label(label);
    return this;
  }

  @override
  RelationshipSelect placeholder(String placeholder) {
    super.placeholder(placeholder);
    return this;
  }

  @override
  RelationshipSelect helperText(String text) {
    super.helperText(text);
    return this;
  }

  @override
  RelationshipSelect hint(String hint) {
    super.hint(hint);
    return this;
  }

  @override
  RelationshipSelect defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  RelationshipSelect required([bool required = true]) {
    super.required(required);
    return this;
  }

  @override
  RelationshipSelect disabled([bool disabled = true]) {
    super.disabled(disabled);
    return this;
  }

  @override
  RelationshipSelect readonly([bool readonly = true]) {
    super.readonly(readonly);
    return this;
  }

  @override
  RelationshipSelect hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  RelationshipSelect columnSpan(int span) {
    super.columnSpan(span);
    return this;
  }

  @override
  RelationshipSelect columnSpanBreakpoint(String breakpoint, int span) {
    super.columnSpanBreakpoint(breakpoint, span);
    return this;
  }

  @override
  RelationshipSelect columnSpanFull() {
    super.columnSpanFull();
    return this;
  }

  @override
  RelationshipSelect extraClasses(String classes) {
    super.extraClasses(classes);
    return this;
  }

  @override
  RelationshipSelect rule(ValidationRule rule) {
    super.rule(rule);
    return this;
  }

  @override
  RelationshipSelect rules(List<ValidationRule> rules) {
    super.rules(rules);
    return this;
  }

  @override
  RelationshipSelect validationMessage(String rule, String message) {
    super.validationMessage(rule, message);
    return this;
  }

  @override
  RelationshipSelect autofocus([bool autofocus = true]) {
    super.autofocus(autofocus);
    return this;
  }

  @override
  RelationshipSelect autocomplete(String value) {
    super.autocomplete(value);
    return this;
  }

  @override
  RelationshipSelect tabindex(int index) {
    super.tabindex(index);
    return this;
  }

  // ============================================================
  // Relationship-specific methods
  // ============================================================

  /// Sets the relationship configuration.
  ///
  /// [name] is the relationship name (e.g., 'author').
  /// [model] is the related model type (e.g., 'User').
  /// [foreignKey] is optional and defaults to '{name}_id'.
  RelationshipSelect relationship(String name, String model, {String? foreignKey}) {
    _relationName = name;
    _relatedModel = model;
    _foreignKey = foreignKey ?? '${name}_id';
    return this;
  }

  /// Gets the relationship name.
  String? getRelationName() => _relationName;

  /// Gets the related model type.
  String? getRelatedModel() => _relatedModel;

  /// Gets the foreign key column.
  String? getForeignKey() => _foreignKey;

  /// Sets the display column on the related model.
  RelationshipSelect displayColumn(String column) {
    _displayColumn = column;
    return this;
  }

  /// Gets the display column.
  String getDisplayColumn() => _displayColumn;

  /// Sets the value column on the related model.
  RelationshipSelect valueColumn(String column) {
    _valueColumn = column;
    return this;
  }

  /// Gets the value column.
  String getValueColumn() => _valueColumn;

  /// Sets additional columns to search.
  RelationshipSelect searchColumns(List<String> columns) {
    _searchColumns = columns;
    return this;
  }

  /// Gets the search columns.
  List<String> getSearchColumns() => [_displayColumn, ..._searchColumns];

  /// Makes the select searchable.
  RelationshipSelect searchable([bool searchable = true]) {
    _searchable = searchable;
    return this;
  }

  /// Checks if the select is searchable.
  bool isSearchable() => _searchable;

  /// Enables preloading of options.
  RelationshipSelect preload({int limit = 10}) {
    _preload = true;
    _preloadLimit = limit;
    return this;
  }

  /// Checks if options should be preloaded.
  bool shouldPreload() => _preload;

  /// Gets the preload limit.
  int getPreloadLimit() => _preloadLimit;

  /// Sets the minimum search length.
  RelationshipSelect minSearchLength(int length) {
    _minSearchLength = length;
    return this;
  }

  /// Gets the minimum search length.
  int getMinSearchLength() => _minSearchLength;

  /// Sets the debounce interval for search.
  RelationshipSelect debounce(int milliseconds) {
    _debounceMs = milliseconds;
    return this;
  }

  /// Gets the debounce interval.
  int getDebounceMs() => _debounceMs;

  /// Sets the search placeholder text.
  RelationshipSelect searchPlaceholder(String placeholder) {
    _searchPlaceholder = placeholder;
    return this;
  }

  /// Gets the search placeholder.
  String getSearchPlaceholder() => _searchPlaceholder ?? getPlaceholder() ?? 'Search ${getLabel().toLowerCase()}...';

  /// Sets the no results text.
  RelationshipSelect noResultsText(String text) {
    _noResultsText = text;
    return this;
  }

  /// Gets the no results text.
  String getNoResultsText() => _noResultsText;

  /// Sets the loading text.
  RelationshipSelect loadingText(String text) {
    _loadingText = text;
    return this;
  }

  /// Gets the loading text.
  String getLoadingText() => _loadingText;

  /// Allows creating new records.
  RelationshipSelect creatable({String? createUrl}) {
    _creatable = true;
    _createUrl = createUrl;
    return this;
  }

  /// Checks if creating is allowed.
  bool isCreatable() => _creatable;

  /// Gets the create URL.
  String? getCreateUrl() => _createUrl;

  /// Sets a custom display formatter.
  ///
  /// The formatter receives the full record map and returns
  /// the display string.
  ///
  /// Example:
  /// ```dart
  /// .displayUsing((record) => '${record['name']} (${record['email']})')
  /// ```
  RelationshipSelect displayUsing(String Function(Map<String, dynamic>) formatter) {
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
  RelationshipSelect options(List<RelationshipOption> options) {
    _options = options;
    return this;
  }

  /// Gets the pre-loaded options.
  List<RelationshipOption> getOptions() => _options;

  /// Sets the currently selected option.
  RelationshipSelect selectedOption(RelationshipOption option) {
    _selectedOption = option;
    return this;
  }

  /// Gets the currently selected option.
  RelationshipOption? getSelectedOption() => _selectedOption;

  /// RelationshipSelect is always single-select (for belongsTo relationships).
  /// This method exists for compatibility with the Select field interface.
  bool isMultiple() => false;

  /// Converts form input to the appropriate type for the foreign key column.
  /// Uses the model's schema to determine the correct column type.
  @override
  dynamic dehydrateValue(dynamic value) {
    // First apply any custom dehydration callback
    final result = super.dehydrateValue(value);

    if (result == null || (result is String && result.isEmpty)) return null;

    // Try to get the column type from the model's schema
    final foreignKey = _foreignKey ?? '${_relationName}_id';
    ColumnType? columnType;

    if (record != null) {
      final column = record!.schema.getColumn(foreignKey);
      columnType = column?.type;
    }

    // Convert based on column type or infer from value
    switch (columnType) {
      case ColumnType.integer:
        if (result is int) return result;
        if (result is String) return int.tryParse(result);
        return null;
      case ColumnType.text:
        return result.toString();
      case ColumnType.real:
        if (result is double) return result;
        if (result is String) return double.tryParse(result);
        return null;
      default:
        // No schema available or unknown type - try to infer
        // If it looks like a number, convert it
        if (result is int) return result;
        if (result is String) {
          final asInt = int.tryParse(result);
          if (asInt != null) return asInt;
        }
        return result;
    }
  }

  /// Creates metadata for this relationship field.
  RelationshipMeta? getRelationshipMeta() {
    if (_relationName == null || _relatedModel == null) return null;

    return RelationshipMeta(
      name: _relationName!,
      type: RelationshipType.belongsTo,
      foreignKey: _foreignKey ?? '${_relationName}_id',
      relatedKey: _valueColumn,
      relatedModelType: _relatedModel!,
    );
  }

  /// Infers configuration from relationship metadata.
  void inferFrom(RelationshipMeta meta) {
    _relationName ??= meta.name;
    _relatedModel ??= meta.relatedModelType;
    _foreignKey ??= meta.foreignKey;
    // Default search columns to display column if not set
    if (_searchColumns.isEmpty) {
      _searchColumns = [_displayColumn];
    }
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();
    final primary = inject<PanelConfig>().colors.primary;
    final defaultVal = getDefaultValue();

    // Build the searchable combobox
    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (!isHidden()) FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // Combobox container with Alpine.js
        div(
          attributes: {
            'x-data': _buildAlpineData(defaultVal),
            'x-on:click.away': 'close()',
            'x-on:keydown.escape.window': 'close()',
          },
          classes: 'relative',
          [
            // Hidden input for form submission
            input(type: InputType.hidden, name: getName(), attributes: {'x-model': 'selectedValue'}),

            // Search input / display field
            div(classes: 'relative', [
              input(
                type: InputType.text,
                id: inputId,
                classes: _getInputClasses(primary),
                attributes: {
                  'x-model': 'searchQuery',
                  'x-on:focus': 'open()',
                  'x-on:input.debounce.${_debounceMs}ms': 'search()',
                  'x-bind:placeholder': "selectedLabel || '${getSearchPlaceholder()}'",
                  'autocomplete': 'off',
                  if (isDisabled()) 'disabled': '',
                  if (isReadonly()) 'readonly': '',
                  if (shouldAutofocus()) 'autofocus': '',
                },
              ),

              // Selected display overlay
              span(
                classes: 'absolute inset-y-0 left-0 flex items-center pl-3 pointer-events-none',
                attributes: {'x-show': 'selectedLabel && !isOpen', 'x-text': 'selectedLabel'},
                [],
              ),

              // Dropdown indicator
              button(
                type: ButtonType.button,
                classes: 'absolute inset-y-0 right-0 flex items-center pr-3',
                attributes: {'x-on:click': 'toggle()', 'tabindex': '-1'},
                [
                  raw('''
                    <svg class="w-4 h-4 text-gray-400" x-bind:class="isOpen ? 'rotate-180' : ''" 
                         fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                            d="M19 9l-7 7-7-7"/>
                    </svg>
                  '''),
                ],
              ),

              // Clear button
              button(
                type: ButtonType.button,
                classes: 'absolute inset-y-0 right-8 flex items-center pr-2',
                attributes: {'x-show': 'selectedValue', 'x-on:click': 'clear()', 'tabindex': '-1'},
                [
                  raw('''
                    <svg class="w-4 h-4 text-gray-400 hover:text-gray-200" fill="none" 
                         stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                            d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                  '''),
                ],
              ),
            ]),

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
                  attributes: {'x-show': '!loading && options.length === 0 && searchQuery.length > 0'},
                  [text(_noResultsText)],
                ),

                // Options list
                ul(
                  classes: 'py-1',
                  attributes: {'x-show': '!loading && options.length > 0'},
                  [
                    raw('''
                      <template x-for="option in options" :key="option.value">
                        <li>
                          <button type="button"
                            class="w-full px-4 py-2 text-left text-sm text-gray-200 hover:bg-$primary-600 hover:text-white focus:outline-none focus:bg-$primary-600 focus:text-white"
                            x-on:click="select(option)"
                            x-text="option.label"
                            x-bind:class="selectedValue == option.value ? 'bg-$primary-700' : ''">
                          </button>
                        </li>
                      </template>
                    '''),
                  ],
                ),

                // Create option
                if (_creatable)
                  div(
                    classes: 'border-t border-gray-700',
                    attributes: {'x-show': 'searchQuery.length > 0'},
                    [
                      button(
                        type: ButtonType.button,
                        classes:
                            'w-full px-4 py-2 text-left text-sm text-$primary-400 '
                            'hover:bg-gray-700 focus:outline-none',
                        attributes: {'x-on:click': 'createNew()'},
                        [
                          raw('''
                            <span class="flex items-center gap-2">
                              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" 
                                      d="M12 4v16m8-8H4"/>
                              </svg>
                              <span>Create "<span x-text="searchQuery"></span>"</span>
                            </span>
                          '''),
                        ],
                      ),
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

  String _getInputClasses(String primary) {
    return 'w-full px-3 py-2 bg-gray-900 border border-gray-700 rounded-lg '
        'text-sm text-gray-200 placeholder-gray-500 '
        'focus:outline-none focus:ring-2 focus:ring-$primary-500 focus:border-transparent '
        'disabled:opacity-50 disabled:cursor-not-allowed '
        'transition-all';
  }

  String _buildAlpineData(dynamic defaultVal) {
    final searchEndpoint = '/dash/relationship-search/${_relatedModel?.toLowerCase() ?? 'model'}';

    // Build initial options JSON
    final optionsJson = _options.isEmpty
        ? '[]'
        : '[${_options.map((o) => '{"value":"${o.value}","label":"${_escapeJs(o.label)}"}').join(',')}]';

    // Build selected option
    final selectedVal = _selectedOption?.value ?? defaultVal?.toString() ?? '';
    final selectedLbl =
        _selectedOption?.label ?? record?.getRelation(_relationName ?? '')?.toMap()[_displayColumn]?.toString() ?? '';

    return '''
      {
        isOpen: false,
        loading: false,
        searchQuery: '',
        selectedValue: '$selectedVal',
        selectedLabel: '$selectedLbl',
        options: $optionsJson,
        searchEndpoint: '$searchEndpoint',
        displayColumn: '$_displayColumn',
        valueColumn: '$_valueColumn',
        searchColumns: ${_buildSearchColumnsJson()},
        minSearchLength: $_minSearchLength,
        
        init() {
          // Preload options if configured
          ${_preload ? 'this.preloadOptions();' : ''}
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
        
        select(option) {
          this.selectedValue = option.value;
          this.selectedLabel = option.label;
          this.close();
        },
        
        clear() {
          this.selectedValue = '';
          this.selectedLabel = '';
          this.searchQuery = '';
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
        },
        
        createNew() {
          ${_createUrl != null ? "window.location.href = '$_createUrl?name=' + encodeURIComponent(this.searchQuery);" : ''}
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
}

/// Represents an option in a relationship select.
class RelationshipOption {
  /// The value (usually the primary key).
  final String value;

  /// The display label.
  final String label;

  /// Optional additional data.
  final Map<String, dynamic>? data;

  const RelationshipOption({required this.value, required this.label, this.data});

  /// Creates an option from a model map.
  factory RelationshipOption.fromMap(
    Map<String, dynamic> map, {
    String valueColumn = 'id',
    String displayColumn = 'name',
    String Function(Map<String, dynamic>)? formatter,
  }) {
    return RelationshipOption(
      value: map[valueColumn]?.toString() ?? '',
      label: formatter?.call(map) ?? map[displayColumn]?.toString() ?? '',
      data: map,
    );
  }

  Map<String, dynamic> toJson() => {'value': value, 'label': label, if (data != null) 'data': data};
}

/// Handler for relationship select async search requests.
///
/// This handler provides the server-side endpoint for `RelationshipSelect`
/// fields to search for related records.
///
/// Example endpoint: `/dash/relationship-search/user?q=john&columns=name,email`
class RelationshipSearchHandler {
  /// Handles a relationship search request.
  ///
  /// Query parameters:
  /// - `q` - Search query string
  /// - `columns` - Comma-separated list of columns to search
  /// - `limit` - Maximum number of results (default: 20)
  /// - `display` - Column to use for display (default: 'name')
  /// - `value` - Column to use for value (default: 'id')
  Future<Response> handle(Request request, String modelSlug) async {
    final queryParams = request.url.queryParameters;
    final searchQuery = queryParams['q'] ?? '';
    final columns = (queryParams['columns'] ?? 'name').split(',');
    final limit = int.tryParse(queryParams['limit'] ?? '20') ?? 20;
    final displayColumn = queryParams['display'] ?? 'name';
    final valueColumn = queryParams['value'] ?? 'id';

    try {
      // Find the resource that handles this model
      final resource = resourceFromSlug(modelSlug);
      final queryBuilder = resource.query();

      // Add search conditions if query is provided
      if (searchQuery.isNotEmpty) {
        for (var i = 0; i < columns.length; i++) {
          final column = columns[i].trim();
          if (i == 0) {
            queryBuilder.where(column, 'LIKE', '%$searchQuery%');
          } else {
            queryBuilder.orWhere(column, 'LIKE', '%$searchQuery%');
          }
        }
      }

      // Get results
      final records = await queryBuilder.limit(limit).get();

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
