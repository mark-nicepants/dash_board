import 'package:dash_board/src/actions/action_color.dart';
import 'package:dash_board/src/components/partials/button.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/components/partials/modal/modal_size.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// Modal component with Alpine.js for open/close state management.
///
/// Modals are used for confirmations, action forms, and custom content.
/// They use Alpine.js for client-side state and can optionally load
/// content via Dashwire for dynamic forms.
///
/// ## Basic Usage
///
/// ```dart
/// Modal(
///   id: 'delete-confirmation',
///   heading: 'Delete User',
///   description: 'Are you sure you want to delete this user?',
///   icon: HeroIcons.exclamationTriangle,
///   iconColor: ActionColor.danger,
///   footer: [
///     ModalCancelButton(),
///     ModalConfirmButton(label: 'Delete', color: ActionColor.danger),
///   ],
/// )
/// ```
///
/// ## Trigger Button
///
/// Use [ModalTrigger] to create a button that opens the modal:
///
/// ```dart
/// ModalTrigger(
///   modalId: 'delete-confirmation',
///   child: Button(label: 'Delete', variant: ButtonVariant.danger),
/// )
/// ```
class Modal extends StatelessComponent {
  /// Unique identifier for the modal, used for Alpine.js state.
  final String id;

  /// Optional heading text displayed at the top.
  final String? heading;

  /// Optional description text below the heading.
  final String? description;

  /// Optional icon displayed above the heading.
  final HeroIcons? icon;

  /// Color of the icon background.
  final ActionColor iconColor;

  /// Size of the modal (controls max-width).
  final ModalSize size;

  /// Whether to render as a slide-over panel instead of centered modal.
  final bool slideOver;

  /// Whether to show a close button in the header.
  final bool showCloseButton;

  /// Whether clicking outside closes the modal.
  final bool closeOnClickOutside;

  /// Whether pressing Escape closes the modal.
  final bool closeOnEscape;

  /// Optional body content.
  final Component? body;

  /// Optional footer content (typically action buttons).
  final List<Component>? footer;

  /// Extra attributes for the modal container.
  final Map<String, String>? attributes;

  /// Whether to manage own Alpine.js state (x-data).
  /// When false, the modal expects a parent to provide the `open` variable.
  final bool manageOwnState;

