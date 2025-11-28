import 'package:dash/src/actions/action_color.dart';
import 'package:dash/src/actions/action_size.dart';
import 'package:dash/src/components/partials/button.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/model/model.dart';
import 'package:jaspr/jaspr.dart';

/// Base class for all Dash actions.
///
/// An [Action] represents an interactive button that can perform operations
/// like navigating to URLs, executing callbacks, or showing confirmations.
///
/// Actions use a fluent builder API for configuration:
///
/// ```dart
/// Action.make('edit')
///   .label('Edit User')
///   .icon(HeroIcons.pencilSquare)
///   .color(ActionColor.primary)
///   .url((record) => '/users/${record.id}/edit')
/// ```
///
/// Actions can also execute server-side code:
///
/// ```dart
/// Action.make('delete')
///   .label('Delete')
///   .color(ActionColor.danger)
///   .requiresConfirmation()
///   .action((record) async => await record.delete())
/// ```
class Action<T extends Model> {
  final String _name;

  // Label
  String? _label;
  bool _isLabelHidden = false;

  // Icon
  HeroIcons? _icon;
  IconPosition _iconPosition = IconPosition.before;

  // Color & Size
  ActionColor _color = ActionColor.primary;
  ActionSize _size = ActionSize.sm;

  // Visibility & State
  bool Function(T record)? _hiddenWhen;
  bool Function(T record)? _visibleWhen;
  bool Function(T record)? _disabledWhen;

  // URL Navigation
  String Function(T record, String basePath)? _url;
  bool _openUrlInNewTab = false;

  // Confirmation
  bool _requiresConfirmation = false;
  String? _confirmationHeading;
  String? _confirmationDescription;
  String? _confirmationButtonLabel;
  String? _cancelButtonLabel;

  // Action Callback (for POST actions)
  String Function(T record, String basePath)? _actionUrl;
  String _actionMethod = 'POST';

  // Tooltip
  String? _tooltip;

  // Extra attributes
  Map<String, String>? _extraAttributes;

  /// Creates a new action with the given [name].
  ///
  /// The name is used as a unique identifier and defaults to the label
  /// if not explicitly set.
  Action(this._name);

  /// Factory method to create a new action.
  ///
  /// This is the preferred way to create actions:
  /// ```dart
  /// Action.make('edit').label('Edit').icon(HeroIcons.pencil)
  /// ```
  static Action<T> make<T extends Model>(String name) => Action<T>(name);

  // ============================================================
  // Label Configuration
  // ============================================================

  /// Sets the display label for the action.
  ///
  /// If not set, the label is derived from the action name.
  Action<T> label(String label) {
    _label = label;
    return this;
  }

  /// Hides the label, showing only the icon.
  Action<T> hiddenLabel([bool condition = true]) {
    _isLabelHidden = condition;
    return this;
  }

  // ============================================================
  // Icon Configuration
  // ============================================================

  /// Sets the icon for the action.
  Action<T> icon(HeroIcons icon) {
    _icon = icon;
    return this;
  }

  /// Sets the icon position relative to the label.
  Action<T> iconPosition(IconPosition position) {
    _iconPosition = position;
    return this;
  }

  // ============================================================
  // Color & Size Configuration
  // ============================================================

  /// Sets the color variant for the action.
  Action<T> color(ActionColor color) {
    _color = color;
    return this;
  }

  /// Sets the size of the action button.
  Action<T> size(ActionSize size) {
    _size = size;
    return this;
  }

  // ============================================================
  // Visibility & State
  // ============================================================

  /// Conditionally hides the action based on the record.
  ///
  /// ```dart
  /// Action.make('restore')
  ///   .hidden((record) => record.deletedAt == null)
  /// ```
  Action<T> hidden(bool Function(T record) condition) {
    _hiddenWhen = condition;
    return this;
  }

  /// Conditionally shows the action based on the record.
  ///
  /// ```dart
  /// Action.make('restore')
  ///   .visible((record) => record.deletedAt != null)
  /// ```
  Action<T> visible(bool Function(T record) condition) {
    _visibleWhen = condition;
    return this;
  }

  /// Conditionally disables the action based on the record.
  ///
  /// ```dart
  /// Action.make('edit')
  ///   .disabled((record) => record.isLocked)
  /// ```
  Action<T> disabled(bool Function(T record) condition) {
    _disabledWhen = condition;
    return this;
  }

  // ============================================================
  // URL Navigation
  // ============================================================

  /// Sets a URL to navigate to when the action is triggered.
  ///
  /// ```dart
  /// Action.make('edit')
  ///   .url((record, basePath) => '$basePath/${record.id}/edit')
  /// ```
  Action<T> url(String Function(T record, String basePath) url) {
    _url = url;
    return this;
  }

