/// Time period for aggregating metrics.
enum Period {
  /// Aggregate by hour.
  hour,

  /// Aggregate by day.
  day,

  /// Aggregate by week.
  week,

  /// Aggregate by month.
  month,

  /// Aggregate by year.
  year,
}

/// Extension methods for Period.
extension PeriodExtension on Period {
  /// Returns the granularity string for use with [DatabaseConnector.dateTrunc].
  ///
  /// This is the database-agnostic way to get date truncation.
  String get granularity {
    switch (this) {
      case Period.hour:
        return 'hour';
      case Period.day:
        return 'day';
      case Period.week:
        return 'week';
      case Period.month:
        return 'month';
      case Period.year:
        return 'year';
    }
  }

  /// Returns the duration for this period.
  Duration get duration {
    switch (this) {
      case Period.hour:
        return const Duration(hours: 1);
      case Period.day:
        return const Duration(days: 1);
      case Period.week:
        return const Duration(days: 7);
      case Period.month:
        return const Duration(days: 30);
      case Period.year:
        return const Duration(days: 365);
    }
  }

  /// Returns a DateTime representing the start of the current period.
  DateTime startOf(DateTime date) {
    switch (this) {
      case Period.hour:
        return DateTime(date.year, date.month, date.day, date.hour);
      case Period.day:
        return DateTime(date.year, date.month, date.day);
      case Period.week:
        final weekday = date.weekday;
        return DateTime(date.year, date.month, date.day - (weekday - 1));
      case Period.month:
        return DateTime(date.year, date.month);
      case Period.year:
        return DateTime(date.year);
    }
  }

  /// Returns a DateTime representing the end of the current period.
  DateTime endOf(DateTime date) {
    switch (this) {
      case Period.hour:
        return DateTime(date.year, date.month, date.day, date.hour, 59, 59, 999);
      case Period.day:
        return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
      case Period.week:
        final weekday = date.weekday;
        final endOfWeek = DateTime(date.year, date.month, date.day + (7 - weekday));
        return DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59, 999);
      case Period.month:
        return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
      case Period.year:
        return DateTime(date.year, 12, 31, 23, 59, 59, 999);
    }
  }

  /// Generates a list of period start dates from [start] to [end].
  List<DateTime> generateRange(DateTime start, DateTime end) {
    final dates = <DateTime>[];
    var current = startOf(start);

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(current);
      switch (this) {
        case Period.hour:
          current = current.add(const Duration(hours: 1));
        case Period.day:
          current = current.add(const Duration(days: 1));
        case Period.week:
          current = current.add(const Duration(days: 7));
        case Period.month:
          current = DateTime(current.year, current.month + 1, current.day);
        case Period.year:
          current = DateTime(current.year + 1, current.month, current.day);
      }
    }

    return dates;
  }
}
