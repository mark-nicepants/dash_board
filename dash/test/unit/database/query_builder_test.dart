import 'package:dash/dash.dart';
import 'package:test/test.dart';

/// Mock database connector for testing query builder
class MockDatabaseConnector extends DatabaseConnector {
  final List<String> executedQueries = [];
  final List<List<dynamic>> executedBindings = [];
  List<Map<String, dynamic>> mockResults = [];
  int mockInsertId = 1;
  int mockAffectedRows = 1;

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}

  @override
  bool get isConnected => true;

  @override
  DatabaseConnectorType get type => DatabaseConnectorType.sqlite;

  @override
  Future<List<Map<String, dynamic>>> queryImpl(String sql, [List<dynamic>? params]) async {
    executedQueries.add(sql);
    executedBindings.add(params ?? []);
    return mockResults;
  }

  @override
  Future<int> executeImpl(String sql, [List<dynamic>? params]) async {
    executedQueries.add(sql);
    executedBindings.add(params ?? []);
    return mockAffectedRows;
  }

  @override
  Future<int> insertImpl(String table, Map<String, dynamic> data) async {
    final columns = data.keys.join(', ');
    final placeholders = List.filled(data.length, '?').join(', ');
    executedQueries.add('INSERT INTO $table ($columns) VALUES ($placeholders)');
    executedBindings.add(data.values.toList());
    return mockInsertId++;
  }

  @override
  Future<int> updateImpl(String table, Map<String, dynamic> data, {String? where, List<dynamic>? whereArgs}) async {
    final sets = data.keys.map((k) => '$k = ?').join(', ');
    var sql = 'UPDATE $table SET $sets';
    if (where != null) sql += ' WHERE $where';
    executedQueries.add(sql);
    executedBindings.add([...data.values, ...?whereArgs]);
    return mockAffectedRows;
  }

  @override
  Future<int> deleteImpl(String table, {String? where, List<dynamic>? whereArgs}) async {
    var sql = 'DELETE FROM $table';
    if (where != null) sql += ' WHERE $where';
    executedQueries.add(sql);
    executedBindings.add(whereArgs ?? []);
    return mockAffectedRows;
  }

  @override
  Future<void> beginTransaction() async {}

  @override
  Future<void> commit() async {}

  @override
  Future<void> rollback() async {}

  @override
  String dateTrunc(String column, String granularity) {
    switch (granularity) {
      case 'hour':
        return "strftime('%Y-%m-%d %H:00:00', $column)";
      case 'day':
        return 'date($column)';
      case 'week':
        return "date($column, 'weekday 0', '-6 days')";
      case 'month':
        return "strftime('%Y-%m-01', $column)";
      case 'year':
        return "strftime('%Y-01-01', $column)";
      default:
        throw ArgumentError('Invalid granularity: $granularity');
    }
  }

  void reset() {
    executedQueries.clear();
    executedBindings.clear();
    mockResults = [];
    mockInsertId = 1;
    mockAffectedRows = 1;
  }
}

