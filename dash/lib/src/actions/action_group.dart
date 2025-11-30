import 'package:dash/src/actions/action.dart';
import 'package:dash/src/actions/action_color.dart';
import 'package:dash/src/actions/action_size.dart';
import 'package:dash/src/components/partials/button.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/model/model.dart';
import 'package:jaspr/jaspr.dart';

/// The display style for an action group trigger.
enum ActionGroupTrigger {
  /// Icon button with ellipsis icon (default).
  iconButton,

  /// Full button with label.
  button,

  /// Link style trigger.
  link,
}

/// Groups multiple actions into a dropdown menu.
///
/// Useful when you have many row actions and want to keep the UI clean.
/// Based on FilamentPHP's ActionGroup pattern.
///
/// Example:
/// ```dart
/// ActionGroup.make([
///   EditAction.make(),
///   ViewAction.make(),
///   DeleteAction.make(),
/// ])
///   .label('Actions')
///   .icon(HeroIcons.ellipsisVertical)
/// ```
class ActionGroup<T extends Model> {
  /// The actions contained in this group.
  final List<Action<T>> _actions;

  /// The trigger style for the dropdown.
  ActionGroupTrigger _trigger = ActionGroupTrigger.iconButton;

  /// The icon to show in the trigger.
  HeroIcons _icon = HeroIcons.ellipsisVertical;

  /// The label for the trigger button.
  String? _label;

  /// The color of the trigger button.
  ActionColor _color = ActionColor.secondary;

  /// The size of the trigger button.
  ActionSize _size = ActionSize.sm;

  /// Optional tooltip for the trigger.
  String? _tooltip;

  /// Dropdown placement.
  String _dropdownPlacement = 'bottom-end';

  /// Whether the dropdown should have a divider between action sections.
  bool _hasDividers = false;

  /// Creates an action group.
  ActionGroup._(this._actions);

  /// Factory method to create an action group.
  static ActionGroup<T> make<T extends Model>(List<Action<T>> actions) {
    return ActionGroup._(actions);
  }

  /// Set the trigger style to icon button.
  ActionGroup<T> iconButton() {
    _trigger = ActionGroupTrigger.iconButton;
    return this;
  }

  /// Set the trigger style to button.
  ActionGroup<T> button() {
    _trigger = ActionGroupTrigger.button;
    return this;
  }

  /// Set the trigger style to link.
  ActionGroup<T> link() {
    _trigger = ActionGroupTrigger.link;
    return this;
  }

  /// Set the icon for the trigger.
  ActionGroup<T> icon(HeroIcons icon) {
    _icon = icon;
    return this;
  }

  /// Set the label for the trigger.
  ActionGroup<T> label(String label) {
    _label = label;
    return this;
  }

  /// Set the color for the trigger.
  ActionGroup<T> color(ActionColor color) {
    _color = color;
    return this;
  }

  /// Set the size for the trigger.
  ActionGroup<T> size(ActionSize size) {
    _size = size;
    return this;
  }

  /// Set the tooltip for the trigger.
  ActionGroup<T> tooltip(String tooltip) {
    _tooltip = tooltip;
    return this;
  }

  /// Set the dropdown placement.
  ActionGroup<T> dropdownPlacement(String placement) {
    _dropdownPlacement = placement;
    return this;
  }

  /// Add dividers between actions.
  ActionGroup<T> dividers([bool enabled = true]) {
    _hasDividers = enabled;
    return this;
  }

  /// Get the visible actions for a given record.
  List<Action<T>> getVisibleActions(T record) => _actions.where((a) => a.isVisible(record)).toList();

  /// Render the action group for a specific record.
  Component render(T record, {required String basePath}) {
    final visibleActions = getVisibleActions(record);
    if (visibleActions.isEmpty) {
      return span([]);
    }

    return _ActionGroupComponent<T>(
      actions: visibleActions,
      record: record,
      basePath: basePath,
      trigger: _trigger,
      icon: _icon,
      label: _label,
      color: _color,
      size: _size,
      tooltip: _tooltip,
      dropdownPlacement: _dropdownPlacement,
      hasDividers: _hasDividers,
    );
  }
}

