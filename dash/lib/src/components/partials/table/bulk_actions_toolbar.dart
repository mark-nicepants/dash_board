import 'package:dash/src/actions/action.dart';
import 'package:dash/src/actions/action_color.dart';
import 'package:dash/src/components/partials/button.dart';
import 'package:dash/src/components/partials/heroicon.dart';
import 'package:dash/src/model/model.dart';
import 'package:jaspr/jaspr.dart';

/// Toolbar that appears when records are selected in a table.
///
/// Shows the number of selected records and bulk action buttons.
/// Hidden when no records are selected using Alpine.js.
///
/// Example:
/// ```dart
/// BulkActionsToolbar<User>(
///   actions: [
///     Action.make('archive').label('Archive').icon(HeroIcons.archiveBox),
///     Action.make('delete').label('Delete').danger().requiresConfirmation(),
///   ],
///   basePath: '/admin/users',
/// )
/// ```
class BulkActionsToolbar<T extends Model> extends StatelessComponent {
  /// The bulk actions to display.
  final List<Action<T>> actions;

  /// The base path for action URLs.
  final String basePath;

  const BulkActionsToolbar({required this.actions, required this.basePath});

  @override
  Component build(BuildContext context) {
    if (actions.isEmpty) return span([]);

    return div(
      classes:
          'flex items-center justify-between px-4 py-3 bg-gray-800/90 border-b border-gray-700 backdrop-blur-sm sticky top-0 z-10',
      attributes: {
        'x-show': 'selectedIds.length > 0',
        'x-transition:enter': 'transition ease-out duration-200',
        'x-transition:enter-start': 'opacity-0 -translate-y-2',
        'x-transition:enter-end': 'opacity-100 translate-y-0',
        'x-transition:leave': 'transition ease-in duration-150',
        'x-transition:leave-start': 'opacity-100 translate-y-0',
        'x-transition:leave-end': 'opacity-0 -translate-y-2',
        'x-cloak': '',
      },
      [
        // Selection info
        div(classes: 'flex items-center gap-3', [
          // Close/deselect button
          button(
            type: ButtonType.button,
            classes: 'p-1 rounded-lg text-gray-400 hover:bg-gray-700 hover:text-white transition-colors',
            attributes: {'@click': 'clearSelection'},
            [const Heroicon(HeroIcons.xMark, size: 20)],
          ),

          // Selection count
          span(
            classes: 'text-sm text-gray-300',
            attributes: {'x-text': "selectedIds.length + ' selected'"},
            [text('0 selected')], // Fallback text
          ),
        ]),

        // Bulk action buttons
        div(classes: 'flex items-center gap-2', [for (final action in actions) _buildBulkActionButton(action)]),
      ],
    );
  }

  Component _buildBulkActionButton(Action<T> action) {
    final actionUrl = '$basePath/bulk-actions/${action.getName()}';

    // For actions with confirmation, we need to show a modal
    if (action.isConfirmationRequired()) {
      return _buildBulkActionWithConfirmation(action, actionUrl);
    }

    // Simple form submission for non-confirmation actions
    return form(action: actionUrl, method: FormMethod.post, classes: 'inline', [
      // Hidden input for selected IDs
      input(type: InputType.hidden, name: 'ids', attributes: {':value': 'selectedIds.join(",")'}),
      Button(
        label: action.getLabel(),
        variant: action.buttonVariant,
        size: ButtonSize.sm,
        icon: action.getIcon(),
        iconPosition: action.getIconPosition(),
        type: ButtonType.submit,
      ),
    ]);
  }

  Component _buildBulkActionWithConfirmation(Action<T> action, String actionUrl) {
    final modalId = 'bulk-${action.getName()}-modal';
    final confirmationDesc = action.getConfirmationDescription() ?? 'This cannot be undone.';

    return div(
      attributes: {'x-data': '{ showConfirm: false }'},
      [
        // Trigger button
        Button(
          label: action.getLabel(),
          variant: action.buttonVariant,
          size: ButtonSize.sm,
          icon: action.getIcon(),
          iconPosition: action.getIconPosition(),
          attributes: {'@click': 'showConfirm = true'},
        ),

        // Confirmation modal - use x-teleport to escape stacking context
        _BulkActionModal(modalId: modalId, action: action, actionUrl: actionUrl, confirmationDesc: confirmationDesc),
      ],
    );
  }
}

