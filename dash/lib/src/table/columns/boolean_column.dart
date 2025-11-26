import 'package:dash/src/table/columns/icon_column.dart';

/// A column that displays a boolean value as an icon.
///
/// This is a convenience class that extends IconColumn with
/// boolean mode enabled by default.
///
/// Example:
/// ```dart
/// BooleanColumn.make('is_active')
///   .sortable(),
///
/// BooleanColumn.make('is_verified')
///   .trueIcon('shield-check')
///   .falseIcon('shield-exclamation')
///   .trueColor('success')
///   .falseColor('warning'),
/// ```
class BooleanColumn extends IconColumn {
  BooleanColumn(super.name) {
    // Enable boolean mode by default
    boolean();
  }

  /// Creates a new boolean column.
  static BooleanColumn make(String name) {
    return BooleanColumn(name);
  }

  /// Sets the icon for true values.
  BooleanColumn trueIcon(String icon) {
    boolean(trueIcon: icon);
    return this;
  }

  /// Sets the icon for false values.
  BooleanColumn falseIcon(String icon) {
    boolean(falseIcon: icon);
    return this;
  }

  /// Sets the color for true values.
  BooleanColumn trueColor(String color) {
    boolean(trueColor: color);
    return this;
  }

  /// Sets the color for false values.
  BooleanColumn falseColor(String color) {
    boolean(falseColor: color);
    return this;
  }
}