/// Internal component for rendering action group.
class _ActionGroupComponent<T extends Model> extends StatelessComponent {
  final List<Action<T>> actions;
  final T record;
  final String basePath;
  final ActionGroupTrigger trigger;
  final HeroIcons icon;
  final String? label;
  final ActionColor color;
  final ActionSize size;
  final String? tooltip;
  final String dropdownPlacement;
  final bool hasDividers;

  const _ActionGroupComponent({
    required this.actions,
    required this.record,
    required this.basePath,
    required this.trigger,
    required this.icon,
    this.label,
    required this.color,
    required this.size,
    this.tooltip,
    required this.dropdownPlacement,
    required this.hasDividers,
  });

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'relative inline-block text-left',
      attributes: {
        'x-data': '{ open: false }',
        '@click.away': 'open = false',
        '@keydown.escape.window': 'open = false',
      },
      [
        // Trigger button
        _buildTrigger(),
        // Dropdown panel
        _buildDropdown(),
      ],
    );
  }

  Component _buildTrigger() {
    final attributes = <String, String>{
      '@click': 'open = !open',
      'type': 'button',
      'aria-haspopup': 'true',
      ':aria-expanded': 'open',
    };

    if (tooltip != null) {
      attributes['title'] = tooltip!;
    }

    return switch (trigger) {
      ActionGroupTrigger.iconButton => _buildIconButtonTrigger(attributes),
      ActionGroupTrigger.button => _buildButtonTrigger(attributes),
      ActionGroupTrigger.link => _buildLinkTrigger(attributes),
    };
  }

  Component _buildIconButtonTrigger(Map<String, String> attributes) {
    final colorClasses = switch (color) {
      ActionColor.primary => 'text-primary-500 hover:text-primary-400 hover:bg-primary-500/10',
      ActionColor.secondary => 'text-gray-400 hover:text-gray-300 hover:bg-gray-700',
      ActionColor.success => 'text-green-500 hover:text-green-400 hover:bg-green-500/10',
      ActionColor.warning => 'text-yellow-500 hover:text-yellow-400 hover:bg-yellow-500/10',
      ActionColor.danger => 'text-red-500 hover:text-red-400 hover:bg-red-500/10',
      ActionColor.info => 'text-blue-500 hover:text-blue-400 hover:bg-blue-500/10',
    };

    final sizeClasses = switch (size) {
      ActionSize.xs => 'p-1',
      ActionSize.sm => 'p-1.5',
      ActionSize.md => 'p-2',
      ActionSize.lg => 'p-2.5',
    };

    final iconSize = switch (size) {
      ActionSize.xs => 16,
      ActionSize.sm => 18,
      ActionSize.md => 20,
      ActionSize.lg => 24,
    };

    return button(
      classes: 'inline-flex items-center justify-center rounded-md transition-colors $colorClasses $sizeClasses',
      attributes: attributes,
      [Heroicon(icon, size: iconSize)],
    );
  }

  Component _buildButtonTrigger(Map<String, String> attributes) {
    final buttonSize = switch (size) {
      ActionSize.xs => ButtonSize.xs,
      ActionSize.sm => ButtonSize.sm,
      ActionSize.md => ButtonSize.md,
      ActionSize.lg => ButtonSize.lg,
    };

    final buttonVariant = switch (color) {
      ActionColor.primary => ButtonVariant.primary,
      ActionColor.secondary => ButtonVariant.secondary,
      ActionColor.success => ButtonVariant.success,
      ActionColor.warning => ButtonVariant.warning,
      ActionColor.danger => ButtonVariant.danger,
      ActionColor.info => ButtonVariant.primary,
    };

    return Button(
      label: label ?? 'Actions',
      variant: buttonVariant,
      size: buttonSize,
      icon: icon,
      iconPosition: IconPosition.after,
      attributes: attributes,
    );
  }

  Component _buildLinkTrigger(Map<String, String> attributes) {
    final colorClasses = switch (color) {
      ActionColor.primary => 'text-primary-500 hover:text-primary-400',
      ActionColor.secondary => 'text-gray-400 hover:text-gray-300',
      ActionColor.success => 'text-green-500 hover:text-green-400',
      ActionColor.warning => 'text-yellow-500 hover:text-yellow-400',
      ActionColor.danger => 'text-red-500 hover:text-red-400',
      ActionColor.info => 'text-blue-500 hover:text-blue-400',
    };

    final sizeClasses = switch (size) {
      ActionSize.xs => 'text-xs',
      ActionSize.sm => 'text-sm',
      ActionSize.md => 'text-sm',
      ActionSize.lg => 'text-base',
    };

    return button(
      classes: 'inline-flex items-center gap-1 transition-colors $colorClasses $sizeClasses',
      attributes: attributes,
      [
        if (label != null) span([text(label!)]),
        Heroicon(icon, size: 16),
      ],
    );
  }

  Component _buildDropdown() {
    final placementClasses = switch (dropdownPlacement) {
      'bottom-start' => 'left-0 mt-2 origin-top-left',
      'bottom-end' => 'right-0 mt-2 origin-top-right',
      'top-start' => 'left-0 bottom-full mb-2 origin-bottom-left',
      'top-end' => 'right-0 bottom-full mb-2 origin-bottom-right',
      _ => 'right-0 mt-2 origin-top-right',
    };

    return div(
      classes: 'absolute z-50 $placementClasses',
      attributes: {
        'x-show': 'open',
        'x-transition:enter': 'transition ease-out duration-100',
        'x-transition:enter-start': 'transform opacity-0 scale-95',
        'x-transition:enter-end': 'transform opacity-100 scale-100',
        'x-transition:leave': 'transition ease-in duration-75',
        'x-transition:leave-start': 'transform opacity-100 scale-100',
        'x-transition:leave-end': 'transform opacity-0 scale-95',
        'x-cloak': 'true',
      },
      [
        div(
          classes:
              'min-w-48 rounded-md bg-gray-800 border border-gray-700 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none divide-y divide-gray-700',
          attributes: {'role': 'menu', 'aria-orientation': 'vertical'},
          [
            if (hasDividers)
              ..._buildDividedActions()
            else
              div(classes: 'py-1', [
                for (final action in actions) _ActionMenuItem(action: action, record: record, basePath: basePath),
              ]),
          ],
        ),
      ],
    );
  }

  List<Component> _buildDividedActions() {
    // Group actions, each action gets its own group for dividers
    return [
      for (final action in actions)
        div(classes: 'py-1', [_ActionMenuItem(action: action, record: record, basePath: basePath)]),
    ];
  }
}

