/// Input sanitization utilities for Dash.
///
/// Provides functions to sanitize user input to prevent security vulnerabilities
/// such as SQL injection and XSS attacks.
///
/// Sanitizes a search query string for use in SQL LIKE clauses.
///
/// This function escapes SQL wildcard characters (% and _) that could be used
/// to manipulate LIKE queries. It also trims whitespace and limits the length
/// to prevent excessive resource usage.
///
/// Example:
/// ```dart
/// final userInput = "admin%' OR '1'='1";
/// final safe = sanitizeSearchQuery(userInput);
/// // Returns: "admin\%' OR '1'='1"
/// ```
///
/// **Note**: This function escapes wildcards but does NOT prevent SQL injection
/// on its own. Always use parameterized queries (which Dash does by default).
///
/// [input] - The raw search query string from user input
/// [maxLength] - Maximum allowed length (default: 255 characters)
///
/// Returns the sanitized search query string, or empty string if input is null
String sanitizeSearchQuery(String? input, {int maxLength = 255}) {
  if (input == null || input.isEmpty) {
    return '';
  }

  // Trim whitespace
  var sanitized = input.trim();

  // Limit length to prevent resource exhaustion
  if (sanitized.length > maxLength) {
    sanitized = sanitized.substring(0, maxLength);
  }

  // Escape SQL LIKE wildcards to prevent users from injecting their own wildcards
  // We add our own % wildcards in the query builder
  sanitized = sanitized
      .replaceAll(r'\', r'\\') // Escape backslashes first
      .replaceAll('%', r'\%') // Escape percent signs
      .replaceAll('_', r'\_'); // Escape underscores

  return sanitized;
}

/// Sanitizes a string for safe HTML output.
///
/// Escapes HTML special characters to prevent XSS attacks.
///
/// [input] - The raw string from user input
///
/// Returns the sanitized string with HTML entities escaped
String sanitizeHtml(String? input) {
  if (input == null || input.isEmpty) {
    return '';
  }

  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;')
      .replaceAll('/', '&#x2F;');
}

/// Validates that a column name is safe to use in SQL queries.
///
/// This prevents SQL injection through column names in sorting/filtering.
/// Only allows alphanumeric characters and underscores.
///
/// [columnName] - The column name to validate
///
/// Returns true if the column name is safe, false otherwise
bool isValidColumnName(String? columnName) {
  if (columnName == null || columnName.isEmpty) {
    return false;
  }

  // Only allow alphanumeric characters and underscores
  final validPattern = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
  return validPattern.hasMatch(columnName);
}
