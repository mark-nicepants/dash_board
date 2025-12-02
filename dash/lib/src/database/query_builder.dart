import 'package:dash/src/database/database_connector.dart';

/// A fluent query builder for constructing database queries.
///
/// Provides a chainable API for building SELECT, INSERT, UPDATE, and DELETE
/// queries in a type-safe and readable manner.
class QueryBuilder {
  final DatabaseConnector _connector;
  String? _table;
  List<String> _columns = ['*'];
  final List<String> _wheres = [];
  final List<dynamic> _bindings = [];
  final List<String> _orderBy = [];
  final List<String> _groupBy = [];
  final List<String> _having = [];
  final List<dynamic> _havingBindings = [];
  int? _limit;
  int? _offset;

  QueryBuilder(this._connector);

  /// Gets the database connector for this query builder.
  DatabaseConnector get connector => _connector;

  /// Sets the table to query from.
  QueryBuilder table(String table) {
    _table = table;
    return this;
  }

  /// Sets the columns to select.
  QueryBuilder select([List<String>? columns]) {
    if (columns != null && columns.isNotEmpty) {
      _columns = columns;
    }
    return this;
  }

  /// Adds a raw SQL expression to the select clause.
  ///
  /// Use this for aggregate functions, JSON extraction, or other
  /// expressions not covered by the standard select method.
  ///
  /// Example:
  /// ```dart
  /// query.selectRaw('COUNT(*) as total');
  /// query.selectRaw("date(created_at) as period");
  /// ```
  QueryBuilder selectRaw(String expression) {
    if (_columns.length == 1 && _columns.first == '*') {
      _columns = [expression];
    } else {
      _columns.add(expression);
    }
    return this;
  }

  /// Adds a WHERE clause.
  QueryBuilder where(String column, String operator, dynamic value) {
    _wheres.add('$column $operator ?');
    _bindings.add(value);
    return this;
  }

  /// Adds an OR WHERE clause.
  QueryBuilder orWhere(String column, String operator, dynamic value) {
    if (_wheres.isEmpty) {
      return where(column, operator, value);
    }
    final lastIndex = _wheres.length - 1;
    _wheres[lastIndex] = '${_wheres[lastIndex]} OR $column $operator ?';
    _bindings.add(value);
    return this;
  }

  /// Adds a WHERE BETWEEN clause.
  QueryBuilder whereBetween(String column, dynamic min, dynamic max) {
    _wheres.add('$column BETWEEN ? AND ?');
    _bindings.add(min);
    _bindings.add(max);
    return this;
  }

  /// Adds a WHERE NOT BETWEEN clause.
  QueryBuilder whereNotBetween(String column, dynamic min, dynamic max) {
    _wheres.add('$column NOT BETWEEN ? AND ?');
    _bindings.add(min);
    _bindings.add(max);
    return this;
  }

  /// Adds a WHERE IN clause.
  QueryBuilder whereIn(String column, List<dynamic> values) {
    final placeholders = List.filled(values.length, '?').join(', ');
    _wheres.add('$column IN ($placeholders)');
    _bindings.addAll(values);
    return this;
  }

  /// Adds a WHERE NOT IN clause.
  QueryBuilder whereNotIn(String column, List<dynamic> values) {
    final placeholders = List.filled(values.length, '?').join(', ');
    _wheres.add('$column NOT IN ($placeholders)');
    _bindings.addAll(values);
    return this;
  }

  /// Adds a WHERE NULL clause.
  QueryBuilder whereNull(String column) {
    _wheres.add('$column IS NULL');
    return this;
  }

  /// Adds a WHERE NOT NULL clause.
  QueryBuilder whereNotNull(String column) {
    _wheres.add('$column IS NOT NULL');
    return this;
  }

  /// Adds a raw WHERE clause with bindings.
  ///
  /// Use this for complex conditions not covered by the standard where methods.
  ///
  /// Example:
  /// ```dart
  /// query.whereRaw('LOWER(name) = ?', ['john']);
  /// ```
  QueryBuilder whereRaw(String expression, [List<dynamic>? bindings]) {
    _wheres.add(expression);
    if (bindings != null) {
      _bindings.addAll(bindings);
    }
    return this;
  }

  /// Adds a WHERE clause that filters by a JSON path value.
  ///
  /// This method provides database-agnostic JSON querying.
  /// Currently uses SQLite's json_extract function. When MySQL/PostgreSQL
  /// connectors are added, this will be overridden to use their native
  /// JSON operators (e.g., MySQL's ->> or PostgreSQL's @>).
  ///
  /// Example:
  /// ```dart
  /// query.whereJsonPath('tags', 'path', '/dashboard');
  /// // Generates: json_extract(tags, '$.path') = ?
  /// ```
  QueryBuilder whereJsonPath(String column, String path, dynamic value) {
    _wheres.add("json_extract($column, '\$.$path') = ?");
    _bindings.add(value.toString());
    return this;
  }

