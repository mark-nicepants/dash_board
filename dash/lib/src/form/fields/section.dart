import 'package:dash_board/src/form/fields/field.dart';

/// A form section that groups related fields together.
///
/// Sections provide visual grouping with optional heading, description,
/// icon, and collapsible behavior.
///
/// Example:
/// ```dart
/// Section.make('Device Information')
///   .description('Basic device identification and customer details')
///   .icon('device-phone-mobile')
///   .collapsible()
///   .columns(2)
///   .schema([
///     TextInput.make('device_id').required(),
///     TextInput.make('customer_name'),
///   ])
/// ```
class Section {
  /// The section heading.
  String? _heading;

  /// The section description.
  String? _description;

  /// The icon name (Heroicon).
  String? _icon;

  /// Whether the section can be collapsed.
  bool _collapsible = false;

  /// Whether the section starts collapsed.
  bool _collapsed = false;

  /// Whether to use compact styling.
  bool _compact = false;

  /// Whether to position heading aside (left) of content.
  bool _aside = false;

  /// Number of columns for the section's field grid.
  int _columns = 1;

  /// The gap between fields in the section.
  String _gap = '4';

  /// The fields within this section.
  List<FormField> _fields = [];

  /// Whether the section is hidden.
  bool _hidden = false;

  /// The number of grid columns this section spans.
  int _columnSpan = 1;

  /// Column span for different breakpoints.
  final Map<String, int> _columnSpanBreakpoints = {};

  /// Creates a section with an optional heading.
  Section([this._heading]);

  /// Factory method to create a section.
  static Section make([String? heading]) => Section(heading);

  /// Sets the section heading.
  Section heading(String heading) {
    _heading = heading;
    return this;
  }

  /// Gets the heading.
  String? getHeading() => _heading;

  /// Sets the section description.
  Section description(String description) {
    _description = description;
    return this;
  }

  /// Gets the description.
  String? getDescription() => _description;

  /// Sets the section icon (Heroicon name).
  Section icon(String icon) {
    _icon = icon;
    return this;
  }

  /// Gets the icon name.
  String? getIcon() => _icon;

  /// Makes the section collapsible.
  Section collapsible([bool collapsible = true]) {
    _collapsible = collapsible;
    return this;
  }

  /// Gets whether the section is collapsible.
  bool isCollapsible() => _collapsible;

  /// Sets the section to start collapsed.
  /// Automatically makes the section collapsible.
  Section collapsed([bool collapsed = true]) {
    _collapsed = collapsed;
    if (collapsed) {
      _collapsible = true;
    }
    return this;
  }

  /// Gets whether the section starts collapsed.
  bool isCollapsed() => _collapsed;

  /// Uses compact styling for the section.
  Section compact([bool compact = true]) {
    _compact = compact;
    return this;
  }

  /// Gets whether compact styling is enabled.
  bool isCompact() => _compact;

  /// Positions the heading aside (left side) of the content.
  Section aside([bool aside = true]) {
    _aside = aside;
    return this;
  }

  /// Gets whether the section uses aside layout.
  bool isAside() => _aside;

  /// Sets the number of columns for the field grid.
  Section columns(int columns) {
    _columns = columns;
    return this;
  }

  /// Gets the number of columns.
  int getColumns() => _columns;

  /// Sets the gap between fields (Tailwind spacing scale).
  Section gap(String gap) {
    _gap = gap;
    return this;
  }

  /// Gets the gap value.
  String getGap() => _gap;

  /// Sets the fields within this section.
  Section schema(List<FormField> fields) {
    _fields = fields;
    return this;
  }

  /// Gets the fields in this section.
  List<FormField> getFields() => _fields;

  /// Hides the section.
  ///
  /// Hidden sections will not be rendered in the form.
  Section hidden([bool hidden = true]) {
    _hidden = hidden;
    return this;
  }

  /// Checks if the section is hidden.
  bool isHidden() => _hidden;

  /// Sets how many grid columns this section spans.
  ///
  /// Example:
  /// ```dart
  /// Grid.make(3).schema([
  ///   Section.make('Main').columnSpan(2),  // Takes 2 of 3 columns
  ///   Section.make('Side').columnSpan(1),  // Takes 1 of 3 columns
  /// ])
  /// ```
  Section columnSpan(int span) {
    _columnSpan = span;
    return this;
  }

  /// Gets the column span.
  int getColumnSpan() => _columnSpan;

  /// Sets column span for a specific breakpoint.
  Section columnSpanBreakpoint(String breakpoint, int span) {
    _columnSpanBreakpoints[breakpoint] = span;
    return this;
  }

  /// Gets the column span breakpoints.
  Map<String, int> getColumnSpanBreakpoints() => _columnSpanBreakpoints;

  /// Makes this section span all columns in the parent grid.
  Section columnSpanFull() {
    _columnSpan = -1; // -1 indicates full width
    return this;
  }

  /// Checks if the section spans full width.
  bool isColumnSpanFull() => _columnSpan == -1;

  /// Gets the Tailwind classes for column span.
  String getColumnSpanClasses(int totalColumns) {
    if (isColumnSpanFull() || _columnSpan >= totalColumns) {
      return 'col-span-full';
    }
    return 'col-span-$_columnSpan';
  }
}