  /// Opens the URL in a new tab.
  Action<T> openUrlInNewTab([bool condition = true]) {
    _openUrlInNewTab = condition;
    return this;
  }

  // ============================================================
  // Confirmation
  // ============================================================

  /// Requires confirmation before executing the action.
  ///
  /// Shows a browser confirmation dialog by default.
  Action<T> requiresConfirmation([bool condition = true]) {
    _requiresConfirmation = condition;
    return this;
  }

  /// Sets the heading for the confirmation dialog.
  Action<T> confirmationHeading(String heading) {
    _confirmationHeading = heading;
    return this;
  }

  /// Sets the description for the confirmation dialog.
  Action<T> confirmationDescription(String description) {
    _confirmationDescription = description;
    return this;
  }

  /// Sets the label for the confirmation button.
  Action<T> confirmationButtonLabel(String label) {
    _confirmationButtonLabel = label;
    return this;
  }

  /// Sets the label for the cancel button.
  Action<T> cancelButtonLabel(String label) {
    _cancelButtonLabel = label;
    return this;
  }

  // ============================================================
  // Action Callback (POST actions)
  // ============================================================

  /// Sets the URL to POST to when the action is triggered.
  ///
  /// ```dart
  /// Action.make('delete')
  ///   .actionUrl((record, basePath) => '$basePath/${record.id}/delete')
  ///   .requiresConfirmation()
  /// ```
  Action<T> actionUrl(String Function(T record, String basePath) url) {
    _actionUrl = url;
    return this;
  }

  /// Sets the HTTP method for the action (default: POST).
  Action<T> method(String method) {
    _actionMethod = method.toUpperCase();
    return this;
  }

  // ============================================================
  // Tooltip & Extra Attributes
  // ============================================================

  /// Sets a tooltip to show on hover.
  Action<T> tooltip(String tooltip) {
    _tooltip = tooltip;
    return this;
  }

  /// Sets extra HTML attributes for the action element.
  Action<T> extraAttributes(Map<String, String> attributes) {
    _extraAttributes = attributes;
    return this;
  }

  // ============================================================
  // Getters
  // ============================================================

  /// Gets the action name.
  String getName() => _name;

