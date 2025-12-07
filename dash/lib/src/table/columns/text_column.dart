import 'package:dash_board/src/components/partials/button.dart' show IconPosition;
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/column.dart';
import 'package:intl/intl.dart';

/// A column that displays text.
///
/// This is the most common column type, used for displaying text data
/// with optional formatting, colors, icons, and badges.
///
/// Example:
/// ```dart
/// TextColumn.make('name')
///   .searchable()
///   .sortable(),
///
/// TextColumn.make('status')
///   .badge()
///   .color((Model record) {
///     final status = record.toMap()['status'];
///     return status == 'active' ? 'success' : 'danger';
///   }),
///
/// TextColumn.make('created_at')
///   .dateTime()
///   .since(),
/// ```
class TextColumn extends TableColumn {
  /// Whether to display as a badge.
  bool _badge = false;

  /// The color of the text/badge.
  dynamic _color;

  /// The size of the text.
  TextSize _size = TextSize.medium;

  /// The weight of the text.
  TextWeight _weight = TextWeight.normal;

  /// Whether to wrap text.
  bool _wrap = false;

  /// Maximum number of lines before truncating.
  int? _lineClamp;

  /// Icon to display before the text.
  String? _icon;

  /// Icon to display after the text.
  String? _iconAfter;

  /// Position of the icon.
  IconPosition _iconPosition = IconPosition.before;

  /// Description text to display below the main text.
  String? _description;

  /// Function to generate description text.
  String? Function(Model)? _descriptionResolver;

  /// Whether to display the value as a date.
  bool _isDate = false;

  /// Whether to display the value as a date and time.
  bool _isDateTime = false;

  /// Whether to display the value as time since (e.g., "2 hours ago").
  bool _isSince = false;

  /// Date format string.
  String? _dateFormat;

  /// Whether to display as a money value.
  bool _isMoney = false;

  /// Currency symbol for money formatting.
  String _currency = '\$';

  /// Number of decimal places for money.
  int _decimals = 2;

  /// Whether to display as a percentage.
  bool _isPercentage = false;

  /// Whether the value is a list.
  bool _isList = false;

  /// Separator for list items.
  String _listSeparator = ', ';

  /// Limit for list items.
  int? _listLimit;

  /// Whether to display limited lists as expandable.
  bool _limitedListExpandable = false;

  /// Custom formatter function.
  String Function(dynamic)? _formatter;

  /// Whether to copy the value on click.
  bool _copyable = false;

  /// Custom copy message.
  String? _copyMessage;

  /// URL to link to.
  dynamic _url;

  /// Whether to open URL in new tab.
  bool _openUrlInNewTab = false;

  TextColumn(super.name);

