import 'package:dash/src/components/partials/forms/form_styles.dart';
import 'package:dash/src/model/model.dart';
import 'package:jaspr/jaspr.dart';

/// Checkbox cell component for row selection in tables.
///
/// Used with Alpine.js state management for bulk action selection.
/// The component integrates with the parent table's selection state.
///
/// Example:
/// ```html
/// <tr x-data="{ selected: false }">
///   <td>
///     <input type="checkbox" x-model="selected" @change="toggleRow(id)">
///   </td>
///   <!-- other cells -->
/// </tr>
/// ```
class CheckboxColumn<T extends Model> extends StatelessComponent {
  /// The record this checkbox is for.
  final T record;

  /// The primary key value of the record.
  final dynamic recordId;

  const CheckboxColumn({required this.record, required this.recordId});

  @override
  Component build(BuildContext context) {
    return td(classes: 'w-12 px-4 py-4', [
      // Use container div for proper vertical centering (matching FormStyles.checkboxContainer)
      div(classes: FormStyles.checkboxContainer, [
        input(
          type: InputType.checkbox,
          classes: FormStyles.checkbox,
          value: '$recordId',
          attributes: {'x-model': 'selectedIds'},
        ),
      ]),
    ]);
  }
}

/// Header checkbox for selecting/deselecting all rows.
class CheckboxColumnHeader extends StatelessComponent {
  const CheckboxColumnHeader();

  @override
  Component build(BuildContext context) {
    return th(classes: 'w-12 px-4 py-3', [
      // Use container div for proper vertical centering (matching FormStyles.checkboxContainer)
      div(classes: FormStyles.checkboxContainer, [
        input(
          type: InputType.checkbox,
          classes: FormStyles.checkbox,
          attributes: {
            ':checked': 'allSelected',
            ':indeterminate': 'someSelected && !allSelected',
            '@change': 'toggleAll',
          },
        ),
      ]),
    ]);
  }
}
