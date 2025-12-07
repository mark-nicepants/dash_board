import 'package:dash_board/dash_board.dart';
import 'package:test/test.dart';

void main() {
  group('Grid', () {
    group('Factory', () {
      test('make() creates grid with default 2 columns', () {
        final grid = Grid.make();
        expect(grid.getDefaultColumns(), equals(2));
      });

      test('make(3) creates grid with 3 columns', () {
        final grid = Grid.make(3);
        expect(grid.getDefaultColumns(), equals(3));
      });
    });

    group('Columns', () {
      test('columns() sets responsive breakpoints', () {
        final grid = Grid.make().columns({'default': 1, 'md': 2, 'lg': 3});

        final columns = grid.getColumns();
        expect(columns['default'], equals(1));
        expect(columns['md'], equals(2));
        expect(columns['lg'], equals(3));
      });

      test('getColumnsAt() returns columns for specific breakpoint', () {
        final grid = Grid.make().columns({'default': 1, 'md': 2, 'lg': 3});

        expect(grid.getColumnsAt('md'), equals(2));
        expect(grid.getColumnsAt('xl'), isNull);
      });

      test('columns() updates lg column count', () {
        final grid = Grid.make().columns({'default': 1, 'lg': 4});

        expect(grid.getDefaultColumns(), equals(4));
      });
    });

    group('Gap', () {
      test('gap() sets gap value', () {
        final grid = Grid.make().gap('6');
        expect(grid.getGap(), equals('6'));
      });

      test('default gap is 4', () {
        final grid = Grid.make();
        expect(grid.getGap(), equals('4'));
      });
    });

    group('Schema', () {
      test('schema() sets child components', () {
        final grid = Grid.make().schema([TextInput.make('name'), TextInput.make('email')]);

        expect(grid.getComponents(), hasLength(2));
      });

      test('getFields() extracts fields from components', () {
        final grid = Grid.make().schema([TextInput.make('name'), TextInput.make('email')]);

        final fields = grid.getFields();
        expect(fields, hasLength(2));
        expect(fields.map((f) => f.getName()), containsAll(['name', 'email']));
      });

      test('getFields() extracts fields from nested sections', () {
        final grid = Grid.make().schema([
          Section.make('Details').schema([TextInput.make('name'), TextInput.make('email')]),
        ]);

        final fields = grid.getFields();
        expect(fields, hasLength(2));
      });

      test('getFields() extracts fields from nested grids', () {
        final grid = Grid.make().schema([
          Grid.make().schema([TextInput.make('name'), TextInput.make('email')]),
        ]);

        final fields = grid.getFields();
        expect(fields, hasLength(2));
      });
    });

    group('Hidden', () {
      test('hidden() hides the grid', () {
        final grid = Grid.make().hidden();
        expect(grid.isHidden(), isTrue);
      });

      test('hidden(false) shows the grid', () {
        final grid = Grid.make().hidden(false);
        expect(grid.isHidden(), isFalse);
      });

      test('default is not hidden', () {
        final grid = Grid.make();
        expect(grid.isHidden(), isFalse);
      });
    });

    group('Column Span', () {
      test('columnSpan() sets span value', () {
        final grid = Grid.make().columnSpan(2);
        expect(grid.getColumnSpan(), equals(2));
      });

      test('default column span is 1', () {
        final grid = Grid.make();
        expect(grid.getColumnSpan(), equals(1));
      });

      test('columnSpanFull() sets full width', () {
        final grid = Grid.make().columnSpanFull();
        expect(grid.isColumnSpanFull(), isTrue);
      });

      test('columnSpanBreakpoint() sets responsive spans', () {
        final grid = Grid.make().columnSpanBreakpoint('md', 2).columnSpanBreakpoint('lg', 3);
        final breakpoints = grid.getColumnSpanBreakpoints();
        expect(breakpoints['md'], equals(2));
        expect(breakpoints['lg'], equals(3));
      });

      test('getColumnSpanClasses() returns correct Tailwind class', () {
        final grid = Grid.make().columnSpan(2);
        expect(grid.getColumnSpanClasses(3), equals('col-span-2'));
      });

      test('getColumnSpanClasses() returns col-span-full for full width', () {
        final grid = Grid.make().columnSpanFull();
        expect(grid.getColumnSpanClasses(3), equals('col-span-full'));
      });

      test('getColumnSpanClasses() returns col-span-full when span >= totalColumns', () {
        final grid = Grid.make().columnSpan(3);
        expect(grid.getColumnSpanClasses(3), equals('col-span-full'));
      });
    });

    group('Grid Classes', () {
      test('getGridClasses() returns correct classes for default columns', () {
        final grid = Grid.make(2);
        final classes = grid.getGridClasses();

        expect(classes, contains('grid'));
        expect(classes, contains('items-start'));
        expect(classes, contains('grid-cols-1'));
        expect(classes, contains('lg:grid-cols-2'));
        expect(classes, contains('gap-4'));
      });

      test('getGridClasses() includes responsive breakpoints', () {
        final grid = Grid.make().columns({'default': 1, 'sm': 2, 'md': 3, 'lg': 4});
        final classes = grid.getGridClasses();

        expect(classes, contains('grid-cols-1'));
        expect(classes, contains('sm:grid-cols-2'));
        expect(classes, contains('md:grid-cols-3'));
        expect(classes, contains('lg:grid-cols-4'));
      });

      test('getGridClasses() includes custom gap', () {
        final grid = Grid.make().gap('8');
        final classes = grid.getGridClasses();

        expect(classes, contains('gap-8'));
      });
    });

    group('Fluent API Chaining', () {
      test('methods can be chained together', () {
        final grid = Grid.make(3).columns({'default': 1, 'md': 2, 'lg': 3}).gap('6').columnSpan(2).schema([
          TextInput.make('name'),
          TextInput.make('email'),
        ]);

        expect(grid.getDefaultColumns(), equals(3));
        expect(grid.getGap(), equals('6'));
        expect(grid.getColumnSpan(), equals(2));
        expect(grid.getComponents(), hasLength(2));
      });
    });
  });

  group('Section Column Span', () {
    test('columnSpan() sets span value', () {
      final section = Section.make('Test').columnSpan(2);
      expect(section.getColumnSpan(), equals(2));
    });

    test('default column span is 1', () {
      final section = Section.make('Test');
      expect(section.getColumnSpan(), equals(1));
    });

    test('columnSpanFull() sets full width', () {
      final section = Section.make('Test').columnSpanFull();
      expect(section.isColumnSpanFull(), isTrue);
    });

    test('columnSpanBreakpoint() sets responsive spans', () {
      final section = Section.make('Test').columnSpanBreakpoint('md', 2).columnSpanBreakpoint('lg', 3);
      final breakpoints = section.getColumnSpanBreakpoints();
      expect(breakpoints['md'], equals(2));
      expect(breakpoints['lg'], equals(3));
    });

    test('getColumnSpanClasses() returns correct Tailwind class', () {
      final section = Section.make('Test').columnSpan(2);
      expect(section.getColumnSpanClasses(3), equals('col-span-2'));
    });

    test('getColumnSpanClasses() returns col-span-full for full width', () {
      final section = Section.make('Test').columnSpanFull();
      expect(section.getColumnSpanClasses(3), equals('col-span-full'));
    });

    test('getColumnSpanClasses() returns col-span-full when span >= totalColumns', () {
      final section = Section.make('Test').columnSpan(3);
      expect(section.getColumnSpanClasses(3), equals('col-span-full'));
    });
  });

  group('Grid in FormSchema', () {
    test('getFields() extracts fields from grid components', () {
      final schema = FormSchema().fields([
        Grid.make(2).schema([TextInput.make('first_name'), TextInput.make('last_name')]),
        TextInput.make('email'),
      ]);

      final fields = schema.getFields();
      expect(fields, hasLength(3));
      expect(fields.map((f) => f.getName()), containsAll(['first_name', 'last_name', 'email']));
    });

    test('getFields() extracts fields from nested grid in section', () {
      final schema = FormSchema().fields([
        Grid.make(2).schema([
          Section.make('Personal Info').schema([TextInput.make('name')]),
          Section.make('Contact Info').schema([TextInput.make('email')]),
        ]),
      ]);

      final fields = schema.getFields();
      expect(fields, hasLength(2));
    });
  });

  group('Grid with different sized sections', () {
    test('sections can have different column spans in a grid', () {
      final grid = Grid.make(
        3,
      ).schema([Section.make('Main Content').columnSpan(2), Section.make('Sidebar').columnSpan(1)]);

      final components = grid.getComponents();
      expect(components, hasLength(2));

      final mainSection = components[0] as Section;
      final sidebarSection = components[1] as Section;

      expect(mainSection.getColumnSpan(), equals(2));
      expect(mainSection.getColumnSpanClasses(3), equals('col-span-2'));

      expect(sidebarSection.getColumnSpan(), equals(1));
      expect(sidebarSection.getColumnSpanClasses(3), equals('col-span-1'));
    });
  });
}