  /// Gets the display label, derived from name if not set.
  String getLabel() {
    if (_label != null) return _label!;
    // Convert name to title case: 'editUser' -> 'Edit User'
    return _name
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
        .replaceAll(RegExp(r'[-_]'), ' ')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : '')
        .join(' ');
  }

  /// Gets whether the label is hidden.
  bool isLabelHidden() => _isLabelHidden;

  /// Gets the icon.
  HeroIcons? getIcon() => _icon;

  /// Gets the icon position.
  IconPosition getIconPosition() => _iconPosition;

  /// Gets the color.
  ActionColor getColor() => _color;

  /// Gets the size.
  ActionSize getSize() => _size;

  /// Checks if the action is hidden for the given record.
  bool isHidden(T record) {
    if (_hiddenWhen != null && _hiddenWhen!(record)) return true;
    if (_visibleWhen != null && !_visibleWhen!(record)) return true;
    return false;
  }

  /// Checks if the action is visible for the given record.
  bool isVisible(T record) => !isHidden(record);

  /// Checks if the action is disabled for the given record.
  bool isDisabled(T record) => _disabledWhen?.call(record) ?? false;

  /// Gets the URL for the given record, if set.
  String? getUrl(T record, String basePath) => _url?.call(record, basePath);

  /// Gets whether to open URL in new tab.
  bool shouldOpenUrlInNewTab() => _openUrlInNewTab;

  /// Gets whether confirmation is required.
  bool isConfirmationRequired() => _requiresConfirmation;

  /// Gets the confirmation heading.
  String getConfirmationHeading() => _confirmationHeading ?? 'Are you sure?';

  /// Gets the confirmation description.
  String? getConfirmationDescription() => _confirmationDescription;

  /// Gets the confirmation button label.
  String getConfirmationButtonLabel() => _confirmationButtonLabel ?? 'Confirm';

  /// Gets the cancel button label.
  String getCancelButtonLabel() => _cancelButtonLabel ?? 'Cancel';

  /// Gets the action URL for POST requests.
  String? getActionUrl(T record, String basePath) => _actionUrl?.call(record, basePath);

  /// Gets the HTTP method.
  String getMethod() => _actionMethod;

  /// Gets the tooltip.
  String? getTooltip() => _tooltip;

  /// Gets extra attributes.
  Map<String, String>? getExtraAttributes() => _extraAttributes;

  /// Checks if this is a URL action (navigation).
  bool isUrlAction() => _url != null;

  /// Checks if this is a POST action.
  bool isPostAction() => _actionUrl != null;

  // ============================================================
  // Type Conversions
  // ============================================================

  /// Converts ActionColor to ButtonVariant.
  ButtonVariant get buttonVariant => switch (_color) {
    ActionColor.primary => ButtonVariant.primary,
    ActionColor.secondary => ButtonVariant.secondary,
    ActionColor.danger => ButtonVariant.danger,
    ActionColor.warning => ButtonVariant.warning,
    ActionColor.success => ButtonVariant.success,
    ActionColor.info => ButtonVariant.info,
  };

  /// Converts ActionSize to ButtonSize.
  ButtonSize get buttonSize => switch (_size) {
    ActionSize.xs => ButtonSize.xs,
    ActionSize.sm => ButtonSize.sm,
    ActionSize.md => ButtonSize.md,
    ActionSize.lg => ButtonSize.lg,
  };

  // ============================================================
  // Rendering
  // ============================================================

  /// Renders the action as a Jaspr [Component].
  ///
  /// The action is rendered differently based on its configuration:
  /// - URL actions render as `<a>` tags via Button
  /// - POST actions render as `<form>` with `<button>`
  Component render(T record, {required String basePath}) {
    if (isHidden(record)) {
      return span([]); // Return empty component
    }

    final isDisabledState = isDisabled(record);

    // URL action - render as link button
    if (isUrlAction()) {
      final url = getUrl(record, basePath)!;
      return Button(
        label: getLabel(),
        variant: buttonVariant,
        size: buttonSize,
        icon: _icon,
        iconPosition: _iconPosition,
        hideLabel: _isLabelHidden,
        href: url,
        openInNewTab: _openUrlInNewTab,
        disabled: isDisabledState,
        subtle: true, // Table row actions use subtle style
        attributes: {if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
      );
    }

    // POST action - render as form with button
    if (isPostAction()) {
      final url = getActionUrl(record, basePath)!;
      final confirmScript = _requiresConfirmation ? "return confirm('${_getConfirmationMessage()}')" : null;

      return form(action: url, method: FormMethod.post, classes: 'inline', [
        // Method spoofing for DELETE/PUT/PATCH
        if (_actionMethod != 'POST') input(type: InputType.hidden, name: '_method', value: _actionMethod),
        Button(
          label: getLabel(),
          variant: buttonVariant,
          size: buttonSize,
          icon: _icon,
          iconPosition: _iconPosition,
          hideLabel: _isLabelHidden,
          type: ButtonType.submit,
          disabled: isDisabledState,
          subtle: true, // Table row actions use subtle style
          attributes: {
            if (confirmScript != null) 'onclick': confirmScript,
            if (_tooltip != null) 'title': _tooltip!,
            ..._extraAttributes ?? {},
          },
        ),
      ]);
    }

    // Fallback - render as disabled button
    return Button(
      label: getLabel(),
      variant: buttonVariant,
      size: buttonSize,
      icon: _icon,
      iconPosition: _iconPosition,
      hideLabel: _isLabelHidden,
      disabled: true,
      subtle: true,
    );
  }

  /// Gets the confirmation message for the dialog.
  String _getConfirmationMessage() {
    if (_confirmationDescription != null) {
      return '$_confirmationHeading\\n\\n$_confirmationDescription';
    }
    return _confirmationHeading ?? 'Are you sure?';
  }

  // ============================================================
  // Header Action Rendering
  // ============================================================

  /// Renders the action as a header button (without record context).
  ///
  /// Header actions are used in page headers and don't operate on a specific
  /// record. They typically navigate to URLs like create pages.
  Component renderAsHeaderAction({required String basePath}) {
    // For header actions, we expect a URL that doesn't need a record
    if (_url != null) {
      return Button(
        label: getLabel(),
        variant: buttonVariant,
        size: buttonSize,
        icon: _icon,
        iconPosition: _iconPosition,
        hideLabel: _isLabelHidden,
        href: '$basePath/create',
        openInNewTab: _openUrlInNewTab,
        attributes: {if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
      );
    }

    // Fallback - render as a button (for POST actions in headers)
    return Button(
      label: getLabel(),
      variant: buttonVariant,
      size: buttonSize,
      icon: _icon,
      iconPosition: _iconPosition,
      hideLabel: _isLabelHidden,
      attributes: {if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
    );
  }

  // ============================================================
  // Form Action Rendering
  // ============================================================

  /// Renders the action as a form button (without record context).
  ///
  /// Form actions are used in form footers for submit/cancel operations.
  /// Override this in subclasses for custom behavior (e.g., submit vs button).
  Component renderAsFormAction({bool isDisabled = false}) {
    return Button(
      label: getLabel(),
      variant: buttonVariant,
      size: ButtonSize.md, // Form actions always use md size
      icon: _icon,
      iconPosition: _iconPosition,
      hideLabel: _isLabelHidden,
      disabled: isDisabled,
      attributes: {if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
    );
  }
}
