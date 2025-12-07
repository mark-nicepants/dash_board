import 'package:dash_board/dash_board.dart';
import 'package:jaspr/jaspr.dart';
import 'package:test/test.dart';

/// Test implementation of ChartWidget
class TestChartWidget extends ChartWidget {
  final ChartType _type;
  final ChartData _data;
  final String? _maxHeight;
  final Map<String, dynamic>? _options;
  final int _sort;
  final int _columnSpan;
  final String? _heading;
  final String? _description;

  TestChartWidget({
    ChartType type = ChartType.line,
    ChartData? data,
    String? maxHeight,
    Map<String, dynamic>? options,
    int sort = 0,
    int columnSpan = 6,
    String? heading,
    String? description,
  }) : _type = type,
       _data =
           data ??
           const ChartData(
             labels: ['Jan', 'Feb', 'Mar'],
             datasets: [
               ChartDataset(label: 'Test', data: [10, 20, 30]),
             ],
           ),
       _maxHeight = maxHeight,
       _options = options,
       _sort = sort,
       _columnSpan = columnSpan,
       _heading = heading,
       _description = description;

  @override
  ChartType getType() => _type;

  @override
  ChartData getData() => _data;

  @override
  String? get maxHeight => _maxHeight;

  @override
  Map<String, dynamic>? getOptions() => _options;

  @override
  int get sort => _sort;

  @override
  int get columnSpan => _columnSpan;

  @override
  String? get heading => _heading;

  @override
  String? get description => _description;
}

/// Test implementation of StatsOverviewWidget
class TestStatsOverviewWidget extends StatsOverviewWidget {
  final List<Stat> _stats;
  final int _columns;
  final String? _heading;
  final String? _description;

  TestStatsOverviewWidget({List<Stat>? stats, int columns = 3, String? heading, String? description})
    : _stats = stats ?? [],
      _columns = columns,
      _heading = heading,
      _description = description;

  @override
  List<Stat> getStats() => _stats;

  @override
  int get columns => _columns;

  @override
  String? get heading => _heading;

  @override
  String? get description => _description;
}