  const Modal({
    required this.id,
    this.heading,
    this.description,
    this.icon,
    this.iconColor = ActionColor.danger,
    this.size = ModalSize.md,
    this.slideOver = false,
    this.showCloseButton = true,
    this.closeOnClickOutside = true,
    this.closeOnEscape = true,
    this.body,
    this.footer,
    this.attributes,
    this.manageOwnState = true,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return slideOver ? _buildSlideOver() : _buildModal();
  }

  Component _buildModal() {
    // When manageOwnState is false, we expect a parent element to provide x-data with 'open'
    final baseAttributes = <String, String>{
      if (manageOwnState) 'x-data': '{ open: false }',
      'x-show': 'open',
      'x-cloak': '',
      if (closeOnEscape) '@keydown.escape.window': 'open = false',
      'role': 'dialog',
      'aria-modal': 'true',
      ...?attributes,
    };

    return div(id: id, classes: 'relative z-50', attributes: baseAttributes, [
      // Backdrop
      div(
        classes: 'fixed inset-0 bg-black/70 transition-opacity',
        attributes: {
          'x-show': 'open',
          'x-transition:enter': 'ease-out duration-300',
          'x-transition:enter-start': 'opacity-0',
          'x-transition:enter-end': 'opacity-100',
          'x-transition:leave': 'ease-in duration-200',
          'x-transition:leave-start': 'opacity-100',
          'x-transition:leave-end': 'opacity-0',
          if (closeOnClickOutside) '@click': 'open = false',
        },
        [],
      ),

      // Modal container
      div(
        classes: 'fixed inset-0 z-10 overflow-y-auto',
        attributes: {if (closeOnClickOutside) '@click': 'open = false'},
        [
          div(classes: 'flex min-h-full items-center justify-center p-4', [
            // Modal panel
            div(
              classes:
                  'relative w-full ${size.maxWidthClass} transform overflow-hidden rounded-xl bg-gray-800 border border-gray-700 shadow-2xl transition-all',
              attributes: {
                'x-show': 'open',
                'x-transition:enter': 'ease-out duration-300',
                'x-transition:enter-start': 'opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95',
                'x-transition:enter-end': 'opacity-100 translate-y-0 sm:scale-100',
                'x-transition:leave': 'ease-in duration-200',
                'x-transition:leave-start': 'opacity-100 translate-y-0 sm:scale-100',
                'x-transition:leave-end': 'opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95',
                '@click.stop': '', // Prevent closing when clicking inside
              },
              [
                // Header with optional close button
                if (showCloseButton)
                  div(classes: 'absolute right-4 top-4', [
                    button(
                      type: ButtonType.button,
                      classes: 'rounded-lg p-1.5 text-gray-400 hover:bg-gray-700 hover:text-gray-200 transition-colors',
                      attributes: {'@click': 'open = false'},
                      [const Heroicon(HeroIcons.xMark, size: 20)],
                    ),
                  ]),

                // Content
                div(classes: 'p-6', [
                  // Icon
                  if (icon != null)
                    div(classes: 'mx-auto flex h-12 w-12 items-center justify-center rounded-full $_iconBgClass', [
                      Heroicon(icon!, size: 24, className: _iconTextClass),
                    ]),

                  // Heading
                  if (heading != null)
                    h3(classes: 'mt-4 text-lg font-semibold text-white text-center ${icon == null ? "" : "mt-4"}', [
                      text(heading!),
                    ]),

                  // Description
                  if (description != null) p(classes: 'mt-2 text-sm text-gray-400 text-center', [text(description!)]),

                  // Body content
                  if (body != null) div(classes: 'mt-4', [body!]),
                ]),

                // Footer with actions
                if (footer != null && footer!.isNotEmpty)
                  div(
                    classes: 'flex items-center justify-end gap-3 border-t border-gray-700 px-6 py-4 bg-gray-800/50',
                    footer!,
                  ),
              ],
            ),
          ]),
        ],
      ),
    ]);
  }

  Component _buildSlideOver() {
    // When manageOwnState is false, we expect a parent element to provide x-data with 'open'
    final baseAttributes = <String, String>{
      if (manageOwnState) 'x-data': '{ open: false }',
      'x-show': 'open',
      'x-cloak': '',
      if (closeOnEscape) '@keydown.escape.window': 'open = false',
      'role': 'dialog',
      'aria-modal': 'true',
      ...?attributes,
    };

    return div(id: id, classes: 'relative z-50', attributes: baseAttributes, [
      // Backdrop
      div(
        classes: 'fixed inset-0 bg-black/70 transition-opacity',
        attributes: {
          'x-show': 'open',
          'x-transition:enter': 'ease-out duration-300',
          'x-transition:enter-start': 'opacity-0',
          'x-transition:enter-end': 'opacity-100',
          'x-transition:leave': 'ease-in duration-200',
          'x-transition:leave-start': 'opacity-100',
          'x-transition:leave-end': 'opacity-0',
          if (closeOnClickOutside) '@click': 'open = false',
        },
        [],
      ),

      // Slide-over panel
      div(classes: 'fixed inset-0 overflow-hidden', [
        div(classes: 'absolute inset-0 overflow-hidden', [
          div(classes: 'pointer-events-none fixed inset-y-0 right-0 flex max-w-full pl-10', [
            div(
              classes: 'pointer-events-auto w-screen ${size.maxWidthClass}',
              attributes: {
                'x-show': 'open',
                'x-transition:enter': 'transform transition ease-in-out duration-300',
                'x-transition:enter-start': 'translate-x-full',
                'x-transition:enter-end': 'translate-x-0',
                'x-transition:leave': 'transform transition ease-in-out duration-300',
                'x-transition:leave-start': 'translate-x-0',
                'x-transition:leave-end': 'translate-x-full',
                '@click.stop': '',
              },
              [
                div(classes: 'flex h-full flex-col bg-gray-800 border-l border-gray-700 shadow-2xl', [
                  // Header
                  div(classes: 'flex items-start justify-between border-b border-gray-700 px-6 py-4', [
                    div([
                      if (heading != null) h2(classes: 'text-lg font-semibold text-white', [text(heading!)]),
                      if (description != null) p(classes: 'mt-1 text-sm text-gray-400', [text(description!)]),
                    ]),
                    if (showCloseButton)
                      button(
                        type: ButtonType.button,
                        classes:
                            'rounded-lg p-1.5 text-gray-400 hover:bg-gray-700 hover:text-gray-200 transition-colors',
                        attributes: {'@click': 'open = false'},
                        [const Heroicon(HeroIcons.xMark, size: 20)],
                      ),
                  ]),

                  // Body
                  div(classes: 'flex-1 overflow-y-auto px-6 py-4', [if (body != null) body!]),

                  // Footer
                  if (footer != null && footer!.isNotEmpty)
                    div(classes: 'flex items-center justify-end gap-3 border-t border-gray-700 px-6 py-4', footer!),
                ]),
              ],
            ),
          ]),
        ]),
      ]),
    ]);
  }

  String get _iconBgClass => switch (iconColor) {
    ActionColor.danger => 'bg-red-500/10',
    ActionColor.warning => 'bg-amber-500/10',
    ActionColor.success => 'bg-green-500/10',
    ActionColor.info => 'bg-blue-500/10',
    ActionColor.primary => 'bg-${panelColors.primary}-500/10',
    ActionColor.secondary => 'bg-gray-500/10',
  };

  String get _iconTextClass => switch (iconColor) {
    ActionColor.danger => 'text-red-500',
    ActionColor.warning => 'text-amber-500',
    ActionColor.success => 'text-green-500',
    ActionColor.info => 'text-blue-500',
    ActionColor.primary => 'text-${panelColors.primary}-500',
    ActionColor.secondary => 'text-gray-400',
  };
}

/// A button that triggers a modal to open.
///
/// Wraps any component and adds the Alpine.js click handler to open
/// the target modal.
///
/// ```dart
/// ModalTrigger(
///   modalId: 'delete-confirmation',
///   child: Button(label: 'Delete', variant: ButtonVariant.danger),
/// )
/// ```
class ModalTrigger extends StatelessComponent {
  /// The ID of the modal to open.
  final String modalId;

