import 'package:dash/src/model/model.dart';
import 'package:dash/src/table/columns/icon_column.dart';
import 'package:jaspr/jaspr.dart';

/// Cell component for IconColumn that displays an icon with optional color.
///
/// Example:
/// ```dart
/// IconCell<User>(
///   column: IconColumn.make('status').icon('check').color('success'),
///   record: user,
/// )
/// ```
class IconCell<T extends Model> extends StatelessComponent {
  /// The column configuration.
  final IconColumn column;

  /// The record to render.
  final T record;

  const IconCell({required this.column, required this.record, super.key});

  @override
  Component build(BuildContext context) {
    final icon = column.getIcon(record);
    final color = column.getColor(record) ?? 'default';

    if (icon == null) {
      return span([]);
    }

    final colorClass = switch (color) {
      'success' => 'text-green-500',
      'danger' => 'text-red-500',
      'warning' => 'text-yellow-500',
      'info' => 'text-blue-500',
      _ => 'text-gray-500',
    };

    return span(classes: 'inline-flex items-center justify-center w-5 h-5 $colorClass', [
      text(_getIconCharacter(icon)),
    ]);
  }

  /// Maps icon names to unicode characters.
  /// In a real implementation, you might use an icon library or SVGs.
  String _getIconCharacter(String iconName) {
    final iconMap = {
      'check': '✓',
      'check-circle': '✓',
      'x': '✗',
      'x-circle': '✗',
      'shield-check': '🛡️',
      'shield-exclamation': '⚠️',
      'document-text': '📄',
      'user': '👤',
      'user-group': '👥',
      'star': '★',
      'star-outline': '☆',
      'heart': '♥',
      'heart-outline': '♡',
      'flag': '⚑',
      'warning': '⚠',
      'info': 'ℹ',
      'lock': '🔒',
      'unlock': '🔓',
    };
    return iconMap[iconName] ?? '●';
  }
}
