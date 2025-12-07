import 'package:dash_board/src/components/partials/forms/form_components.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:jaspr/jaspr.dart';

/// A date picker field.
///
/// This field displays a native date input with optional
/// time selection and range constraints.
///
/// Example:
/// ```dart
/// DatePicker.make('birth_date')
///   .label('Date of Birth')
///   .maxDate(DateTime.now())
///   .displayFormat('MM/dd/yyyy'),
///
/// DatePicker.make('appointment')
///   .label('Appointment Date & Time')
///   .withTime()
///   .minDate(DateTime.now()),
///
/// DatePicker.make('start_date')
///   .label('Start Date')
///   .native(),
/// ```
class DatePicker extends FormField {
  /// Whether to include time selection.
  bool _withTime = false;

  /// Whether to only show time (no date).
  bool _timeOnly = false;

  /// Minimum allowed date.
  DateTime? _minDate;

  /// Maximum allowed date.
  DateTime? _maxDate;

  /// Display format (for custom pickers).
  String _displayFormat = 'yyyy-MM-dd';

  /// Whether to use native HTML date input.
  bool _native = true;

  /// First day of week (0 = Sunday, 1 = Monday).
  int _firstDayOfWeek = 1;

  /// Disabled dates.
  List<DateTime>? _disabledDates;

  /// Whether to close on selection.
  bool _closeOnSelect = true;

  DatePicker(super.name);

