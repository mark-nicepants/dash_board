import 'package:dash/src/database/database_connector.dart';
import 'package:dash/src/database/query_builder.dart';
import 'package:dash/src/model/model.dart';

/// A query builder that returns typed model instances.
///
/// Wraps QueryBuilder to work with Model classes,
/// automatically converting database rows to model instances.
///
/// By default, get() and first() return typed models. Use getMap()
/// and firstMap() if you need raw database maps.
class ModelQueryBuilder<T extends Model> {
  final QueryBuilder _query;
  final T Function()? _modelFactory;
  final String? _modelPrimaryKey;

  ModelQueryBuilder(
    DatabaseConnector connector, {
    T Function()? modelFactory,
    String? modelTable,
    String? modelPrimaryKey,
  }) : _query = QueryBuilder(connector),
       _modelFactory = modelFactory,
       _modelPrimaryKey = modelPrimaryKey {
    if (modelTable != null) {
      _query.table(modelTable);
    }
  }

  /// Sets the model factory for this query builder.
  ModelQueryBuilder<T> model(T Function() factory) {
    return ModelQueryBuilder<T>(_query.connector, modelFactory: factory, modelPrimaryKey: _modelPrimaryKey);
  }

  /// Sets the table for this query.
  ModelQueryBuilder<T> table(String table) {
    _query.table(table);
    return this;
  }

  /// Executes the query and returns typed model instances.
  /// This is the default behavior - use getMap() for raw maps.
  Future<List<T>> get() async {
    if (_modelFactory == null) {
      throw StateError('Model factory not set. Use model() or provide factory in constructor.');
    }

    final results = await getMap();
    return results.map((row) {
      final model = _modelFactory();
      model.fromMap(row);
      return model;
    }).toList();
  }

  /// Executes the query and returns the first model, or null.
  /// This is the default behavior - use firstMap() for raw maps.
  Future<T?> first() async {
    if (_modelFactory == null) {
      throw StateError('Model factory not set. Use model() or provide factory in constructor.');
    }

    final result = await firstMap();
    if (result == null) return null;

    final model = _modelFactory();
    model.fromMap(result);
    return model;
  }

  /// Executes the query and returns raw maps instead of typed models.
  Future<List<Map<String, dynamic>>> getMap() {
    return _query.get();
  }

  /// Executes the query and returns the first result as a raw map.
  Future<Map<String, dynamic>?> firstMap() {
    return _query.first();
  }

  /// Finds a model by its primary key.
  Future<T?> find(dynamic id) async {
    if (_modelFactory == null) {
      throw StateError('Model factory not set. Use model() or provide factory in constructor.');
    }

    final model = _modelFactory();
    final primaryKey = _modelPrimaryKey ?? model.primaryKey;

    where(primaryKey, id);
    return await first();
  }

  /// Returns the count of records matching the query.
  Future<int> count([String column = '*']) => _query.count(column);

  /// Returns a single value from the query.
  Future<V?> value<V>(String column) => _query.value<V>(column);

  // Query builder methods that return ModelQueryBuilder for chaining

  ModelQueryBuilder<T> select([List<String>? columns]) {
    _query.select(columns);
    return this;
  }

  ModelQueryBuilder<T> where(String column, dynamic value, [String operator = '=']) {
    _query.where(column, value, operator);
    return this;
  }

  ModelQueryBuilder<T> orWhere(String column, dynamic value, [String operator = '=']) {
    _query.orWhere(column, value, operator);
    return this;
  }

  ModelQueryBuilder<T> whereBetween(String column, dynamic min, dynamic max) {
    _query.whereBetween(column, min, max);
    return this;
  }

  ModelQueryBuilder<T> whereNotBetween(String column, dynamic min, dynamic max) {
    _query.whereNotBetween(column, min, max);
    return this;
  }

  ModelQueryBuilder<T> whereIn(String column, List<dynamic> values) {
    _query.whereIn(column, values);
    return this;
  }

  ModelQueryBuilder<T> whereNotIn(String column, List<dynamic> values) {
    _query.whereNotIn(column, values);
    return this;
  }

  ModelQueryBuilder<T> whereNull(String column) {
    _query.whereNull(column);
    return this;
  }

  ModelQueryBuilder<T> whereNotNull(String column) {
    _query.whereNotNull(column);
    return this;
  }

  ModelQueryBuilder<T> orderBy(String column, [String direction = 'ASC']) {
    _query.orderBy(column, direction);
    return this;
  }

  ModelQueryBuilder<T> groupBy(String column) {
    _query.groupBy(column);
    return this;
  }

  ModelQueryBuilder<T> having(String column, dynamic value, [String operator = '=']) {
    _query.having(column, value, operator);
    return this;
  }

  ModelQueryBuilder<T> limit(int limit) {
    _query.limit(limit);
    return this;
  }

  ModelQueryBuilder<T> offset(int offset) {
    _query.offset(offset);
    return this;
  }

  /// Returns the sum of a column.
  Future<num> sum(String column) => _query.sum(column);

  /// Returns the average of a column.
  Future<num> avg(String column) => _query.avg(column);

  /// Returns the maximum value of a column.
  Future<V?> max<V>(String column) => _query.max<V>(column);

  /// Returns the minimum value of a column.
  Future<V?> min<V>(String column) => _query.min<V>(column);

  /// Inserts a record and returns the inserted ID.
  Future<int> insert(Map<String, dynamic> data) => _query.insert(data);

  /// Updates records and returns the number of affected rows.
  Future<int> update(Map<String, dynamic> data) => _query.update(data);

  /// Deletes records and returns the number of affected rows.
  Future<int> delete() => _query.delete();
}
