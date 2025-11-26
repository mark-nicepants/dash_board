import 'package:dash/src/model/model.dart';
import 'package:dash/src/table/columns/text_column.dart';
import 'package:jaspr/jaspr.dart';

/// Badge variant mapping from color strings.
BadgeVariant _colorToBadgeVariant(String? color) {
  return switch (color) {
    'primary' => BadgeVariant.primary,
    'success' => BadgeVariant.success,
    'danger' => BadgeVariant.danger,
    'warning' => BadgeVariant.warning,
    'info' => BadgeVariant.info,
    _ => BadgeVariant.default_,
  };
}

/// Badge variant enum for text cells.
enum BadgeVariant { default_, primary, success, danger, warning, info }

/// Cell component for TextColumn that handles text display with optional
/// badges, icons, descriptions, and URLs.
///
/// Example:
/// ```dart
/// TextCell<User>(
///   column: TextColumn.make('name').badge(),
///   record: user,
/// )
/// ```
class TextCell<T extends Model> extends StatelessComponent {
  /// The column configuration.
  final TextColumn column;

  /// The record to render.
  final T record;

  const TextCell({required this.column, required this.record, super.key});

  @override
  Component build(BuildContext context) {
    final state = column.getState(record);
    final components = <Component>[];

    // Icon before text
    if (column.getIcon() != null) {
      components.add(span(classes: 'inline-flex items-center justify-center w-5 h-5 mr-2', [text(column.getIcon()!)]));
    }

    // Main content (badge or text)
    if (column.isBadge()) {
      components.add(_buildBadge(state));
    } else {
      final formatted = column.formatState(state);
      components.add(span(classes: 'text-sm text-gray-200', [text(formatted)]));
    }

    // Icon after text
    if (column.getIconAfter() != null) {
      components.add(
        span(classes: 'inline-flex items-center justify-center w-5 h-5 ml-2', [text(column.getIconAfter()!)]),
      );
    }

    // Description below main text
    final description = column.getDescription(record);
    if (description != null) {
      components.add(span(classes: 'text-xs text-gray-400', [text(description)]));
    }

    // Wrap in link if URL is provided
    final url = column.getUrl(record);
    if (url != null) {
      final attrs = column.shouldOpenUrlInNewTab()
          ? {'target': '_blank', 'rel': 'noopener noreferrer'}
          : <String, String>{};
      return a(href: url, classes: 'text-blue-400 hover:underline', attributes: attrs, components);
    }

    return div(classes: 'flex flex-col gap-1', components);
  }

  Component _buildBadge(dynamic state) {
    final color = column.getColor(record) ?? 'default';
    final variant = _colorToBadgeVariant(color);
    final formatted = column.formatState(state);

    final badgeClasses = switch (variant) {
      BadgeVariant.primary =>
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-900 text-blue-300',
      BadgeVariant.success =>
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-green-900 text-green-300',
      BadgeVariant.danger =>
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-red-900 text-red-300',
      BadgeVariant.warning =>
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-yellow-900 text-yellow-300',
      BadgeVariant.info =>
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-900 text-blue-300',
      BadgeVariant.default_ =>
        'inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-gray-700 text-gray-300',
    };

    return span(classes: badgeClasses, [text(formatted)]);
  }
}