  /// Creates a new date picker field.
  static DatePicker make(String name) {
    return DatePicker(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  DatePicker id(String id) {
    super.id(id);
    return this;
  }

  @override
  DatePicker label(String label) {
    super.label(label);
    return this;
  }

  @override
  DatePicker placeholder(String placeholder) {
    super.placeholder(placeholder);
    return this;
  }

  @override
  DatePicker helperText(String text) {
    super.helperText(text);
    return this;
  }

  @override
  DatePicker hint(String hint) {
    super.hint(hint);
    return this;
  }

  @override
  DatePicker defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  DatePicker required([bool required = true]) {
    super.required(required);
    return this;
  }

  @override
  DatePicker disabled([bool disabled = true]) {
    super.disabled(disabled);
    return this;
  }

  @override
  DatePicker readonly([bool readonly = true]) {
    super.readonly(readonly);
    return this;
  }

  @override
  DatePicker hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  DatePicker columnSpan(int span) {
    super.columnSpan(span);
    return this;
  }

  @override
  DatePicker columnSpanBreakpoint(String breakpoint, int span) {
    super.columnSpanBreakpoint(breakpoint, span);
    return this;
  }

  @override
  DatePicker columnSpanFull() {
    super.columnSpanFull();
    return this;
  }

  @override
  DatePicker extraClasses(String classes) {
    super.extraClasses(classes);
    return this;
  }

  @override
  DatePicker rule(ValidationRule rule) {
    super.rule(rule);
    return this;
  }

  @override
  DatePicker rules(List<ValidationRule> rules) {
    super.rules(rules);
    return this;
  }

  @override
  DatePicker validationMessage(String rule, String message) {
    super.validationMessage(rule, message);
    return this;
  }

  @override
  DatePicker autofocus([bool autofocus = true]) {
    super.autofocus(autofocus);
    return this;
  }

  @override
  DatePicker autocomplete(String value) {
    super.autocomplete(value);
    return this;
  }

  @override
  DatePicker tabindex(int index) {
    super.tabindex(index);
    return this;
  }

  // ============================================================
  // DatePicker-specific methods
  // ============================================================

  /// Includes time selection.
  DatePicker withTime([bool withTime = true]) {
    _withTime = withTime;
    return this;
  }

  /// Checks if time is included.
  bool hasTime() => _withTime;

  /// Shows only time picker (no date).
  DatePicker timeOnly([bool timeOnly = true]) {
    _timeOnly = timeOnly;
    return this;
  }

  /// Checks if time only.
  bool isTimeOnly() => _timeOnly;

  /// Sets the minimum allowed date.
  /// Also adds a [DateAfter] validation rule.
  DatePicker minDate(DateTime date) {
    _minDate = date;
    rule(DateAfter(date));
    return this;
  }

  /// Gets the minimum date.
  DateTime? getMinDate() => _minDate;

  /// Sets the maximum allowed date.
  /// Also adds a [DateBefore] validation rule.
  DatePicker maxDate(DateTime date) {
    _maxDate = date;
    rule(DateBefore(date));
    return this;
  }

  /// Gets the maximum date.
  DateTime? getMaxDate() => _maxDate;

  /// Sets the display format.
  DatePicker displayFormat(String format) {
    _displayFormat = format;
    return this;
  }

  /// Gets the display format.
  String getDisplayFormat() => _displayFormat;

  /// Uses native HTML date input.
  DatePicker native([bool native = true]) {
    _native = native;
    return this;
  }

  /// Checks if using native input.
  bool isNative() => _native;

  /// Sets the first day of week.
  DatePicker firstDayOfWeek(int day) {
    _firstDayOfWeek = day;
    return this;
  }

  /// Gets the first day of week.
  int getFirstDayOfWeek() => _firstDayOfWeek;

  /// Sets disabled dates.
  DatePicker disabledDates(List<DateTime> dates) {
    _disabledDates = dates;
    return this;
  }

  /// Gets disabled dates.
  List<DateTime>? getDisabledDates() => _disabledDates;

  /// Sets whether to close on selection.
  DatePicker closeOnSelect([bool close = true]) {
    _closeOnSelect = close;
    return this;
  }

  /// Checks if should close on select.
  bool shouldCloseOnSelect() => _closeOnSelect;

  /// Sets the minimum date to today.
  DatePicker minToday() {
    _minDate = DateTime.now();
    return this;
  }

  /// Sets the maximum date to today.
  DatePicker maxToday() {
    _maxDate = DateTime.now();
    return this;
  }

  /// Converts form input to DateTime value for database storage.
  @override
  dynamic dehydrateValue(dynamic value) {
    // First apply any custom dehydration callback
    final result = super.dehydrateValue(value);

    // Then convert to DateTime
    if (result == null || (result is String && result.isEmpty)) return null;
    if (result is DateTime) return result;
    if (result is String) {
      return DateTime.tryParse(result);
    }
    return null;
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();

    // Determine input type
    final inputType = _timeOnly
        ? InputType.time
        : _withTime
        ? 'datetime-local'
        : InputType.date;

    // Format dates for HTML5 inputs
    final attrs = <String, String>{};
    if (_minDate != null) {
      attrs['min'] = _formatDateForInput(_minDate!);
    }
    if (_maxDate != null) {
      attrs['max'] = _formatDateForInput(_maxDate!);
    }
    // Handle datetime-local type which Jaspr doesn't support directly
    if (inputType is String) {
      attrs['type'] = inputType;
    }

    // Default value
    final defaultVal = getDefaultValue();
    String? valueStr;
    if (defaultVal != null) {
      if (defaultVal is DateTime) {
        valueStr = _formatDateForInput(defaultVal);
      } else if (defaultVal is String) {
        valueStr = defaultVal;
      }
    }

    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (!isHidden()) FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // Input
        FormInput(
          type: inputType is InputType ? inputType : InputType.text,
          id: inputId,
          name: getName(),
          value: valueStr,
          required: isRequired(),
          disabled: isDisabled(),
          readonly: isReadonly(),
          autofocus: shouldAutofocus(),
          autocomplete: getAutocomplete(),
          tabindex: getTabindex(),
          attributes: attrs.isEmpty ? null : attrs,
        ),

        // Helper text
        if (getHelperText() != null) FormHelperText(helperText: getHelperText()!),
      ],
    );
  }

  /// Formats a DateTime for HTML5 date/time inputs.
  String _formatDateForInput(DateTime date) {
    if (_timeOnly) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    if (_withTime) {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}T${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
