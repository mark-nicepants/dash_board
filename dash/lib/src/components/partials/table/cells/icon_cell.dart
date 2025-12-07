import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/icon_column.dart';
import 'package:jaspr/jaspr.dart';

/// Cell component for IconColumn that displays a Heroicon with optional color.
///
/// When the column is configured as clickable, the icon will be wrapped in a
/// button that triggers a wire:click action with the record ID and column name.
///
/// Example:
/// ```dart
/// IconCell<User>(
///   column: IconColumn.make('status').icon(HeroIcons.check).color('success'),
///   record: user,
/// )
///
/// // Clickable column
/// IconCell<User>(
///   column: BooleanColumn.make('is_active').clickable(),
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

    final iconSize = switch (column.getSize()) {
      IconSize.small => 16,
      IconSize.medium => 20,
      IconSize.large => 24,
    };

    final iconComponent = span(classes: 'inline-flex items-center justify-center', [
      Heroicon(icon, size: iconSize, color: colorClass),
    ]);

    // Wrap in clickable button if column is clickable
    if (column.isClickable()) {
      final recordId = record.getKey();
      final columnName = column.getName();
      final action = column.getClickAction()!;

      return button(
        type: ButtonType.button,
        classes: 'p-1 rounded hover:bg-gray-700/50 transition-colors cursor-pointer',
        attributes: {
          // Pass field name via formData for the toggle-boolean handler
          'wire:click': "executeAction('$action', '$recordId', {\"field\": \"$columnName\"})",
          'title': 'Click to toggle',
        },
        [iconComponent],
      );
    }

    return iconComponent;
  }
}
