import 'package:dash_board/src/actions/action_color.dart';
import 'package:dash_board/src/actions/action_size.dart';
import 'package:dash_board/src/actions/handler/action_handler.dart';
import 'package:dash_board/src/actions/handler/action_handler_registry.dart';
import 'package:dash_board/src/auth/csrf_protection.dart';
import 'package:dash_board/src/components/partials/button.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/components/partials/modal/modal.dart';
import 'package:dash_board/src/components/partials/modal/modal_size.dart';
import 'package:dash_board/src/context/request_context.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:dash_board/src/model/model.dart';
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

  // Modal Configuration
  HeroIcons? _modalIcon;
  ActionColor _modalIconColor = ActionColor.danger;
  ModalSize _modalSize = ModalSize.sm;

  // Form Schema (for actions with forms)
  List<Object>? _formFields;
  int _formColumns = 1;
  Map<String, dynamic> Function(T record)? _fillFormCallback;

  // Action Handler
  ActionHandler? _handler;

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

  /// Sets the action color to danger (red).
  Action<T> danger() => color(ActionColor.danger);

  /// Sets the action color to success (green).
  Action<T> success() => color(ActionColor.success);

  /// Sets the action color to warning (yellow/orange).
  Action<T> warning() => color(ActionColor.warning);

  /// Sets the action color to info (blue).
  Action<T> info() => color(ActionColor.info);

  /// Sets the action color to secondary (gray).
  Action<T> secondary() => color(ActionColor.secondary);

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
  // Modal Configuration
  // ============================================================

  /// Sets the icon for the confirmation modal.
  ///
  /// ```dart
  /// Action.make('delete')
  ///   .requiresConfirmation()
  ///   .modalIcon(HeroIcons.trash)
  /// ```
  Action<T> modalIcon(HeroIcons icon) {
    _modalIcon = icon;
    return this;
  }

  /// Sets the icon color for the confirmation modal.
  Action<T> modalIconColor(ActionColor color) {
    _modalIconColor = color;
    return this;
  }

  /// Sets the size of the confirmation modal.
  Action<T> modalSize(ModalSize size) {
    _modalSize = size;
    return this;
  }

  // ============================================================
  // Form Schema (for actions with forms)
  // ============================================================

  /// Sets form fields to display in the action modal.
  ///
  /// Actions with forms show a modal where users can fill in data
  /// before the action is executed.
  ///
  /// ```dart
  /// Action.make('updateStatus')
  ///   .schema([
  ///     Select.make('status')
  ///       .options([
  ///         SelectOption('pending', 'Pending'),
  ///         SelectOption('approved', 'Approved'),
  ///         SelectOption('rejected', 'Rejected'),
  ///       ])
  ///       .required(),
  ///     Textarea.make('notes').label('Notes'),
  ///   ])
  ///   .fillForm((record) => {'status': record.status})
  ///   .actionUrl((record, basePath) => '$basePath/${record.id}/update-status')
  /// ```
  Action<T> schema(List<Object> fields) {
    _formFields = fields;
    // Actions with forms need to open a modal
    _requiresConfirmation = true;
    // Default to larger modal for forms
    if (_modalSize == ModalSize.sm) {
      _modalSize = ModalSize.md;
    }
    return this;
  }

  /// Sets the number of columns for the form fields.
  Action<T> formColumns(int columns) {
    _formColumns = columns;
    return this;
  }

  /// Pre-fills the form fields with data from the record.
  ///
  /// ```dart
  /// Action.make('updateStatus')
  ///   .schema([...])
  ///   .fillForm((record) => {'status': record.status, 'notes': ''})
  /// ```
  Action<T> fillForm(Map<String, dynamic> Function(T record) callback) {
    _fillFormCallback = callback;
    return this;
  }

  /// Whether this action has a form.
  bool hasForm() => _formFields != null && _formFields!.isNotEmpty;

  /// Gets the form fields.
  List<Object>? getFormFields() => _formFields;

  /// Gets the form columns.
  int getFormColumns() => _formColumns;

  /// Gets the filled form data for a record.
  Map<String, dynamic>? getFilledFormData(T record) => _fillFormCallback?.call(record);

  // ============================================================
  // Action Handler
  // ============================================================

  /// Sets an action handler for server-side execution.
  ///
  /// When a handler is set, the action will POST to a generated route
  /// that executes the handler logic.
  ///
  /// ```dart
  /// Action.make('archive')
  ///   .label('Archive')
  ///   .handler(ArchiveUserHandler())
  ///   .requiresConfirmation()
  /// ```
  ///
  /// The handler is automatically registered when the action is rendered.
  Action<T> handler(ActionHandler actionHandler) {
    _handler = actionHandler;
    return this;
  }

  /// Gets the action handler.
  ActionHandler? getHandler() => _handler;

  /// Whether this action has a handler.
  bool hasHandler() => _handler != null;

  /// Registers the handler with the registry (called automatically).
  ///
  /// The [resourceSlug] is used to generate a unique route key.
  void registerHandler(String resourceSlug) {
    if (_handler != null) {
      ActionHandlerRegistry.register(resourceSlug: resourceSlug, actionName: _name, handler: _handler!);
    }
  }

  /// Gets the action URL, using the handler route if a handler is set.
  String getActionUrlForRecord(T record, String basePath, {String? resourceSlug}) {
    // If handler is set, use the handler route
    if (_handler != null && resourceSlug != null) {
      final recordId = getRecordId(record);
      return ActionHandlerRegistry.getRoutePath(basePath, _name, recordId: recordId);
    }
    // Otherwise use the custom action URL
    return _actionUrl?.call(record, basePath) ?? '$basePath/${getRecordId(record)}/actions/$_name';
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

  /// Checks if this is a POST action (has actionUrl or handler).
  bool isPostAction() => _actionUrl != null || _handler != null;

  // ============================================================
  // Helper Methods
  // ============================================================

  /// Gets the record's primary key value.
  ///
  /// This is a helper method for building URLs that reference a specific record.
  /// Subclasses can use this to construct action URLs.
  dynamic getRecordId(T record) {
    final fields = record.toMap();
    final primaryKey = record.primaryKey;
    return fields[primaryKey];
  }

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
  /// - POST actions with handlers use DashWire (wire:click)
  /// - POST actions without handlers render as `<form>` with `<button>`
  ///
  /// The optional [resourceSlug] parameter is required for actions with handlers
  /// to generate the correct action URL.
  Component render(T record, {required String basePath, String? resourceSlug}) {
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

    // POST action with handler - use DashWire (wire:click)
    if (isPostAction() && _handler != null && resourceSlug != null) {
      // If confirmation is required, render with a modal
      if (_requiresConfirmation) {
        return _renderWithConfirmationModalWire(record, resourceSlug, isDisabledState);
      }

      // Direct DashWire action without confirmation
      final recordId = getRecordId(record);
      return Button(
        label: getLabel(),
        variant: buttonVariant,
        size: buttonSize,
        icon: _icon,
        iconPosition: _iconPosition,
        hideLabel: _isLabelHidden,
        disabled: isDisabledState,
        subtle: true,
        attributes: {
          'wire:click': "executeAction('$_name', '$recordId')",
          if (_tooltip != null) 'title': _tooltip!,
          ..._extraAttributes ?? {},
        },
      );
    }

    // POST action without handler - render as form with button (legacy)
    if (isPostAction()) {
      // Get the action URL - use handler route if handler is set, otherwise use custom actionUrl
      final url = getActionUrlForRecord(record, basePath, resourceSlug: resourceSlug);

      // If confirmation is required, render with a modal
      if (_requiresConfirmation) {
        return _renderWithConfirmationModal(record, url, isDisabledState);
      }

      // Direct form submission without confirmation
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
          subtle: true,
          attributes: {if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
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

  /// Renders a handler-based action with a styled confirmation modal using DashWire.
  ///
  /// The modal triggers a wire:click action when confirmed.
  Component _renderWithConfirmationModalWire(T record, String resourceSlug, bool isDisabledState) {
    // Generate a unique modal ID based on action name and record
    final recordId = getRecordId(record);
    final modalId = 'confirm-$_name-$recordId';

    // Determine the icon to show (use provided or default based on color)
    // Don't show icon for form actions (they focus on the form content)
    final displayIcon = hasForm() ? null : (_modalIcon ?? _getDefaultConfirmationIcon());

    // Build form content for wire-based modal
    final formContent = _buildModalFormContentWire(record, modalId);

    return div(
      classes: 'inline',
      attributes: {'x-data': '{ open: false }'},
      [
        // Trigger button
        Button(
          label: getLabel(),
          variant: buttonVariant,
          size: buttonSize,
          icon: _icon,
          iconPosition: _iconPosition,
          hideLabel: _isLabelHidden,
          disabled: isDisabledState,
          subtle: true,
          attributes: {'@click': 'open = true', if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
        ),

        // Confirmation modal (inline, Alpine-controlled by parent x-data)
        Modal(
          id: modalId,
          heading: getConfirmationHeading(),
          description: hasForm() ? null : getConfirmationDescription(),
          icon: displayIcon,
          iconColor: _modalIconColor,
          size: _modalSize,
          body: formContent,
          manageOwnState: false, // Parent div provides x-data with 'open'
          footer: [
            const ModalCancelButton(),
            ModalConfirmButton(
              label: getConfirmationButtonLabel(),
              color: hasForm() ? ActionColor.primary : _modalIconColor,
              attributes: {
                'wire:click': hasForm()
                    ? "executeAction('$_name', '$recordId', \$formData)"
                    : "executeAction('$_name', '$recordId')",
                '@click': 'open = false',
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the form content for a wire-based modal (no action URL needed).
  Component _buildModalFormContentWire(T record, String modalId) {
    // Get initial data if fillForm callback is provided
    final initialData = _fillFormCallback?.call(record) ?? {};

    // Build field components if this action has a form
    final fieldComponents = <Component>[];
    if (hasForm()) {
      for (final field in _formFields!) {
        if (field is FormField) {
          // Fill with initial data if available
          final fieldName = field.getName();
          if (initialData.containsKey(fieldName)) {
            field.defaultValue(initialData[fieldName]);
          }
          fieldComponents.add(_ActionFormFieldWrapper(field: field));
        }
      }
    }

    // Return a form element (without action) that holds the fields
    return div(classes: 'modal-content', [
      if (fieldComponents.isNotEmpty)
        form([
          div(
            classes: 'grid grid-cols-1 ${_formColumns > 1 ? 'md:grid-cols-$_formColumns' : ''} gap-4',
            fieldComponents,
          ),
        ])
      else
        span([]), // Empty placeholder
    ]);
  }

  /// Renders a POST action with a styled confirmation modal.
  ///
  /// The modal contains the form that submits when confirmed.
  Component _renderWithConfirmationModal(T record, String url, bool isDisabledState) {
    // Generate a unique modal ID based on action name and record
    final recordId = getRecordId(record);
    final modalId = 'confirm-$_name-$recordId';

    // Determine the icon to show (use provided or default based on color)
    // Don't show icon for form actions (they focus on the form content)
    final displayIcon = hasForm() ? null : (_modalIcon ?? _getDefaultConfirmationIcon());

    // Build form content
    final formContent = _buildModalFormContent(record, url, modalId);

    return div(
      classes: 'inline',
      attributes: {'x-data': '{ open: false }'},
      [
        // Trigger button
        Button(
          label: getLabel(),
          variant: buttonVariant,
          size: buttonSize,
          icon: _icon,
          iconPosition: _iconPosition,
          hideLabel: _isLabelHidden,
          disabled: isDisabledState,
          subtle: true,
          attributes: {'@click': 'open = true', if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
        ),

        // Confirmation modal (inline, Alpine-controlled by parent x-data)
        Modal(
          id: modalId,
          heading: getConfirmationHeading(),
          description: hasForm() ? null : getConfirmationDescription(),
          icon: displayIcon,
          iconColor: _modalIconColor,
          size: _modalSize,
          body: formContent,
          manageOwnState: false, // Parent div provides x-data with 'open'
          footer: [
            const ModalCancelButton(),
            ModalConfirmButton(
              label: getConfirmationButtonLabel(),
              color: hasForm() ? ActionColor.primary : _modalIconColor,
              attributes: {'@click': "document.getElementById('$modalId-form').submit()"},
            ),
          ],
        ),
      ],
    );
  }

  /// Builds the form content for the modal.
  Component _buildModalFormContent(T record, String url, String modalId) {
    final formId = '$modalId-form';

    // Get initial data if fillForm callback is provided
    final initialData = _fillFormCallback?.call(record) ?? {};

    // Build field components if this action has a form
    final fieldComponents = <Component>[];
    if (hasForm()) {
      for (final field in _formFields!) {
        if (field is FormField) {
          // Fill with initial data if available
          final fieldName = field.getName();
          if (initialData.containsKey(fieldName)) {
            field.defaultValue(initialData[fieldName]);
          }
          fieldComponents.add(_ActionFormFieldWrapper(field: field));
        }
      }
    }

    return form(action: url, method: FormMethod.post, id: formId, [
      // CSRF token for protection against cross-site request forgery
      _buildCsrfTokenField(),
      // Method spoofing for DELETE/PUT/PATCH
      if (_actionMethod != 'POST') input(type: InputType.hidden, name: '_method', value: _actionMethod),

      // Form fields (if any)
      if (fieldComponents.isNotEmpty)
        div(classes: 'grid grid-cols-1 ${_formColumns > 1 ? 'md:grid-cols-$_formColumns' : ''} gap-4', fieldComponents),
    ]);
  }

  /// Builds the hidden CSRF token field for action forms.
  Component _buildCsrfTokenField() {
    final sessionId = RequestContext.sessionId;
    final token = CsrfProtection.generateToken(sessionId ?? 'no-session');
    return input(type: InputType.hidden, name: CsrfProtection.tokenFieldName, value: token);
  }

  /// Gets the default icon for confirmation based on the action color/type.
  HeroIcons _getDefaultConfirmationIcon() {
    return switch (_color) {
      ActionColor.danger => HeroIcons.exclamationTriangle,
      ActionColor.warning => HeroIcons.exclamationCircle,
      ActionColor.info => HeroIcons.informationCircle,
      _ => HeroIcons.questionMarkCircle,
    };
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

  /// Renders the action as a header button with record context.
  ///
  /// Used on view pages where header actions need to operate on a specific record.
  /// For example, an "Edit" button that navigates to the edit page for the current record.
  Component renderAsHeaderActionWithRecord({required T record, required String basePath}) {
    // URL action - render as link button
    if (_url != null) {
      final url = _url!(record, basePath);
      return Button(
        label: getLabel(),
        variant: buttonVariant,
        size: buttonSize,
        icon: _icon,
        iconPosition: _iconPosition,
        hideLabel: _isLabelHidden,
        href: url,
        openInNewTab: _openUrlInNewTab,
        attributes: {if (_tooltip != null) 'title': _tooltip!, ..._extraAttributes ?? {}},
      );
    }

    // Fallback - render as a button
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

/// Internal component wrapper for rendering FormField instances in action modals.
///
/// This is needed because FormField.build() requires a BuildContext.
class _ActionFormFieldWrapper extends StatelessComponent {
  final FormField field;

  const _ActionFormFieldWrapper({required this.field});

  @override
  Component build(BuildContext context) {
    return field.build(context);
  }
}
