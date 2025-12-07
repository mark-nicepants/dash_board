import 'package:dash_board/src/widgets/stat.dart';
import 'package:dash_board/src/widgets/widget.dart';
import 'package:jaspr/jaspr.dart';

/// A widget that displays multiple stats in a grid layout.
///
/// Extend this class and override [getStats] to define your stats.
///
/// Example:
/// ```dart
/// class UserStatsWidget extends StatsOverviewWidget {
///   static UserStatsWidget make() => UserStatsWidget();
///
///   @override
///   String? get heading => 'User Statistics';
///
///   @override
///   List<Stat> getStats() => [
///     Stat.make('Total Users', '1,234')
///       .icon(HeroIcons.users)
///       .description('+12% from last month')
///       .descriptionColor('green'),
///     Stat.make('Active Today', '156')
///       .icon(HeroIcons.userGroup)
///       .chart([10, 15, 8, 22, 18, 25, 30]),
///     Stat.make('New Signups', '23')
///       .icon(HeroIcons.userPlus)
///       .description('This week'),
///   ];
/// }
/// ```
abstract class StatsOverviewWidget extends Widget {
  /// The number of columns in the stats grid.
  ///
  /// Override to customize the layout.
  /// Default is 3 for desktop displays.
  int get columns => 3;

  @override
  int get columnSpan => 12; // Full width by default

  /// Returns the list of stats to display.
  ///
  /// Override this method to define your widget's statistics.
  List<Stat> getStats();

  @override
  Component build() {
    final stats = getStats();

    if (stats.isEmpty) {
      return div(classes: 'text-gray-400 text-center py-4', [text('No statistics available')]);
    }

    // Build responsive grid classes
    final gridClasses = _buildGridClasses();

    return div(classes: gridClasses, [for (final stat in stats) stat.build()]);
  }

  String _buildGridClasses() {
    // Responsive grid: 1 col on mobile, 2 on md, configured columns on lg+
    return 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-$columns gap-4';
  }
}