void main() {
  group('ChartDataset', () {
    test('creates dataset with required fields', () {
      final dataset = const ChartDataset(label: 'Revenue', data: [100, 200, 300]);

      expect(dataset.label, equals('Revenue'));
      expect(dataset.data, equals([100, 200, 300]));
    });

    test('creates dataset with all optional fields', () {
      final dataset = const ChartDataset(
        label: 'Sales',
        data: [10, 20, 30],
        backgroundColor: 'rgba(0, 0, 0, 0.5)',
        borderColor: 'rgb(0, 0, 0)',
        borderWidth: 2,
        fill: true,
        tension: 0.4,
      );

      expect(dataset.backgroundColor, equals('rgba(0, 0, 0, 0.5)'));
      expect(dataset.borderColor, equals('rgb(0, 0, 0)'));
      expect(dataset.borderWidth, equals(2));
      expect(dataset.fill, isTrue);
      expect(dataset.tension, equals(0.4));
    });

    test('toJson() includes required fields', () {
      final dataset = const ChartDataset(label: 'Revenue', data: [100, 200, 300]);

      final json = dataset.toJson();

      expect(json['label'], equals('Revenue'));
      expect(json['data'], equals([100, 200, 300]));
    });

    test('toJson() includes optional fields when set', () {
      final dataset = const ChartDataset(
        label: 'Sales',
        data: [10, 20, 30],
        backgroundColor: 'red',
        borderColor: 'blue',
        borderWidth: 2,
        fill: true,
        tension: 0.4,
      );

      final json = dataset.toJson();

      expect(json['backgroundColor'], equals('red'));
      expect(json['borderColor'], equals('blue'));
      expect(json['borderWidth'], equals(2));
      expect(json['fill'], isTrue);
      expect(json['tension'], equals(0.4));
    });

    test('toJson() excludes null optional fields', () {
      final dataset = const ChartDataset(label: 'Revenue', data: [100, 200, 300]);

      final json = dataset.toJson();

      expect(json.containsKey('backgroundColor'), isFalse);
      expect(json.containsKey('borderColor'), isFalse);
      expect(json.containsKey('borderWidth'), isFalse);
      expect(json.containsKey('fill'), isFalse);
      expect(json.containsKey('tension'), isFalse);
    });
  });

  group('ChartData', () {
    test('creates data with labels and datasets', () {
      final data = const ChartData(
        labels: ['Jan', 'Feb', 'Mar'],
        datasets: [
          ChartDataset(label: 'Revenue', data: [100, 200, 300]),
        ],
      );

      expect(data.labels, equals(['Jan', 'Feb', 'Mar']));
      expect(data.datasets, hasLength(1));
    });

    test('toJson() returns correct structure', () {
      final data = const ChartData(
        labels: ['Q1', 'Q2', 'Q3', 'Q4'],
        datasets: [
          ChartDataset(label: 'Sales', data: [10, 20, 30, 40]),
          ChartDataset(label: 'Expenses', data: [5, 10, 15, 20]),
        ],
      );

      final json = data.toJson();

      expect(json['labels'], equals(['Q1', 'Q2', 'Q3', 'Q4']));
      expect(json['datasets'], isList);
      expect((json['datasets'] as List), hasLength(2));
    });
  });

  group('ChartType', () {
    test('has all expected values', () {
      expect(ChartType.values, contains(ChartType.line));
      expect(ChartType.values, contains(ChartType.bar));
      expect(ChartType.values, contains(ChartType.pie));
      expect(ChartType.values, contains(ChartType.doughnut));
      expect(ChartType.values, contains(ChartType.polarArea));
      expect(ChartType.values, contains(ChartType.radar));
    });

    test('name property returns correct string', () {
      expect(ChartType.line.name, equals('line'));
      expect(ChartType.bar.name, equals('bar'));
      expect(ChartType.pie.name, equals('pie'));
      expect(ChartType.doughnut.name, equals('doughnut'));
      expect(ChartType.polarArea.name, equals('polarArea'));
      expect(ChartType.radar.name, equals('radar'));
    });
  });

  group('ChartWidget', () {
    group('Configuration', () {
      test('getType() returns chart type', () {
        final widget = TestChartWidget(type: ChartType.bar);
        expect(widget.getType(), equals(ChartType.bar));
      });

      test('getData() returns chart data', () {
        final data = const ChartData(
          labels: ['A', 'B', 'C'],
          datasets: [
            ChartDataset(label: 'Test', data: [1, 2, 3]),
          ],
        );

        final widget = TestChartWidget(data: data);
        expect(widget.getData().labels, equals(['A', 'B', 'C']));
      });

      test('maxHeight can be set', () {
        final widget = TestChartWidget(maxHeight: '400px');
        expect(widget.maxHeight, equals('400px'));
      });

      test('maxHeight defaults to null', () {
        final widget = TestChartWidget();
        expect(widget.maxHeight, isNull);
      });

      test('getOptions() returns custom options', () {
        final options = {'responsive': true, 'maintainAspectRatio': false};
        final widget = TestChartWidget(options: options);
        expect(widget.getOptions(), equals(options));
      });

      test('getOptions() defaults to null', () {
        final widget = TestChartWidget();
        expect(widget.getOptions(), isNull);
      });
    });

    group('Widget Properties', () {
      test('sort can be customized', () {
        final widget = TestChartWidget(sort: 5);
        expect(widget.sort, equals(5));
      });

      test('columnSpan can be customized', () {
        final widget = TestChartWidget(columnSpan: 12);
        expect(widget.columnSpan, equals(12));
      });

      test('heading can be set', () {
        final widget = TestChartWidget(heading: 'Revenue Chart');
        expect(widget.heading, equals('Revenue Chart'));
      });

      test('description can be set', () {
        final widget = TestChartWidget(description: 'Monthly revenue overview');
        expect(widget.description, equals('Monthly revenue overview'));
      });
    });

    group('Assets', () {
      test('requiredAssets includes Chart.js CDN', () {
        final widget = TestChartWidget();
        expect(widget.requiredAssets, isNotEmpty);
        expect(widget.requiredAssets.first, isA<JsAsset>());
      });
    });

    group('Rendering', () {
      test('build() returns a Component', () {
        final widget = TestChartWidget();
        final component = widget.build();
        expect(component, isA<Component>());
      });

      test('build() with different chart types', () {
        for (final type in ChartType.values) {
          final widget = TestChartWidget(type: type);
          final component = widget.build();
          expect(component, isA<Component>());
        }
      });
    });
  });

  group('StatsOverviewWidget', () {
    group('Configuration', () {
      test('columns defaults to 3', () {
        final widget = TestStatsOverviewWidget();
        expect(widget.columns, equals(3));
      });

      test('columns can be customized', () {
        final widget = TestStatsOverviewWidget(columns: 4);
        expect(widget.columns, equals(4));
      });

      test('columnSpan defaults to 12 (full width)', () {
        final widget = TestStatsOverviewWidget();
        expect(widget.columnSpan, equals(12));
      });
    });

    group('Stats', () {
      test('getStats() returns empty list by default', () {
        final widget = TestStatsOverviewWidget();
        expect(widget.getStats(), isEmpty);
      });

      test('getStats() returns provided stats', () {
        final stats = [Stat.make('Users', '1,234'), Stat.make('Revenue', '\$5,678')];

        final widget = TestStatsOverviewWidget(stats: stats);
        expect(widget.getStats(), hasLength(2));
      });
    });

    group('Rendering', () {
      test('build() returns Component with empty stats', () {
        final widget = TestStatsOverviewWidget();
        final component = widget.build();
        expect(component, isA<Component>());
      });

      test('build() returns Component with stats', () {
        final widget = TestStatsOverviewWidget(
          stats: [Stat.make('Users', '1,234'), Stat.make('Revenue', '\$5,678'), Stat.make('Orders', '89')],
        );

        final component = widget.build();
        expect(component, isA<Component>());
      });
    });
  });
}