  /// Creates a new text column.
  static TextColumn make(String name) {
    return TextColumn(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  TextColumn label(String label) {
    super.label(label);
    return this;
  }

  @override
  TextColumn sortable([bool sortable = true]) {
    super.sortable(sortable);
    return this;
  }

  @override
  TextColumn searchable([bool searchable = true]) {
    super.searchable(searchable);
    return this;
  }

  @override
  TextColumn toggleable({bool toggleable = true, bool isToggledHiddenByDefault = false}) {
    super.toggleable(toggleable: toggleable, isToggledHiddenByDefault: isToggledHiddenByDefault);
    return this;
  }

  @override
  TextColumn hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  TextColumn alignment(ColumnAlignment alignment) {
    super.alignment(alignment);
    return this;
  }

  @override
  TextColumn alignStart() {
    super.alignStart();
    return this;
  }

  @override
  TextColumn alignCenter() {
    super.alignCenter();
    return this;
  }

  @override
  TextColumn alignEnd() {
    super.alignEnd();
    return this;
  }

  @override
  TextColumn width(String width) {
    super.width(width);
    return this;
  }

  @override
  TextColumn grow([bool grow = true]) {
    super.grow(grow);
    return this;
  }

  @override
  TextColumn placeholder(String text) {
    super.placeholder(text);
    return this;
  }

  @override
  TextColumn defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  TextColumn state(dynamic Function(Model) resolver) {
    super.state(resolver);
    return this;
  }

  // ============================================================
  // TextColumn-specific methods
  // ============================================================

  /// Displays the column as a badge.
  TextColumn badge([bool badge = true]) {
    _badge = badge;
    return this;
  }

  /// Checks if this is a badge column.
  bool isBadge() => _badge;

  /// Sets the color of the text/badge.
  /// Can be a string or a function that returns a string based on the record.
  TextColumn color(dynamic color) {
    _color = color;
    return this;
  }

  /// Gets the color for a specific record.
  String? getColor(Model record) {
    if (_color == null) return null;
    if (_color is String) return _color as String;
    if (_color is Function) {
      return (_color as String? Function(Model))(record);
    }
    return null;
  }

  /// Sets the text size.
  TextColumn size(TextSize size) {
    _size = size;
    return this;
  }

  /// Gets the text size.
  TextSize getSize() => _size;

  /// Sets the text weight.
  TextColumn weight(TextWeight weight) {
    _weight = weight;
    return this;
  }

  /// Gets the text weight.
  TextWeight getWeight() => _weight;

  /// Enables text wrapping.
  TextColumn wrap([bool wrap = true]) {
    _wrap = wrap;
    return this;
  }

  /// Checks if text should wrap.
  bool shouldWrap() => _wrap;

  /// Sets the maximum number of lines before truncating.
  TextColumn lineClamp(int lines) {
    _lineClamp = lines;
    return this;
  }

  /// Gets the line clamp value.
  int? getLineClamp() => _lineClamp;

  /// Sets an icon to display with the text.
  TextColumn icon(String icon, {IconPosition position = IconPosition.before}) {
    if (position == IconPosition.before) {
      _icon = icon;
    } else {
      _iconAfter = icon;
    }
    _iconPosition = position;
    return this;
  }

  /// Gets the icon.
  String? getIcon() => _icon;

  /// Gets the icon after.
  String? getIconAfter() => _iconAfter;

  /// Gets the icon position.
  IconPosition getIconPosition() => _iconPosition;

  /// Sets a description to display below the text.
  TextColumn description(dynamic description) {
    if (description is String) {
      _description = description;
    } else if (description is Function) {
      _descriptionResolver = description as String? Function(Model);
    }
    return this;
  }

  /// Gets the description for a specific record.
  String? getDescription(Model record) {
    if (_descriptionResolver != null) {
      return _descriptionResolver!(record);
    }
    return _description;
  }

  /// Formats the value as a date.
  TextColumn date([String? format]) {
    _isDate = true;
    _dateFormat = format;
    return this;
  }

  /// Formats the value as a date and time.
  TextColumn dateTime([String? format]) {
    _isDateTime = true;
    _dateFormat = format ?? 'yyyy-MM-dd HH:mm:ss';
    return this;
  }

  /// Formats the value as time since (e.g., "2 hours ago").
  TextColumn since() {
    _isSince = true;
    return this;
  }

  /// Formats the value as money.
  TextColumn money({String currency = '\$', int decimals = 2}) {
    _isMoney = true;
    _currency = currency;
    _decimals = decimals;
    return this;
  }

  /// Formats the value as a percentage.
  TextColumn percentage() {
    _isPercentage = true;
    return this;
  }

  /// Treats the value as a list and joins it.
  TextColumn list({String separator = ', ', int? limit}) {
    _isList = true;
    _listSeparator = separator;
    _listLimit = limit;
    return this;
  }

  /// Makes limited lists expandable.
  TextColumn expandableLimitedList([bool expandable = true]) {
    _limitedListExpandable = expandable;
    return this;
  }

  /// Checks if limited lists are expandable.
  bool isLimitedListExpandable() => _limitedListExpandable;

  /// Sets a custom formatter function.
  TextColumn formatStateUsing(String Function(dynamic) formatter) {
    _formatter = formatter;
    return this;
  }

  /// Makes the value copyable on click.
  TextColumn copyable({String? message}) {
    _copyable = true;
    _copyMessage = message;
    return this;
  }

  /// Checks if the column is copyable.
  bool isCopyable() => _copyable;

  /// Gets the copy message.
  String? getCopyMessage() => _copyMessage;

  /// Sets a URL to link to.
  TextColumn url(dynamic url, {bool openInNewTab = false}) {
    _url = url;
    _openUrlInNewTab = openInNewTab;
    return this;
  }

  /// Gets the URL for a specific record.
  String? getUrl(Model record) {
    if (_url == null) return null;
    if (_url is String) return _url as String;
    if (_url is Function) {
      return (_url as String? Function(Model))(record);
    }
    return null;
  }

  /// Checks if URL should open in new tab.
  bool shouldOpenUrlInNewTab() => _openUrlInNewTab;

  @override
  String formatState(dynamic state) {
    if (state == null) return getPlaceholder() ?? '';

    // Apply custom formatter if provided
    if (_formatter != null) {
      return _formatter!(state);
    }

    // Handle list values
    if (_isList && state is List) {
      final items = _listLimit != null && state.length > _listLimit! ? state.take(_listLimit!) : state;
      final formatted = items.join(_listSeparator);
      if (_listLimit != null && state.length > _listLimit!) {
        return '$formatted... (+${state.length - _listLimit!} more)';
      }
      return formatted;
    }

    // Handle date/time formatting
    if (_isDate || _isDateTime) {
      DateTime? dt;
      if (state is DateTime) {
        dt = state;
      } else if (state is String) {
        dt = DateTime.tryParse(state);
      }

      if (dt != null) {
        final format = _dateFormat ?? (_isDate ? 'yyyy-MM-dd' : 'yyyy-MM-dd HH:mm:ss');
        return DateFormat(format).format(dt);
      }
      return state.toString();
    }

    // Handle time since
    if (_isSince && state is DateTime) {
      final now = DateTime.now();
      final difference = now.difference(state);

      if (difference.inDays > 365) {
        final years = (difference.inDays / 365).floor();
        return '$years year${years == 1 ? '' : 's'} ago';
      } else if (difference.inDays > 30) {
        final months = (difference.inDays / 30).floor();
        return '$months month${months == 1 ? '' : 's'} ago';
      } else if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'just now';
      }
    }

    // Handle money formatting
    if (_isMoney) {
      if (state is num) {
        return '$_currency${state.toStringAsFixed(_decimals)}';
      }
    }

    // Handle percentage formatting
    if (_isPercentage) {
      if (state is num) {
        return '${(state * 100).toStringAsFixed(0)}%';
      }
    }

    return state.toString();
  }
}

/// Text size options.
enum TextSize { small, medium, large }

/// Text weight options.
enum TextWeight { thin, normal, medium, semibold, bold }
