import 'package:dash/src/model/model.dart';

import 'package:dash/src/table/columns/column.dart';

/// A column that displays an icon.
///
/// This column type is useful for displaying visual indicators,
/// status icons, or boolean values as icons.
///
/// Example:
/// ```dart
/// IconColumn.make('status')
///   .icon((Model record) {
///     final status = record.toMap()['status'];
///     return status == 'active' ? 'check' : 'x';
///   })
///   .color((Model record) {
///     final status = record.toMap()['status'];
///     return status == 'active' ? 'success' : 'danger';
///   }),
///
/// IconColumn.make('is_featured')
///   .boolean(),
/// ```
class IconColumn extends TableColumn {
  /// The icon to display.
  dynamic _icon;

  /// The color of the icon.
  dynamic _color;

  /// The size of the icon.
  IconSize _size = IconSize.medium;

  /// Whether to display as a boolean (check/x icons).
  bool _isBoolean = false;

  /// Icon to display for true values (when boolean).
  String _trueIcon = 'check-circle';

  /// Icon to display for false values (when boolean).
  String _falseIcon = 'x-circle';

  /// Color for true values (when boolean).
  String _trueColor = 'success';

  /// Color for false values (when boolean).
  String _falseColor = 'danger';

  IconColumn(super.name);

  /// Creates a new icon column.
  static IconColumn make(String name) {
    return IconColumn(name);
  }

  /// Sets the icon to display.
  /// Can be a string or a function that returns a string based on the record.
  IconColumn icon(dynamic icon) {
    _icon = icon;
    return this;
  }

  /// Gets the icon for a specific record.
  String? getIcon(Model record) {
    // Handle boolean mode
    if (_isBoolean) {
      final state = getState(record);
      final boolValue = _parseBool(state);
      return boolValue ? _trueIcon : _falseIcon;
    }

    if (_icon == null) return null;
    if (_icon is String) return _icon as String;
    if (_icon is Function) {
      return (_icon as String? Function(Model))(record);
    }
    return null;
  }

  /// Sets the color of the icon.
  /// Can be a string or a function that returns a string based on the record.
  IconColumn color(dynamic color) {
    _color = color;
    return this;
  }

  /// Gets the color for a specific record.
  String? getColor(Model record) {
    // Handle boolean mode
    if (_isBoolean) {
      final state = getState(record);
      final boolValue = _parseBool(state);
      return boolValue ? _trueColor : _falseColor;
    }

    if (_color == null) return null;
    if (_color is String) return _color as String;
    if (_color is Function) {
      return (_color as String? Function(Model))(record);
    }
    return null;
  }

  /// Sets the icon size.
  IconColumn size(IconSize size) {
    _size = size;
    return this;
  }

  /// Gets the icon size.
  IconSize getSize() => _size;

  /// Configures the column as a boolean column.
  IconColumn boolean({String? trueIcon, String? falseIcon, String? trueColor, String? falseColor}) {
    _isBoolean = true;
    if (trueIcon != null) _trueIcon = trueIcon;
    if (falseIcon != null) _falseIcon = falseIcon;
    if (trueColor != null) _trueColor = trueColor;
    if (falseColor != null) _falseColor = falseColor;
    return this;
  }

  /// Checks if this is a boolean column.
  bool isBoolean() => _isBoolean;

  /// Parses a value as a boolean.
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  @override
  String formatState(dynamic state) {
    // Icon columns typically don't format state as text
    // The icon itself is the visual representation
    if (_isBoolean) {
      return _parseBool(state) ? 'Yes' : 'No';
    }
    return super.formatState(state);
  }
}

/// Icon size options.
enum IconSize { small, medium, large }
