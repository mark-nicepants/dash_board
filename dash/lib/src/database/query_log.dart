/// Query logging system for database operations.
///
/// Provides centralized logging of all database queries with timing,
/// parameters, and the ability to toggle logging on/off at runtime.
///
/// Example:
/// ```dart
/// // Enable logging
/// QueryLog.enable();
///
/// // Perform database operations...
/// await User.query().get();
///
/// // View logs
/// for (final entry in QueryLog.entries) {
///   print('${entry.sql} - ${entry.durationMs}ms');
/// }
///
/// // Clear logs
/// QueryLog.clear();
/// ```
class QueryLog {
  static bool _enabled = false;
  static final List<QueryLogEntry> _entries = [];
  static int _maxEntries = 100;

  /// Whether query logging is currently enabled.
  static bool get isEnabled => _enabled;

  /// All logged query entries.
  static List<QueryLogEntry> get entries => List.unmodifiable(_entries);

  /// The maximum number of entries to keep (oldest are removed first).
  static int get maxEntries => _maxEntries;

  /// Enables query logging.
  static void enable() {
    _enabled = true;
  }

  /// Disables query logging.
  static void disable() {
    _enabled = false;
  }

  /// Toggles query logging on/off.
  /// Returns the new state.
  static bool toggle() {
    _enabled = !_enabled;
    return _enabled;
  }

  /// Sets the maximum number of entries to keep.
  static void setMaxEntries(int max) {
    _maxEntries = max;
    _trimEntries();
  }

  /// Logs a query execution.
  ///
  /// [sql] - The SQL query string
  /// [parameters] - The bound parameters (optional)
  /// [duration] - The execution duration (optional)
  /// [rowCount] - Number of rows affected/returned (optional)
  static void log({required String sql, List<dynamic>? parameters, Duration? duration, int? rowCount}) {
    if (!_enabled) return;

    _entries.add(
      QueryLogEntry(
        sql: sql.trim().replaceAll(RegExp(r'\s+'), ' '),
        parameters: parameters,
        timestamp: DateTime.now(),
        duration: duration,
        rowCount: rowCount,
      ),
    );

    _trimEntries();
  }

  /// Clears all logged entries.
  static void clear() {
    _entries.clear();
  }

  /// Gets the last N entries.
  static List<QueryLogEntry> last([int count = 10]) {
    if (_entries.length <= count) {
      return List.unmodifiable(_entries);
    }
    return List.unmodifiable(_entries.sublist(_entries.length - count));
  }

  /// Gets the total count of logged queries.
  static int get count => _entries.length;

  /// Gets the total execution time of all logged queries.
  static Duration get totalDuration {
    var total = Duration.zero;
    for (final entry in _entries) {
      if (entry.duration != null) {
        total += entry.duration!;
      }
    }
    return total;
  }

  /// Removes old entries if we exceed maxEntries.
  static void _trimEntries() {
    while (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
  }

  /// Prints the query log to the console in a formatted way.
  static void printLog() {
    final output = StringBuffer();
    output.writeln('');
    output.writeln('📊 Query Log (${_entries.length} queries, ${isEnabled ? "enabled" : "disabled"})');
    output.writeln('─' * 60);

    if (_entries.isEmpty) {
      output.writeln('  No queries logged.');
    } else {
      for (var i = 0; i < _entries.length; i++) {
        final entry = _entries[i];
        output.writeln('  ${i + 1}. ${entry.sql}');

        if (entry.parameters != null && entry.parameters!.isNotEmpty) {
          output.writeln('     Parameters: ${entry.parameters}');
        }

        final meta = <String>[];
        if (entry.duration != null) {
          meta.add('${entry.durationMs.toStringAsFixed(2)}ms');
        }
        if (entry.rowCount != null) {
          meta.add('${entry.rowCount} rows');
        }
        meta.add(_formatTimestamp(entry.timestamp));

        if (meta.isNotEmpty) {
          output.writeln('     ${meta.join(' • ')}');
        }
        output.writeln('');
      }

      // Summary
      output.writeln('─' * 60);
      output.writeln('  Total: ${_entries.length} queries in ${totalDuration.inMilliseconds}ms');
    }

    output.writeln('');

    // Use print here since this is console output
    // ignore: avoid_print
    print(output.toString());
  }

  static String _formatTimestamp(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

/// A single logged query entry.
class QueryLogEntry {
  /// The SQL query that was executed.
  final String sql;

  /// The bound parameters for the query.
  final List<dynamic>? parameters;

  /// When the query was executed.
  final DateTime timestamp;

  /// How long the query took to execute.
  final Duration? duration;

  /// Number of rows affected or returned.
  final int? rowCount;

  const QueryLogEntry({required this.sql, this.parameters, required this.timestamp, this.duration, this.rowCount});

  /// Duration in milliseconds as a double.
  double get durationMs => (duration?.inMicroseconds.toDouble() ?? 0) / 1000;

  @override
  String toString() {
    final buffer = StringBuffer(sql);
    if (parameters != null && parameters!.isNotEmpty) {
      buffer.write(' [${parameters!.join(', ')}]');
    }
    if (duration != null) {
      buffer.write(' (${durationMs.toStringAsFixed(2)}ms)');
    }
    return buffer.toString();
  }
}
