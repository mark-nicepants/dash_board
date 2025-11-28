/// Exception thrown when model validation fails.
class ValidationException implements Exception {
  final Map<String, List<String>> errors;

  ValidationException(this.errors);

  @override
  String toString() {
    final buffer = StringBuffer('Validation failed:\n');
    errors.forEach((field, messages) {
      buffer.writeln('  $field: ${messages.join(', ')}');
    });
    return buffer.toString();
  }
}

/// Base class for validation rules.
///
/// All validation rules must implement [name] for identification
/// and [validate] for the actual validation logic.
abstract class ValidationRule {
  /// A unique string identifier for this rule (e.g., 'required', 'email', 'min:8').
  String get name;

  /// Validates the given value.
  /// Returns null if valid, or an error message if invalid.
  String? validate(String field, dynamic value);
}

/// Rule that requires a value to be present.
class Required extends ValidationRule {
  @override
  String get name => 'required';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '' || (value is List && value.isEmpty)) {
      return 'The $field field is required.';
    }
    return null;
  }
}

/// Rule that validates an email address.
class Email extends ValidationRule {
  static final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

  @override
  String get name => 'email';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null; // Use Required for non-null
    if (value is! String) return 'The $field must be a string.';
    if (!_emailRegex.hasMatch(value)) {
      return 'The $field must be a valid email address.';
    }
    return null;
  }
}

/// Rule that validates a URL.
class Url extends ValidationRule {
  @override
  String get name => 'url';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    if (value is! String) return 'The $field must be a string.';
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'The $field must be a valid URL.';
    }
    return null;
  }
}

/// Rule that validates a minimum length.
class MinLength extends ValidationRule {
  final int min;

  MinLength(this.min);

  @override
  String get name => 'min:$min';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    final length = value is String ? value.length : value.toString().length;
    if (length < min) {
      return 'The $field must be at least $min characters.';
    }
    return null;
  }
}

/// Rule that validates a maximum length.
class MaxLength extends ValidationRule {
  final int max;

  MaxLength(this.max);

  @override
  String get name => 'max:$max';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    final length = value is String ? value.length : value.toString().length;
    if (length > max) {
      return 'The $field must not exceed $max characters.';
    }
    return null;
  }
}

/// Rule that validates a numeric value.
class Numeric extends ValidationRule {
  @override
  String get name => 'numeric';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    if (value is num) return null;
    if (value is String && num.tryParse(value) != null) return null;
    return 'The $field must be a number.';
  }
}

/// Rule that validates integer input.
class Integer extends ValidationRule {
  @override
  String get name => 'integer';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    if (value is int) return null;
    if (value is String && int.tryParse(value) != null) return null;
    return 'The $field must be an integer.';
  }
}

/// Rule that validates a minimum numeric value.
class Min extends ValidationRule {
  final num min;

  Min(this.min);

  @override
  String get name => 'min:$min';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    num? numValue;
    if (value is num) {
      numValue = value;
    } else if (value is String) {
      numValue = num.tryParse(value);
    }
    if (numValue == null) return 'The $field must be a number.';
    if (numValue < min) {
      return 'The $field must be at least $min.';
    }
    return null;
  }
}

/// Rule that validates a maximum numeric value.
class Max extends ValidationRule {
  final num max;

  Max(this.max);

  @override
  String get name => 'max:$max';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    num? numValue;
    if (value is num) {
      numValue = value;
    } else if (value is String) {
      numValue = num.tryParse(value);
    }
    if (numValue == null) return 'The $field must be a number.';
    if (numValue > max) {
      return 'The $field must not exceed $max.';
    }
    return null;
  }
}

/// Rule that validates a value is in a list of allowed values.
class InList extends ValidationRule {
  final List<dynamic> allowed;

  InList(this.allowed);

  @override
  String get name => 'in:${allowed.join(',')}';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    if (!allowed.contains(value)) {
      return 'The selected $field is invalid.';
    }
    return null;
  }
}

/// Rule that validates a value matches a regex pattern.
class Pattern extends ValidationRule {
  final RegExp pattern;
  final String? message;

  Pattern(this.pattern, {this.message});

  @override
  String get name => 'regex';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    final str = value.toString();
    if (!pattern.hasMatch(str)) {
      return message ?? 'The $field format is invalid.';
    }
    return null;
  }
}

/// Rule that requires a checkbox to be accepted.
class Accepted extends ValidationRule {
  @override
  String get name => 'accepted';

  @override
  String? validate(String field, dynamic value) {
    if (value == true || value == 1 || value == '1' || value == 'on' || value == 'yes') {
      return null;
    }
    return 'The $field must be accepted.';
  }
}

/// Rule that validates confirmed fields match.
class Confirmed extends ValidationRule {
  final String confirmationField;
  final dynamic confirmationValue;

  Confirmed(this.confirmationField, this.confirmationValue);

  @override
  String get name => 'confirmed';

  @override
  String? validate(String field, dynamic value) {
    if (value == null || value == '') return null;
    if (value != confirmationValue) {
      return 'The $field confirmation does not match.';
    }
    return null;
  }
}

/// Rule that validates a value is unique in the database.
class Unique extends ValidationRule {
  final String table;
  final String column;
  final dynamic ignoreId;
  final String? ignoreColumn;

  Unique(this.table, this.column, {this.ignoreId, this.ignoreColumn = 'id'});

  @override
  String get name => 'unique:$table,$column';

  @override
  String? validate(String field, dynamic value) {
    // This needs database access, so it's marked for async implementation
    // For now, return null (will be implemented in Model class)
    return null;
  }
}