  /// The component that acts as the trigger (typically a Button).
  final Component child;

  const ModalTrigger({required this.modalId, required this.child, super.key});

  @override
  Component build(BuildContext context) {
    return div(
      attributes: {'@click': "\$dispatch('open-modal', { id: '$modalId' })", 'style': 'display: contents;'},
      [child],
    );
  }
}

/// Cancel button for modal footers.
///
/// Closes the modal when clicked without performing any action.
class ModalCancelButton extends StatelessComponent {
  final String label;

  const ModalCancelButton({this.label = 'Cancel', super.key});

  @override
  Component build(BuildContext context) {
    return Button(
      label: label,
      variant: ButtonVariant.secondary,
      size: ButtonSize.md,
      attributes: {'@click': 'open = false'},
    );
  }
}

/// Confirm button for modal footers.
///
/// Can trigger form submission or custom actions.
class ModalConfirmButton extends StatelessComponent {
  final String label;
  final ActionColor color;
  final HeroIcons? icon;
  final bool isSubmit;
  final Map<String, String>? attributes;

  const ModalConfirmButton({
    this.label = 'Confirm',
    this.color = ActionColor.primary,
    this.icon,
    this.isSubmit = false,
    this.attributes,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    final variant = switch (color) {
      ActionColor.danger => ButtonVariant.danger,
      ActionColor.warning => ButtonVariant.warning,
      ActionColor.success => ButtonVariant.success,
      ActionColor.info => ButtonVariant.info,
      ActionColor.secondary => ButtonVariant.secondary,
      ActionColor.primary => ButtonVariant.primary,
    };

    return Button(
      label: label,
      variant: variant,
      size: ButtonSize.md,
      icon: icon,
      type: isSubmit ? ButtonType.submit : ButtonType.button,
      attributes: attributes,
    );
  }
}
