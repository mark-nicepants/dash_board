import 'package:dash/src/model/model.dart';

/// Base class for all table columns.
///
/// A [TableColumn] defines how a specific piece of data is displayed in a table.
/// It provides common functionality like labels, sorting, searching, and alignment.
///
/// Example:
/// ```dart
/// TextColumn.make('name')
///   .label('Full Name')
///   .sortable()
///   .searchable()
///   .alignCenter();
/// ```
abstract class TableColumn {
  /// The name of the column (corresponds to model attribute).
  final String _name;

  /// The label displayed in the table header.
  String? _label;

  /// Whether the column is sortable.
  bool _sortable = false;

  /// Whether the column is searchable.
  bool _searchable = false;

  /// Whether the column is hidden by default (but can be toggled).
  bool _toggleable = false;

  /// Whether the column is toggled hidden by default.
  bool _toggledHiddenByDefault = false;

  /// Whether the column is completely hidden.
  bool _hidden = false;

  /// The alignment of the column content.
  ColumnAlignment _alignment = ColumnAlignment.start;

  /// The width of the column.
  String? _width;

  /// Whether the column can grow to fill available space.
  bool _grow = false;

  /// Placeholder text when the column value is null.
  String? _placeholder;

  /// Default value when the column value is null.
  dynamic _default;

  /// Custom state resolver function.
  dynamic Function(Model)? _stateResolver;

  TableColumn(this._name);

  /// Creates a new column instance.
  static T make<T extends TableColumn>(String name) {
    throw UnimplementedError('Subclasses must implement make()');
  }

  /// Gets the name of the column.
  String getName() => _name;

  /// Sets the label for the column header.
  T label<T extends TableColumn>(String label) {
    _label = label;
    return this as T;
  }

  /// Gets the label for the column.
  /// Defaults to a humanized version of the name if not set.
  String getLabel() {
    if (_label != null) return _label!;

    // Convert snake_case or camelCase to Title Case
    final words = _name
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty);

    return words.map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase()).join(' ');
  }

  /// Makes the column sortable.
  T sortable<T extends TableColumn>([bool sortable = true]) {
    _sortable = sortable;
    return this as T;
  }

  /// Checks if the column is sortable.
  bool isSortable() => _sortable;

  /// Makes the column searchable.
  T searchable<T extends TableColumn>([bool searchable = true]) {
    _searchable = searchable;
    return this as T;
  }

  /// Checks if the column is searchable.
  bool isSearchable() => _searchable;

  /// Makes the column toggleable (can be shown/hidden by user).
  T toggleable<T extends TableColumn>({bool toggleable = true, bool isToggledHiddenByDefault = false}) {
    _toggleable = toggleable;
    _toggledHiddenByDefault = isToggledHiddenByDefault;
    return this as T;
  }

  /// Checks if the column is toggleable.
  bool isToggleable() => _toggleable;

  /// Checks if the column is toggled hidden by default.
  bool isToggledHiddenByDefault() => _toggledHiddenByDefault;

  /// Hides the column completely.
  T hidden<T extends TableColumn>([bool hidden = true]) {
    _hidden = hidden;
    return this as T;
  }

  /// Checks if the column is hidden.
  bool isHidden() => _hidden;

  /// Sets the alignment of the column content.
  T alignment<T extends TableColumn>(ColumnAlignment alignment) {
    _alignment = alignment;
    return this as T;
  }

  /// Aligns the column content to the start.
  T alignStart<T extends TableColumn>() => alignment(ColumnAlignment.start);

  /// Aligns the column content to the center.
  T alignCenter<T extends TableColumn>() => alignment(ColumnAlignment.center);

  /// Aligns the column content to the end.
  T alignEnd<T extends TableColumn>() => alignment(ColumnAlignment.end);

  /// Gets the alignment of the column.
  ColumnAlignment getAlignment() => _alignment;

  /// Sets the width of the column.
  T width<T extends TableColumn>(String width) {
    _width = width;
    return this as T;
  }

  /// Gets the width of the column.
  String? getWidth() => _width;

  /// Makes the column grow to fill available space.
  T grow<T extends TableColumn>([bool grow = true]) {
    _grow = grow;
    return this as T;
  }

  /// Checks if the column can grow.
  bool canGrow() => _grow;

  /// Sets placeholder text for null values.
  T placeholder<T extends TableColumn>(String text) {
    _placeholder = text;
    return this as T;
  }

  /// Gets the placeholder text.
  String? getPlaceholder() => _placeholder;

  /// Sets a default value for null values.
  T defaultValue<T extends TableColumn>(dynamic value) {
    _default = value;
    return this as T;
  }

  /// Gets the default value.
  dynamic getDefaultValue() => _default;

  /// Sets a custom state resolver function.
  T state<T extends TableColumn>(dynamic Function(Model) resolver) {
    _stateResolver = resolver;
    return this as T;
  }

  /// Gets the state (value) for this column from a model.
  dynamic getState(Model model) {
    // If there's a custom state resolver, use it
    if (_stateResolver != null) {
      return _stateResolver!(model);
    }

    // Handle dot notation (e.g., 'author.name')
    final parts = _name.split('.');
    dynamic value = model;

    for (final part in parts) {
      if (value == null) break;

      if (value is Model) {
        value = value.toMap()[part];
      } else if (value is Map) {
        value = value[part];
      } else {
        value = null;
        break;
      }
    }

    // Return default or placeholder if value is null
    if (value == null) {
      return _default ?? _placeholder;
    }

    return value;
  }

  /// Formats the state for display.
  /// Subclasses can override this to provide custom formatting.
  String formatState(dynamic state) {
    if (state == null) return _placeholder ?? '';
    return state.toString();
  }
}

/// Alignment options for columns.
enum ColumnAlignment { start, center, end }