/// Modal component for bulk action confirmation.
/// Uses x-teleport to render at body level, escaping any stacking contexts.
class _BulkActionModal<T extends Model> extends StatelessComponent {
  final String modalId;
  final Action<T> action;
  final String actionUrl;
  final String confirmationDesc;

  const _BulkActionModal({
    required this.modalId,
    required this.action,
    required this.actionUrl,
    required this.confirmationDesc,
  });

  @override
  Component build(BuildContext context) {
    // We need to use raw() to create a <template> element since Jaspr doesn't have one built-in
    // The template with x-teleport will be rendered at body level by Alpine.js
    return raw('''
<template x-teleport="body">
  <div id="$modalId" class="relative z-[100]" x-show="showConfirm" x-cloak @keydown.escape.window="showConfirm = false" role="dialog" aria-modal="true">
    <div class="fixed inset-0 bg-black/70 transition-opacity" x-show="showConfirm" x-transition.opacity @click="showConfirm = false"></div>
    <div class="fixed inset-0 z-10 overflow-y-auto" @click="showConfirm = false">
      <div class="flex min-h-full items-center justify-center p-4">
        <div class="relative w-full max-w-sm transform overflow-hidden rounded-xl bg-gray-800 border border-gray-700 shadow-2xl"
             x-show="showConfirm"
             x-transition:enter="ease-out duration-300"
             x-transition:enter-start="opacity-0 scale-95"
             x-transition:enter-end="opacity-100 scale-100"
             x-transition:leave="ease-in duration-200"
             x-transition:leave-start="opacity-100 scale-100"
             x-transition:leave-end="opacity-0 scale-95"
             @click.stop>
          <div class="p-6 text-center">
            <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-red-500/10 mb-4">
              <svg class="w-6 h-6 text-red-500" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126ZM12 15.75h.007v.008H12v-.008Z" />
              </svg>
            </div>
            <h3 class="text-lg font-semibold text-white">${action.getConfirmationHeading()}</h3>
            <p class="mt-2 text-sm text-gray-400" x-text="'This action will affect ' + selectedIds.length + ' record' + (selectedIds.length === 1 ? '' : 's') + '. $confirmationDesc'">
              This action will affect the selected records.
            </p>
          </div>
          <form action="$actionUrl" method="post" class="flex items-center justify-end gap-3 border-t border-gray-700 px-6 py-4 bg-gray-800/50">
            <input type="hidden" name="ids" :value="selectedIds.join(',')">
            <button type="button" class="inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg bg-gray-700 text-white hover:bg-gray-600 transition-all" @click="showConfirm = false">
              Cancel
            </button>
            <button type="submit" class="inline-flex items-center justify-center gap-2 px-4 py-2 text-sm font-semibold rounded-lg ${_getButtonClasses(action)} transition-all">
              ${action.getConfirmationButtonLabel()}
            </button>
          </form>
        </div>
      </div>
    </div>
  </div>
</template>
''');
  }

  String _getButtonClasses(Action<T> action) {
    return switch (action.getColor()) {
      ActionColor.danger => 'bg-red-600 text-white hover:bg-red-500',
      ActionColor.warning => 'bg-yellow-600 text-white hover:bg-yellow-500',
      ActionColor.success => 'bg-green-600 text-white hover:bg-green-500',
      ActionColor.info => 'bg-blue-600 text-white hover:bg-blue-500',
      ActionColor.primary => 'bg-primary-600 text-white hover:bg-primary-500',
      ActionColor.secondary => 'bg-gray-600 text-white hover:bg-gray-500',
    };
  }
}
