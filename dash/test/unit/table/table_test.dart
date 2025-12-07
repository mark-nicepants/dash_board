import 'package:dash/dash.dart';
import 'package:test/test.dart';

/// Test model for table tests
class TestModel extends Model {
  final int? _id;
  final String _name;
  final String _email;
  final bool _isActive;

  TestModel({int? id, String name = '', String email = '', bool isActive = true})
    : _id = id,
      _name = name,
      _email = email,
      _isActive = isActive;

  @override
  String get table => 'test_models';

  @override
  String get primaryKey => 'id';

  @override
  dynamic getKey() => _id;

  @override
  void setKey(dynamic key) {}

  @override
  List<String> getFields() => ['id', 'name', 'email', 'is_active'];

  int? get id => _id;
  String get name => _name;
  String get email => _email;
  bool get isActive => _isActive;

  @override
  Map<String, dynamic> toMap() => {'id': _id, 'name': _name, 'email': _email, 'is_active': _isActive};

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}

void main() {
  group('Table', () {
    group('Factory', () {
      test('creates empty table with defaults', () {
        final table = Table<TestModel>();

        expect(table.getColumns(), isEmpty);
        expect(table.isPaginated(), isTrue);
        expect(table.getRecordsPerPage(), equals(10));
        expect(table.isSearchable(), isTrue);
        expect(table.isStriped(), isFalse);
      });
    });

    group('Columns Configuration', () {
      test('columns() sets table columns', () {
        final table = Table<TestModel>().columns([TextColumn.make('name'), TextColumn.make('email')]);

        expect(table.getColumns(), hasLength(2));
        expect(table.getColumns()[0].getName(), equals('name'));
        expect(table.getColumns()[1].getName(), equals('email'));
      });

      test('columns() updates searchable based on column config', () {
        final table = Table<TestModel>().columns([TextColumn.make('name'), TextColumn.make('email')]);

        // No searchable columns, so table searchable should be false
        expect(table.isSearchable(), isFalse);
      });

      test('columns() enables searchable when columns are searchable', () {
        final table = Table<TestModel>().columns([TextColumn.make('name').searchable(), TextColumn.make('email')]);

        expect(table.isSearchable(), isTrue);
      });
    });

    group('Sorting Configuration', () {
      test('defaultSort() sets sort column and direction', () {
        final table = Table<TestModel>().defaultSort('name');

        expect(table.getDefaultSort(), equals('name'));
        expect(table.getDefaultSortDirection(), equals('asc'));
      });

      test('defaultSort() with custom direction', () {
        final table = Table<TestModel>().defaultSort('created_at', 'desc');

        expect(table.getDefaultSort(), equals('created_at'));
        expect(table.getDefaultSortDirection(), equals('desc'));
      });

      test('default sort direction is asc', () {
        final table = Table<TestModel>();
        expect(table.getDefaultSortDirection(), equals('asc'));
      });
    });

    group('Pagination Configuration', () {
      test('paginated() enables pagination', () {
        final table = Table<TestModel>().paginated(true);
        expect(table.isPaginated(), isTrue);
      });

      test('paginated() disables pagination', () {
        final table = Table<TestModel>().paginated(false);
        expect(table.isPaginated(), isFalse);
      });

      test('recordsPerPage() sets page size', () {
        final table = Table<TestModel>().recordsPerPage(25);
        expect(table.getRecordsPerPage(), equals(25));
      });

      test('perPageOptions() sets available page sizes', () {
        final table = Table<TestModel>().perPageOptions([10, 20, 50]);
        expect(table.getPerPageOptions(), equals([10, 20, 50]));
      });

      test('default perPageOptions', () {
        final table = Table<TestModel>();
        expect(table.getPerPageOptions(), equals([5, 10, 25, 50, 100]));
      });
    });

    group('Appearance Configuration', () {
      test('striped() enables striped rows', () {
        final table = Table<TestModel>().striped();
        expect(table.isStriped(), isTrue);
      });

      test('striped(false) disables striped rows', () {
        final table = Table<TestModel>().striped(false);
        expect(table.isStriped(), isFalse);
      });
    });

    group('Empty State Configuration', () {
      test('emptyStateHeading() sets heading', () {
        final table = Table<TestModel>().emptyStateHeading('No records found');
        expect(table.getEmptyStateHeading(), equals('No records found'));
      });

      test('emptyStateDescription() sets description', () {
        final table = Table<TestModel>().emptyStateDescription('Try adjusting your search');
        expect(table.getEmptyStateDescription(), equals('Try adjusting your search'));
      });

      test('emptyStateIcon() sets icon', () {
        final table = Table<TestModel>().emptyStateIcon('inbox');
        expect(table.getEmptyStateIcon(), equals('inbox'));
      });
    });

    group('Search Configuration', () {
      test('searchable() enables search', () {
        final table = Table<TestModel>().searchable(true);
        expect(table.isSearchable(), isTrue);
      });

      test('searchable() disables search', () {
        final table = Table<TestModel>().searchable(false);
        expect(table.isSearchable(), isFalse);
      });

      test('searchPlaceholder() sets placeholder text', () {
        final table = Table<TestModel>().searchPlaceholder('Find users...');
        expect(table.getSearchPlaceholder(), equals('Find users...'));
      });

      test('default search placeholder', () {
        final table = Table<TestModel>();
        expect(table.getSearchPlaceholder(), equals('Search...'));
      });
    });

    group('Row Actions Configuration', () {
      test('actions() sets row actions', () {
        final table = Table<TestModel>().actions([EditAction.make<TestModel>(), DeleteAction.make<TestModel>()]);

        expect(table.getActions(), hasLength(2));
        expect(table.hasActions(), isTrue);
      });

      test('hasActions() returns false when no actions', () {
        final table = Table<TestModel>();
        expect(table.hasActions(), isFalse);
      });
    });

    group('Bulk Actions Configuration', () {
      test('bulkActions() sets bulk actions', () {
        final table = Table<TestModel>().bulkActions([DeleteAction.make<TestModel>()]);

        expect(table.getBulkActions(), hasLength(1));
        expect(table.hasBulkActions(), isTrue);
      });

      test('hasBulkActions() returns false when no bulk actions', () {
        final table = Table<TestModel>();
        expect(table.hasBulkActions(), isFalse);
      });
    });

    group('Header Actions Configuration', () {
      test('headerActions() sets header actions', () {
        final table = Table<TestModel>().headerActions([CreateAction.make<TestModel>()]);

        expect(table.getHeaderActions(), hasLength(1));
        expect(table.hasHeaderActions(), isTrue);
      });

      test('hasHeaderActions() returns false when no header actions', () {
        final table = Table<TestModel>();
        expect(table.hasHeaderActions(), isFalse);
      });
    });

    group('Required Relationships', () {
      test('getRequiredRelationships() returns empty set when no dot notation', () {
        final table = Table<TestModel>().columns([TextColumn.make('name'), TextColumn.make('email')]);

        expect(table.getRequiredRelationships(), isEmpty);
      });

      test('getRequiredRelationships() extracts relationship names from dot notation', () {
        final table = Table<TestModel>().columns([
          TextColumn.make('name'),
          TextColumn.make('author.name'),
          TextColumn.make('category.title'),
        ]);

        final relationships = table.getRequiredRelationships();
        expect(relationships, contains('author'));
        expect(relationships, contains('category'));
        expect(relationships, hasLength(2));
      });

      test('getRequiredRelationships() deduplicates relationships', () {
        final table = Table<TestModel>().columns([TextColumn.make('author.name'), TextColumn.make('author.email')]);

        final relationships = table.getRequiredRelationships();
        expect(relationships, hasLength(1));
        expect(relationships.first, equals('author'));
      });
    });

    group('Fluent API Chaining', () {
      test('methods can be chained together', () {
        final table = Table<TestModel>()
            .columns([
              TextColumn.make('name').searchable().sortable(),
              TextColumn.make('email').searchable(),
              BooleanColumn.make('is_active').sortable(),
            ])
            .defaultSort('name', 'asc')
            .paginated(true)
            .recordsPerPage(25)
            .perPageOptions([10, 25, 50])
            .striped()
            .searchPlaceholder('Search users...')
            .emptyStateHeading('No users found')
            .emptyStateDescription('Create your first user to get started')
            .actions([EditAction.make<TestModel>(), DeleteAction.make<TestModel>()])
            .headerActions([CreateAction.make<TestModel>()]);

        expect(table.getColumns(), hasLength(3));
        expect(table.getDefaultSort(), equals('name'));
        expect(table.getDefaultSortDirection(), equals('asc'));
        expect(table.isPaginated(), isTrue);
        expect(table.getRecordsPerPage(), equals(25));
        expect(table.getPerPageOptions(), equals([10, 25, 50]));
        expect(table.isStriped(), isTrue);
        expect(table.isSearchable(), isTrue);
        expect(table.getSearchPlaceholder(), equals('Search users...'));
        expect(table.getEmptyStateHeading(), equals('No users found'));
        expect(table.getEmptyStateDescription(), equals('Create your first user to get started'));
        expect(table.hasActions(), isTrue);
        expect(table.hasHeaderActions(), isTrue);
      });
    });
  });
}
