# Dash Analytics

Analytics plugin for the [Dash](../../dash) admin panel framework.

## Features

- **Stats Overview Widget**: Displays page views, unique visitors, and bounce rate with sparkline charts
- **Page Views Chart**: Line chart showing weekly page view trends with week-over-week comparison
- **Traffic Sources Chart**: Doughnut chart showing breakdown of traffic sources
- **Sidebar Navigation**: Adds an "Analytics" item to the Reports group
- **Customizable**: Enable/disable widgets and sidebar badge via fluent API

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  dash_analytics: ^0.1.0
```

## Usage

```dart
import 'package:dash/dash.dart';
import 'package:dash_analytics/dash_analytics.dart';

void main() async {
  final panel = Panel()
    ..plugins([
      AnalyticsPlugin.make()
        .enableDashboardWidget(true)
        .showSidebarBadge(true),
    ]);

  await panel.serve();
}
```

## Configuration Options

| Method | Description | Default |
|--------|-------------|---------|
| `enableDashboardWidget(bool)` | Show widgets on dashboard | `false` |
| `showSidebarBadge(bool)` | Show version badge in sidebar | `true` |

## Widgets

### AnalyticsStatsWidget

A stats overview widget showing three key metrics:
- Page Views (with trend indicator)
- Unique Visitors (with trend indicator)
- Bounce Rate (with trend indicator)

Each stat includes a sparkline chart.

### PageViewsChartWidget

A line chart comparing this week's page views to last week. Takes 8 columns (2/3 width).

### TrafficSourcesChartWidget

A doughnut chart showing traffic source breakdown:
- Direct
- Organic
- Referral
- Social
- Email

Takes 4 columns (1/3 width).

## Creating Custom Analytics Widgets

You can create your own analytics widgets by extending the base widget classes:

```dart
import 'package:dash/dash.dart';

class MyCustomChartWidget extends LineChartWidget {
  static MyCustomChartWidget make() => MyCustomChartWidget();

  @override
  String? get heading => 'My Custom Chart';

  @override
  ChartData getData() => const ChartData(
    labels: ['A', 'B', 'C'],
    datasets: [
      ChartDataset(
        label: 'Data',
        data: [10, 20, 30],
        borderColor: 'rgb(6, 182, 212)',
      ),
    ],
  );
}
```

## License

MIT License - see [LICENSE](LICENSE) for details.
