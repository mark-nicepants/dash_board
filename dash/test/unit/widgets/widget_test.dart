import 'package:dash/dash.dart';
import 'package:jaspr/jaspr.dart';
import 'package:test/test.dart';

/// Test widget implementation
class TestWidget extends Widget {
  final int _sort;
  final int _columnSpan;
  final String? _heading;
  final String? _description;
  final bool _canView;

  TestWidget({int sort = 0, int columnSpan = 6, String? heading, String? description, bool canView = true})
    : _sort = sort,
      _columnSpan = columnSpan,
      _heading = heading,
      _description = description,
      _canView = canView;

  static TestWidget make({
    int sort = 0,
    int columnSpan = 6,
    String? heading,
    String? description,
    bool canView = true,
  }) => TestWidget(sort: sort, columnSpan: columnSpan, heading: heading, description: description, canView: canView);

  @override
  int get sort => _sort;

  @override
  int get columnSpan => _columnSpan;

  @override
  String? get heading => _heading;

  @override
  String? get description => _description;

  @override
  bool canView() => _canView;

  @override
  Component build() {
    return div([text('Test Widget Content')]);
  }
}

void main() {
  group('Widget', () {
    group('Configuration Properties', () {
      test('sort defaults to 0', () {
        final widget = TestWidget.make();
        expect(widget.sort, equals(0));
      });

      test('sort can be customized', () {
        final widget = TestWidget.make(sort: 5);
        expect(widget.sort, equals(5));
      });

      test('columnSpan defaults to 6', () {
        final widget = TestWidget.make();
        expect(widget.columnSpan, equals(6));
      });

      test('columnSpan can be customized', () {
        final widget = TestWidget.make(columnSpan: 12);
        expect(widget.columnSpan, equals(12));
      });

      test('heading defaults to null', () {
        final widget = TestWidget.make();
        expect(widget.heading, isNull);
      });

      test('heading can be set', () {
        final widget = TestWidget.make(heading: 'My Widget');
        expect(widget.heading, equals('My Widget'));
      });

      test('description defaults to null', () {
        final widget = TestWidget.make();
        expect(widget.description, isNull);
      });

      test('description can be set', () {
        final widget = TestWidget.make(description: 'Widget description');
        expect(widget.description, equals('Widget description'));
      });
    });

    group('Visibility', () {
      test('canView() returns true by default', () {
        final widget = TestWidget.make();
        expect(widget.canView(), isTrue);
      });

      test('canView() can return false', () {
        final widget = TestWidget.make(canView: false);
        expect(widget.canView(), isFalse);
      });
    });

    group('Assets', () {
      test('requiredAssets returns empty list by default', () {
        final widget = TestWidget.make();
        expect(widget.requiredAssets, isEmpty);
      });
    });

    group('Rendering', () {
      test('build() returns a Component', () {
        final widget = TestWidget.make();
        final component = widget.build();
        expect(component, isA<Component>());
      });

      test('render() returns a Component', () {
        final widget = TestWidget.make();
        final component = widget.render();
        expect(component, isA<Component>());
      });
    });
  });

  group('Stat', () {
    group('Factory', () {
      test('make() creates stat with label and value', () {
        final stat = Stat.make('Users', '1,234');
        expect(stat.label, equals('Users'));
        expect(stat.value, equals('1,234'));
      });
    });

    group('Configuration', () {
      test('icon() sets icon', () {
        final stat = Stat.make('Users', '1,234').icon(HeroIcons.users);
        expect(stat.getIcon, equals(HeroIcons.users));
      });

      test('description() sets description', () {
        final stat = Stat.make('Users', '1,234').description('+12% from last month');
        expect(stat.getDescription, equals('+12% from last month'));
      });

      test('descriptionIcon() sets description icon', () {
        final stat = Stat.make('Users', '1,234').descriptionIcon(HeroIcons.arrowUp);
        expect(stat.getDescriptionIcon, equals(HeroIcons.arrowUp));
      });

      test('color() sets color', () {
        final stat = Stat.make('Users', '1,234').color('green');
        expect(stat.getColor, equals('green'));
      });

      test('color defaults to cyan', () {
        final stat = Stat.make('Users', '1,234');
        expect(stat.getColor, equals('cyan'));
      });

      test('descriptionColor() sets description color', () {
        final stat = Stat.make('Users', '1,234').descriptionColor('green');
        expect(stat.getDescriptionColor, equals('green'));
      });

      test('chart() sets chart data', () {
        final data = [10.0, 15.0, 8.0, 22.0, 18.0];
        final stat = Stat.make('Users', '1,234').chart(data);
        expect(stat.getChartData, equals(data));
      });

      test('chartColor() sets chart color', () {
        final stat = Stat.make('Users', '1,234').chartColor('amber');
        expect(stat.getChartColor, equals('amber'));
      });

      test('url() sets URL', () {
        final stat = Stat.make('Users', '1,234').url('/users');
        expect(stat.getUrl, equals('/users'));
      });
    });

    group('Fluent API Chaining', () {
      test('all methods can be chained together', () {
        final stat = Stat.make('Total Revenue', '\$12,345')
            .icon(HeroIcons.currencyDollar)
            .description('+15% from last month')
            .descriptionIcon(HeroIcons.arrowUp)
            .descriptionColor('green')
            .color('cyan')
            .chart([100, 150, 120, 180, 200, 220])
            .chartColor('cyan')
            .url('/dashboard/revenue');

        expect(stat.label, equals('Total Revenue'));
        expect(stat.value, equals('\$12,345'));
        expect(stat.getIcon, equals(HeroIcons.currencyDollar));
        expect(stat.getDescription, equals('+15% from last month'));
        expect(stat.getDescriptionIcon, equals(HeroIcons.arrowUp));
        expect(stat.getDescriptionColor, equals('green'));
        expect(stat.getColor, equals('cyan'));
        expect(stat.getChartData, hasLength(6));
        expect(stat.getChartColor, equals('cyan'));
        expect(stat.getUrl, equals('/dashboard/revenue'));
      });
    });

    group('Rendering', () {
      test('build() returns a Component', () {
        final stat = Stat.make('Users', '1,234');
        final component = stat.build();
        expect(component, isA<Component>());
      });
    });
  });
}