void main() {
  group('QueryBuilder', () {
    late MockDatabaseConnector connector;
    late QueryBuilder builder;

    setUp(() {
      connector = MockDatabaseConnector();
      builder = QueryBuilder(connector);
    });

    group('Basic Query Building', () {
      test('table() sets the table name', () async {
        connector.mockResults = [
          {'id': 1, 'name': 'Test'},
        ];

        await builder.table('users').get();

        expect(connector.executedQueries.last, contains('FROM users'));
      });

      test('select() sets columns', () async {
        connector.mockResults = [];

        await builder.table('users').select(['id', 'name', 'email']).get();

        expect(connector.executedQueries.last, contains('SELECT id, name, email'));
      });

      test('select() with no columns defaults to *', () async {
        connector.mockResults = [];

        await builder.table('users').get();

        expect(connector.executedQueries.last, contains('SELECT *'));
      });
    });

    group('WHERE Clauses', () {
      test('where() adds basic condition', () async {
        connector.mockResults = [];

        await builder.table('users').where('status', '=', 'active').get();

        expect(connector.executedQueries.last, contains('WHERE status = ?'));
        expect(connector.executedBindings.last, contains('active'));
      });

      test('where() with custom operator', () async {
        connector.mockResults = [];

        await builder.table('users').where('age', '>=', 18).get();

        expect(connector.executedQueries.last, contains('WHERE age >= ?'));
        expect(connector.executedBindings.last, contains(18));
      });

      test('multiple where() creates AND conditions', () async {
        connector.mockResults = [];

        await builder.table('users').where('status', '=', 'active').where('age', '>=', 18).get();

        expect(connector.executedQueries.last, contains('WHERE status = ? AND age >= ?'));
      });

      test('orWhere() adds OR condition', () async {
        connector.mockResults = [];

        await builder.table('users').where('status', '=', 'active').orWhere('role', '=', 'admin').get();

        expect(connector.executedQueries.last, contains('status = ? OR role = ?'));
      });

      test('orWhere() on first call acts as where()', () async {
        connector.mockResults = [];

        await builder.table('users').orWhere('status', '=', 'active').get();

        expect(connector.executedQueries.last, contains('WHERE status = ?'));
      });

      test('whereBetween() adds BETWEEN clause', () async {
        connector.mockResults = [];

        await builder.table('products').whereBetween('price', 10, 100).get();

        expect(connector.executedQueries.last, contains('WHERE price BETWEEN ? AND ?'));
        expect(connector.executedBindings.last, equals([10, 100]));
      });

      test('whereNotBetween() adds NOT BETWEEN clause', () async {
        connector.mockResults = [];

        await builder.table('products').whereNotBetween('price', 10, 100).get();

        expect(connector.executedQueries.last, contains('WHERE price NOT BETWEEN ? AND ?'));
      });

      test('whereIn() adds IN clause', () async {
        connector.mockResults = [];

        await builder.table('users').whereIn('status', ['active', 'pending', 'approved']).get();

        expect(connector.executedQueries.last, contains('WHERE status IN (?, ?, ?)'));
        expect(connector.executedBindings.last, equals(['active', 'pending', 'approved']));
      });

      test('whereNotIn() adds NOT IN clause', () async {
        connector.mockResults = [];

        await builder.table('users').whereNotIn('status', ['banned', 'deleted']).get();

        expect(connector.executedQueries.last, contains('WHERE status NOT IN (?, ?)'));
      });

      test('whereNull() adds IS NULL clause', () async {
        connector.mockResults = [];

        await builder.table('users').whereNull('deleted_at').get();

        expect(connector.executedQueries.last, contains('WHERE deleted_at IS NULL'));
      });

      test('whereNotNull() adds IS NOT NULL clause', () async {
        connector.mockResults = [];

        await builder.table('users').whereNotNull('email_verified_at').get();

        expect(connector.executedQueries.last, contains('WHERE email_verified_at IS NOT NULL'));
      });
    });

    group('ORDER BY', () {
      test('orderBy() adds ORDER BY clause', () async {
        connector.mockResults = [];

        await builder.table('users').orderBy('created_at').get();

        expect(connector.executedQueries.last, contains('ORDER BY created_at ASC'));
      });

      test('orderBy() with DESC direction', () async {
        connector.mockResults = [];

        await builder.table('users').orderBy('created_at', 'DESC').get();

        expect(connector.executedQueries.last, contains('ORDER BY created_at DESC'));
      });

      test('multiple orderBy() clauses', () async {
        connector.mockResults = [];

        await builder.table('users').orderBy('status').orderBy('name', 'ASC').get();

        expect(connector.executedQueries.last, contains('ORDER BY status ASC, name ASC'));
      });
    });

    group('GROUP BY and HAVING', () {
      test('groupBy() adds GROUP BY clause', () async {
        connector.mockResults = [];

        await builder.table('orders').select(['status', 'COUNT(*) as count']).groupBy('status').get();

        expect(connector.executedQueries.last, contains('GROUP BY status'));
      });

      test('having() adds HAVING clause', () async {
        connector.mockResults = [];

        await builder
            .table('orders')
            .select(['status', 'COUNT(*) as count'])
            .groupBy('status')
            .having('count', 5, '>')
            .get();

        expect(connector.executedQueries.last, contains('HAVING count > ?'));
      });
    });

    group('LIMIT and OFFSET', () {
      test('limit() sets LIMIT clause', () async {
        connector.mockResults = [];

        await builder.table('users').limit(10).get();

        expect(connector.executedQueries.last, contains('LIMIT 10'));
      });

      test('offset() sets OFFSET clause', () async {
        connector.mockResults = [];

        await builder.table('users').limit(10).offset(20).get();

        expect(connector.executedQueries.last, contains('OFFSET 20'));
      });
    });

    group('Execution Methods', () {
      test('get() returns all results', () async {
        connector.mockResults = [
          {'id': 1, 'name': 'User 1'},
          {'id': 2, 'name': 'User 2'},
        ];

        final results = await builder.table('users').get();

        expect(results.length, equals(2));
        expect(results[0]['name'], equals('User 1'));
      });

      test('first() returns first result', () async {
        connector.mockResults = [
          {'id': 1, 'name': 'User 1'},
        ];

        final result = await builder.table('users').first();

        expect(result, isNotNull);
        expect(result!['name'], equals('User 1'));
      });

      test('first() returns null when no results', () async {
        connector.mockResults = [];

        final result = await builder.table('users').first();

        expect(result, isNull);
      });

      test('value() returns single column value', () async {
        connector.mockResults = [
          {'email': 'test@example.com'},
        ];

        final email = await builder.table('users').where('id', '=', 1).value<String>('email');

        expect(email, equals('test@example.com'));
      });

      test('count() returns record count', () async {
        connector.mockResults = [
          {'count': 42},
        ];

        final count = await builder.table('users').count();

        expect(count, equals(42));
      });

      test('count() returns 0 when no results', () async {
        connector.mockResults = [
          {'count': null},
        ];

        final count = await builder.table('users').count();

        expect(count, equals(0));
      });

      test('sum() returns column sum', () async {
        connector.mockResults = [
          {'sum': 1500.50},
        ];

        final total = await builder.table('orders').sum('total');

        expect(total, equals(1500.50));
      });

      test('avg() returns column average', () async {
        connector.mockResults = [
          {'avg': 75.5},
        ];

        final average = await builder.table('scores').avg('score');

        expect(average, equals(75.5));
      });

      test('max() returns maximum value', () async {
        connector.mockResults = [
          {'max': 100},
        ];

        final maxValue = await builder.table('products').max<int>('price');

        expect(maxValue, equals(100));
      });

      test('min() returns minimum value', () async {
        connector.mockResults = [
          {'min': 10},
        ];

        final minValue = await builder.table('products').min<int>('price');

        expect(minValue, equals(10));
      });
    });

    group('Insert, Update, Delete', () {
      test('insert() inserts record and returns ID', () async {
        final id = await builder.table('users').insert({'name': 'John Doe', 'email': 'john@example.com'});

        expect(id, equals(1));
        expect(connector.executedQueries.last, contains('INSERT INTO users'));
      });

      test('update() updates records', () async {
        final affected = await builder.table('users').where('id', '=', 1).update({'name': 'Jane Doe'});

        expect(affected, equals(1));
        expect(connector.executedQueries.last, contains('UPDATE users SET'));
        expect(connector.executedQueries.last, contains('WHERE id = ?'));
      });

      test('delete() deletes records', () async {
        final affected = await builder.table('users').where('id', '=', 1).delete();

        expect(affected, equals(1));
        expect(connector.executedQueries.last, contains('DELETE FROM users'));
        expect(connector.executedQueries.last, contains('WHERE id = ?'));
      });
    });

    group('Error Handling', () {
      test('get() throws when table not set', () {
        expect(() => builder.get(), throwsStateError);
      });

      test('insert() throws when table not set', () {
        expect(() => builder.insert({'name': 'Test'}), throwsStateError);
      });

      test('update() throws when table not set', () {
        expect(() => builder.update({'name': 'Test'}), throwsStateError);
      });

      test('delete() throws when table not set', () {
        expect(() => builder.delete(), throwsStateError);
      });
    });

    group('Reset', () {
      test('reset() clears all query state', () async {
        connector.mockResults = [];

        // Build a complex query
        builder
            .table('users')
            .select(['id', 'name'])
            .where('status', '=', 'active')
            .orderBy('name')
            .limit(10)
            .offset(5);

        // Reset
        builder.reset();

        // Try to execute - should fail because table is cleared
        expect(() => builder.get(), throwsStateError);
      });
    });

    group('Complex Queries', () {
      test('builds complete query with all clauses', () async {
        connector.mockResults = [];

        await builder
            .table('orders')
            .select(['customer_id', 'SUM(total) as total_spent'])
            .where('status', '=', 'completed')
            .whereNotNull('paid_at')
            .groupBy('customer_id')
            .having('total_spent', 100, '>')
            .orderBy('total_spent', 'DESC')
            .limit(10)
            .get();

        final sql = connector.executedQueries.last;
        expect(sql, contains('SELECT customer_id, SUM(total) as total_spent'));
        expect(sql, contains('FROM orders'));
        expect(sql, contains('WHERE status = ? AND paid_at IS NOT NULL'));
        expect(sql, contains('GROUP BY customer_id'));
        expect(sql, contains('HAVING total_spent > ?'));
        expect(sql, contains('ORDER BY total_spent DESC'));
        expect(sql, contains('LIMIT 10'));
      });
    });
  });
}