  /// Adds an ORDER BY clause.
  QueryBuilder orderBy(String column, [String direction = 'ASC']) {
    _orderBy.add('$column $direction');
    return this;
  }

  /// Adds a GROUP BY clause.
  QueryBuilder groupBy(String column) {
    _groupBy.add(column);
    return this;
  }

  /// Adds a raw GROUP BY expression.
  ///
  /// Use this for complex grouping expressions like date functions.
  ///
  /// Example:
  /// ```dart
  /// query.groupByRaw("date(created_at)");
  /// ```
  QueryBuilder groupByRaw(String expression) {
    _groupBy.add(expression);
    return this;
  }

  /// Adds a HAVING clause.
  QueryBuilder having(String column, dynamic value, [String operator = '=']) {
    _having.add('$column $operator ?');
    _havingBindings.add(value);
    return this;
  }

  /// Sets the LIMIT clause.
  QueryBuilder limit(int limit) {
    _limit = limit;
    return this;
  }

  /// Sets the OFFSET clause.
  QueryBuilder offset(int offset) {
    _offset = offset;
    return this;
  }

  /// Executes the query and returns all results.
  Future<List<Map<String, dynamic>>> get() async {
    if (_table == null) {
      throw StateError('Table name is required');
    }

    final sql = _buildSelectSql();
    final allBindings = [..._bindings, ..._havingBindings];
    return await _connector.query(sql, allBindings);
  }

  /// Executes the query and returns the first result, or null if no results.
  Future<Map<String, dynamic>?> first() async {
    limit(1);
    final results = await get();
    return results.isNotEmpty ? results.first : null;
  }

  /// Executes the query and returns a single value.
  Future<T?> value<T>(String column) async {
    select([column]);
    final result = await first();
    return result?[column] as T?;
  }

  /// Returns the count of records matching the query.
  Future<int> count([String column = '*']) async {
    select(['COUNT($column) as count']);
    final result = await first();
    return result?['count'] as int? ?? 0;
  }

  /// Returns the sum of a column.
  Future<num> sum(String column) async {
    select(['SUM($column) as sum']);
    final result = await first();
    return result?['sum'] as num? ?? 0;
  }

  /// Returns the average of a column.
  Future<num> avg(String column) async {
    select(['AVG($column) as avg']);
    final result = await first();
    return result?['avg'] as num? ?? 0;
  }

  /// Returns the maximum value of a column.
  Future<T?> max<T>(String column) async {
    select(['MAX($column) as max']);
    final result = await first();
    return result?['max'] as T?;
  }

  /// Returns the minimum value of a column.
  Future<T?> min<T>(String column) async {
    select(['MIN($column) as min']);
    final result = await first();
    return result?['min'] as T?;
  }

  /// Inserts a record and returns the inserted ID.
  Future<int> insert(Map<String, dynamic> data) async {
    if (_table == null) {
      throw StateError('Table name is required');
    }
    return await _connector.insert(_table!, data);
  }

  /// Updates records and returns the number of affected rows.
  Future<int> update(Map<String, dynamic> data) async {
    if (_table == null) {
      throw StateError('Table name is required');
    }

    final whereClause = _wheres.isNotEmpty ? _wheres.join(' AND ') : null;
    return await _connector.update(_table!, data, where: whereClause, whereArgs: _bindings);
  }

  /// Deletes records and returns the number of affected rows.
  Future<int> delete() async {
    if (_table == null) {
      throw StateError('Table name is required');
    }

    final whereClause = _wheres.isNotEmpty ? _wheres.join(' AND ') : null;
    return await _connector.delete(_table!, where: whereClause, whereArgs: _bindings);
  }

  /// Builds the SELECT SQL statement.
  String _buildSelectSql() {
    final buffer = StringBuffer();

    // SELECT clause
    buffer.write('SELECT ${_columns.join(', ')} FROM $_table');

    // WHERE clause
    if (_wheres.isNotEmpty) {
      buffer.write(' WHERE ${_wheres.join(' AND ')}');
    }

    // GROUP BY clause
    if (_groupBy.isNotEmpty) {
      buffer.write(' GROUP BY ${_groupBy.join(', ')}');
    }

    // HAVING clause
    if (_having.isNotEmpty) {
      buffer.write(' HAVING ${_having.join(' AND ')}');
    }

    // ORDER BY clause
    if (_orderBy.isNotEmpty) {
      buffer.write(' ORDER BY ${_orderBy.join(', ')}');
    }

    // LIMIT clause
    if (_limit != null) {
      buffer.write(' LIMIT $_limit');
    }

    // OFFSET clause
    if (_offset != null) {
      buffer.write(' OFFSET $_offset');
    }

    return buffer.toString();
  }

  /// Resets the query builder to its initial state.
  void reset() {
    _table = null;
    _columns = ['*'];
    _wheres.clear();
    _bindings.clear();
    _orderBy.clear();
    _groupBy.clear();
    _having.clear();
    _havingBindings.clear();
    _limit = null;
    _offset = null;
  }
}
