import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Button variants matching ActionColor options
enum ButtonVariant { primary, secondary, danger, warning, success, info, ghost }

/// Button sizes matching ActionSize options
enum ButtonSize { xs, sm, md, lg }

/// Icon position relative to label
enum IconPosition { before, after }

/// Reusable button component with consistent Tailwind styling.
///
/// This is the single source of truth for all button UI in Dash.
/// Used by Actions, Forms, and anywhere else buttons are needed.
class Button extends StatelessComponent {
  /// The button label text. Can be hidden with [hideLabel].
  final String label;

  /// Visual style variant.
  final ButtonVariant variant;

  /// Button size (affects padding and text size).
  final ButtonSize size;

  /// HTML button type (submit, button, reset).
  final ButtonType? type;

  /// If provided, renders as an `<a>` tag instead of `<button>`.
  final String? href;

  /// Additional HTML attributes.
  final Map<String, String>? attributes;

  /// Optional icon (typically a Heroicon).
  final HeroIcons? icon;

  /// Icon position relative to label.
  final IconPosition iconPosition;

  /// Whether the button is disabled.
  final bool disabled;

  /// Whether to stretch button to full width.
  final bool fullWidth;

  /// Whether to hide the label (icon-only button).
  final bool hideLabel;

  /// Whether to open href in new tab.
  final bool openInNewTab;

  /// Use subtle styling (colored text on gray background).
  /// Good for table row actions where prominent buttons would be too loud.
  final bool subtle;

  const Button({
    required this.label,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.type,
    this.href,
    this.attributes,
    this.icon,
    this.iconPosition = IconPosition.before,
    this.disabled = false,
    this.fullWidth = false,
    this.hideLabel = false,
    this.openInNewTab = false,
    this.subtle = false,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final classes = _buildClasses();
    final content = _buildContent();

    if (href != null) {
      final linkClasses = disabled ? '$classes opacity-50 cursor-not-allowed' : classes;
      if (disabled) {
        // Disabled link renders as span
        return span(classes: linkClasses, content);
      }
      return a(
        href: href!,
        classes: classes,
        attributes: {if (openInNewTab) 'target': '_blank', ...?attributes},
        content,
      );
    }

    return button(
      type: type ?? ButtonType.button,
      classes: classes,
      attributes: {if (disabled) 'disabled': '', ...?attributes},
      content,
    );
  }

  List<Component> _buildContent() {
    final iconSize = _getIconSize();
    final components = <Component>[];

    if (icon != null && iconPosition == IconPosition.before) {
      components.add(Heroicon(icon!, size: iconSize));
    }

    if (!hideLabel) {
      components.add(text(label));
    }

    if (icon != null && iconPosition == IconPosition.after) {
      components.add(Heroicon(icon!, size: iconSize));
    }

    return components;
  }

  int _getIconSize() => switch (size) {
    ButtonSize.xs => 14,
    ButtonSize.sm => 16,
    ButtonSize.md => 18,
    ButtonSize.lg => 20,
  };

  String _buildClasses() {
    final baseClasses = subtle
        ? 'inline-flex items-center gap-1.5 font-medium rounded-md transition-colors'
        : 'inline-flex items-center justify-center gap-2 font-semibold rounded-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed';

    final variantClasses = subtle ? _buildSubtleVariantClasses() : _buildFilledVariantClasses();

    final sizeClasses = switch (size) {
      ButtonSize.xs => 'text-xs px-2 py-1',
      ButtonSize.sm => subtle ? 'text-xs px-3 py-1.5' : 'text-sm px-3 py-1.5',
      ButtonSize.md => 'text-sm px-4 py-2',
      ButtonSize.lg => 'text-base px-6 py-3',
    };

    final widthClass = fullWidth ? 'w-full' : '';
    return '$baseClasses $variantClasses $sizeClasses $widthClass'.trim();
  }

  /// Filled/prominent button styles (default)
  String _buildFilledVariantClasses() {
    final colors = panelColors;
    return switch (variant) {
      ButtonVariant.primary =>
        'bg-${colors.primary}-500 text-white hover:bg-${colors.primary}-600 active:bg-${colors.primary}-700 focus:ring-2 focus:ring-${colors.primary}-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.secondary =>
        'bg-gray-700 text-gray-300 hover:bg-gray-600 hover:text-gray-100 active:bg-gray-800 border border-gray-600 focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.danger =>
        'bg-${colors.danger}-600 text-white hover:bg-${colors.danger}-700 active:bg-${colors.danger}-800 focus:ring-2 focus:ring-${colors.danger}-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.warning =>
        'bg-${colors.warning}-500 text-white hover:bg-${colors.warning}-600 active:bg-${colors.warning}-700 focus:ring-2 focus:ring-${colors.warning}-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.success =>
        'bg-${colors.success}-600 text-white hover:bg-${colors.success}-700 active:bg-${colors.success}-800 focus:ring-2 focus:ring-${colors.success}-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.info =>
        'bg-${colors.info}-600 text-white hover:bg-${colors.info}-700 active:bg-${colors.info}-800 focus:ring-2 focus:ring-${colors.info}-500 focus:ring-offset-2 focus:ring-offset-gray-900',
      ButtonVariant.ghost => 'text-gray-300 hover:bg-gray-700 hover:text-white active:bg-gray-800',
    };
  }

  /// Subtle button styles (colored text on gray background)
  String _buildSubtleVariantClasses() {
    final colors = panelColors;
    return switch (variant) {
      ButtonVariant.primary =>
        'text-${colors.primary}-400 hover:text-${colors.primary}-300 bg-gray-700 hover:bg-gray-600',
      ButtonVariant.secondary => 'text-gray-300 hover:text-white bg-gray-700 hover:bg-gray-600',
      ButtonVariant.danger => 'text-${colors.danger}-400 hover:text-white bg-gray-700 hover:bg-${colors.danger}-600',
      ButtonVariant.warning =>
        'text-${colors.warning}-400 hover:text-${colors.warning}-300 bg-gray-700 hover:bg-gray-600',
      ButtonVariant.success =>
        'text-${colors.success}-400 hover:text-${colors.success}-300 bg-gray-700 hover:bg-gray-600',
      ButtonVariant.info => 'text-${colors.info}-400 hover:text-${colors.info}-300 bg-gray-700 hover:bg-gray-600',
      ButtonVariant.ghost => 'text-gray-300 hover:bg-gray-700 hover:text-white',
    };
  }
}
