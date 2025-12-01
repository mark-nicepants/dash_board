import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/model/model.dart';
import 'package:dash/src/table/columns/column.dart';

/// A column that displays a Heroicon.
///
/// This column type is useful for displaying visual indicators,
/// status icons, or boolean values as icons.
///
/// Example:
/// ```dart
/// IconColumn.make('status')
///   .icon((Model record) {
///     final status = record.toMap()['status'];
///     return status == 'active' ? HeroIcons.check : HeroIcons.xMark;
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
  HeroIcons _trueIcon = HeroIcons.checkCircle;

  /// Icon to display for false values (when boolean).
  HeroIcons _falseIcon = HeroIcons.xCircle;

  /// Color for true values (when boolean).
  String _trueColor = 'success';

  /// Color for false values (when boolean).
  String _falseColor = 'danger';

  /// The action name for clickable columns (triggers wire:click).
  String? _clickAction;

  IconColumn(super.name);

  /// Creates a new icon column.
  static IconColumn make(String name) {
    return IconColumn(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  IconColumn label(String label) {
    super.label(label);
    return this;
  }

  @override
  IconColumn sortable([bool sortable = true]) {
    super.sortable(sortable);
    return this;
  }

  @override
  IconColumn searchable([bool searchable = true]) {
    super.searchable(searchable);
    return this;
  }

  @override
  IconColumn toggleable({bool toggleable = true, bool isToggledHiddenByDefault = false}) {
    super.toggleable(toggleable: toggleable, isToggledHiddenByDefault: isToggledHiddenByDefault);
    return this;
  }

  @override
  IconColumn hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  IconColumn alignment(ColumnAlignment alignment) {
    super.alignment(alignment);
    return this;
  }

  @override
  IconColumn alignStart() {
    super.alignStart();
    return this;
  }

  @override
  IconColumn alignCenter() {
    super.alignCenter();
    return this;
  }

  @override
  IconColumn alignEnd() {
    super.alignEnd();
    return this;
  }

  @override
  IconColumn width(String width) {
    super.width(width);
    return this;
  }

  @override
  IconColumn grow([bool grow = true]) {
    super.grow(grow);
    return this;
  }

  @override
  IconColumn placeholder(String text) {
    super.placeholder(text);
    return this;
  }

  @override
  IconColumn defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  IconColumn state(dynamic Function(Model) resolver) {
    super.state(resolver);
    return this;
  }

  // ============================================================
  // IconColumn-specific methods
  // ============================================================

  /// Sets the icon to display.
  /// Can be a HeroIcons value or a function that returns a HeroIcons based on the record.
  IconColumn icon(dynamic icon) {
    _icon = icon;
    return this;
  }

  /// Gets the icon for a specific record.
  HeroIcons? getIcon(Model record) {
    // Handle boolean mode
    if (_isBoolean) {
      final state = getState(record);
      final boolValue = _parseBool(state);
      return boolValue ? _trueIcon : _falseIcon;
    }

    if (_icon == null) return null;
    if (_icon is HeroIcons) return _icon as HeroIcons;
    if (_icon is Function) {
      return (_icon as HeroIcons? Function(Model))(record);
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
  IconColumn boolean({HeroIcons? trueIcon, HeroIcons? falseIcon, String? trueColor, String? falseColor}) {
    _isBoolean = true;
    if (trueIcon != null) _trueIcon = trueIcon;
    if (falseIcon != null) _falseIcon = falseIcon;
    if (trueColor != null) _trueColor = trueColor;
    if (falseColor != null) _falseColor = falseColor;
    return this;
  }

  /// Checks if this is a boolean column.
  bool isBoolean() => _isBoolean;

  /// Makes the column clickable, triggering a wire:click action.
  ///
  /// When clicked, the action will be executed with the record ID.
  /// The action name defaults to 'toggle-boolean' which uses the built-in
  /// [ToggleBooleanHandler] to toggle the field value.
  ///
  /// Example:
  /// ```dart
  /// BooleanColumn.make('is_active')
  ///   .clickable(), // Uses default 'toggle-boolean' action
  ///
  /// IconColumn.make('status')
  ///   .clickable('change-status'), // Custom action name
  /// ```
  IconColumn clickable([String action = 'toggle-boolean']) {
    _clickAction = action;
    return this;
  }

  /// Checks if the column is clickable.
  bool isClickable() => _clickAction != null;

  /// Gets the click action name.
  String? getClickAction() => _clickAction;

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
