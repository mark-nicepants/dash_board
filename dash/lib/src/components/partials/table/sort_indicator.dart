import 'package:jaspr/jaspr.dart';

/// Sort indicator component that shows the current sort direction.
///
/// Example:
/// ```dart
/// SortIndicator(isActive: true, direction: 'asc')
/// SortIndicator(isActive: false) // Shows neutral state
/// ```
class SortIndicator extends StatelessComponent {
  /// Whether this column is currently being sorted.
  final bool isActive;

  /// The current sort direction ('asc' or 'desc').
  final String direction;

  const SortIndicator({this.isActive = false, this.direction = 'asc', super.key});

  @override
  Component build(BuildContext context) {
    final textColor = isActive ? 'text-gray-200' : 'text-gray-600';
    final indicator = isActive ? (direction == 'asc' ? '↑' : '↓') : '↕';

    return span(classes: 'text-xs $textColor cursor-pointer', [text(indicator)]);
  }
}
