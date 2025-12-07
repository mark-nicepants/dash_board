import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/column.dart';
import 'package:dash_board/src/table/columns/icon_column.dart';

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
///   .trueIcon(HeroIcons.shieldCheck)
///   .falseIcon(HeroIcons.shieldExclamation)
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

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  BooleanColumn label(String label) {
    super.label(label);
    return this;
  }

  @override
  BooleanColumn sortable([bool sortable = true]) {
    super.sortable(sortable);
    return this;
  }

  @override
  BooleanColumn searchable([bool searchable = true]) {
    super.searchable(searchable);
    return this;
  }

  @override
  BooleanColumn toggleable({bool toggleable = true, bool isToggledHiddenByDefault = false}) {
    super.toggleable(toggleable: toggleable, isToggledHiddenByDefault: isToggledHiddenByDefault);
    return this;
  }

  @override
  BooleanColumn hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  BooleanColumn alignment(ColumnAlignment alignment) {
    super.alignment(alignment);
    return this;
  }

  @override
  BooleanColumn alignStart() {
    super.alignStart();
    return this;
  }

  @override
  BooleanColumn alignCenter() {
    super.alignCenter();
    return this;
  }

  @override
  BooleanColumn alignEnd() {
    super.alignEnd();
    return this;
  }

  @override
  BooleanColumn width(String width) {
    super.width(width);
    return this;
  }

  @override
  BooleanColumn grow([bool grow = true]) {
    super.grow(grow);
    return this;
  }

  @override
  BooleanColumn placeholder(String text) {
    super.placeholder(text);
    return this;
  }

  @override
  BooleanColumn defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  BooleanColumn state(dynamic Function(Model) resolver) {
    super.state(resolver);
    return this;
  }

  // ============================================================
  // BooleanColumn-specific methods
  // ============================================================

  /// Sets the icon for true values.
  BooleanColumn trueIcon(HeroIcons icon) {
    boolean(trueIcon: icon);
    return this;
  }

  /// Sets the icon for false values.
  BooleanColumn falseIcon(HeroIcons icon) {
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

  @override
  BooleanColumn clickable([String action = 'toggle-boolean']) {
    super.clickable(action);
    return this;
  }
}
