import 'package:dash_board/src/form/fields/field.dart';
import 'package:dash_board/src/form/fields/section.dart';

/// A grid layout component for arranging form fields and sections.
///
/// Grid creates a CSS grid layout to arrange child components in columns.
/// Use Grid to place multiple fields or sections side by side.
///
/// Example:
/// ```dart
/// Grid.make(2)
///   .schema([
///     Section.make('Left Section')
///       .schema([TextInput.make('name')]),
///     Section.make('Right Section')
///       .schema([TextInput.make('email')]),
///   ])
/// ```
///
/// With responsive columns:
/// ```dart
/// Grid.make()
///   .columns({
///     'default': 1,
///     'md': 2,
///     'lg': 3,
///   })
///   .schema([...])
/// ```
class Grid {
  /// The number of columns at the lg breakpoint.
  int _lgColumns = 2;

  /// Responsive columns configuration.
  final Map<String, int> _columns = {'default': 1};

  /// The gap between grid items.
  String _gap = '4';

  /// The child components (fields, sections, or nested grids).
  List<Object> _components = [];

  /// Whether the grid is hidden.
  bool _hidden = false;

  /// The number of grid columns this grid spans (when nested).
  int _columnSpan = 1;

  /// Column span for different breakpoints.
  final Map<String, int> _columnSpanBreakpoints = {};

  /// Creates a grid with an optional number of columns.
  Grid([int columns = 2]) {
    _lgColumns = columns;
    _columns['lg'] = columns;
  }

  /// Factory method to create a grid.
  static Grid make([int columns = 2]) => Grid(columns);

  /// Sets the number of columns at a specific breakpoint.
  ///
  /// Available breakpoints: 'default', 'sm', 'md', 'lg', 'xl', '2xl'
  ///
  /// Example:
  /// ```dart
  /// Grid.make()
  ///   .columns({'default': 1, 'md': 2, 'lg': 3})
  /// ```
  Grid columns(Map<String, int> columns) {
    _columns.clear();
    _columns.addAll(columns);
    if (columns.containsKey('lg')) {
      _lgColumns = columns['lg']!;
    }
    return this;
  }

  /// Gets the columns configuration.
  Map<String, int> getColumns() => Map.from(_columns);

  /// Gets the number of columns at a specific breakpoint.
  int? getColumnsAt(String breakpoint) => _columns[breakpoint];

  /// Gets the default column count (lg breakpoint).
  int getDefaultColumns() => _lgColumns;

  /// Sets the gap between grid items (Tailwind spacing scale).
  Grid gap(String gap) {
    _gap = gap;
    return this;
  }

  /// Gets the gap value.
  String getGap() => _gap;

  /// Sets the child components for this grid.
  ///
  /// Components can be [FormField], [Section], or nested [Grid].
  Grid schema(List<Object> components) {
    _components = components;
    return this;
  }

  /// Gets the child components.
  List<Object> getComponents() => _components;

  /// Gets all fields from this grid (flattening sections and nested grids).
  List<FormField> getFields() {
    final fields = <FormField>[];
    for (final component in _components) {
      if (component is FormField) {
        fields.add(component);
      } else if (component is Section) {
        fields.addAll(component.getFields());
      } else if (component is Grid) {
        fields.addAll(component.getFields());
      }
    }
    return fields;
  }

  /// Hides the grid.
  Grid hidden([bool hidden = true]) {
    _hidden = hidden;
    return this;
  }

  /// Checks if the grid is hidden.
  bool isHidden() => _hidden;

  /// Sets how many grid columns this grid spans (when nested in another grid).
  ///
  /// Example:
  /// ```dart
  /// Grid.make(3).schema([
  ///   Grid.make(1).columnSpan(2).schema([...]),  // Takes 2 of 3 columns
  ///   Section.make('Side').columnSpan(1),         // Takes 1 of 3 columns
  /// ])
  /// ```
  Grid columnSpan(int span) {
    _columnSpan = span;
    return this;
  }

  /// Gets the column span.
  int getColumnSpan() => _columnSpan;

  /// Sets column span for a specific breakpoint.
  Grid columnSpanBreakpoint(String breakpoint, int span) {
    _columnSpanBreakpoints[breakpoint] = span;
    return this;
  }

  /// Gets the column span breakpoints.
  Map<String, int> getColumnSpanBreakpoints() => _columnSpanBreakpoints;

  /// Makes this grid span all columns in the parent grid.
  Grid columnSpanFull() {
    _columnSpan = -1; // -1 indicates full width
    return this;
  }

  /// Checks if the grid spans full width.
  bool isColumnSpanFull() => _columnSpan == -1;

  /// Gets the Tailwind classes for column span.
  String getColumnSpanClasses(int totalColumns) {
    if (isColumnSpanFull() || _columnSpan >= totalColumns) {
      return 'col-span-full';
    }
    return 'col-span-$_columnSpan';
  }

  /// Builds the Tailwind CSS classes for the grid.
  String getGridClasses() {
    final classes = <String>['grid', 'items-start'];

    // Add column classes for each breakpoint
    _columns.forEach((breakpoint, cols) {
      if (breakpoint == 'default') {
        classes.add('grid-cols-$cols');
      } else {
        classes.add('$breakpoint:grid-cols-$cols');
      }
    });

    // Add gap
    classes.add('gap-$_gap');

    return classes.join(' ');
  }
}