/// A menu item within an action group dropdown.
class _ActionMenuItem<T extends Model> extends StatelessComponent {
  final Action<T> action;
  final T record;
  final String basePath;

  const _ActionMenuItem({required this.action, required this.record, required this.basePath});

  @override
  Component build(BuildContext context) {
    final colorClasses = switch (action.getColor()) {
      ActionColor.primary => 'text-primary-400 hover:bg-primary-500/10',
      ActionColor.secondary => 'text-gray-300 hover:bg-gray-700',
      ActionColor.success => 'text-green-400 hover:bg-green-500/10',
      ActionColor.warning => 'text-yellow-400 hover:bg-yellow-500/10',
      ActionColor.danger => 'text-red-400 hover:bg-red-500/10',
      ActionColor.info => 'text-blue-400 hover:bg-blue-500/10',
    };

    final icon = action.getIcon();
    final url = action.getUrl(record, basePath);
    final isDisabled = action.isDisabled(record);

    // Build base attributes
    final attributes = <String, String>{'role': 'menuitem', '@click': 'open = false'};

    // Add extra attributes from action
    final extraAttrs = action.getExtraAttributes();
    if (extraAttrs != null) {
      attributes.addAll(extraAttrs);
    }

    // Disabled state
    if (isDisabled) {
      return div(classes: 'flex items-center gap-2 px-4 py-2 text-sm text-gray-500 cursor-not-allowed', [
        if (icon != null) Heroicon(icon, size: 18),
        span([text(action.getLabel())]),
      ]);
    }

    // URL action - render as link
    if (url != null) {
      return a(
        href: url,
        classes: 'flex items-center gap-2 px-4 py-2 text-sm transition-colors $colorClasses',
        attributes: attributes,
        [
          if (icon != null) Heroicon(icon, size: 18),
          span([text(action.getLabel())]),
        ],
      );
    }

    // POST action or custom action - render as button
    return button(
      classes: 'flex w-full items-center gap-2 px-4 py-2 text-sm text-left transition-colors $colorClasses',
      attributes: {...attributes, 'type': 'button'},
      [
        if (icon != null) Heroicon(icon, size: 18),
        span([text(action.getLabel())]),
      ],
    );
  }
}
