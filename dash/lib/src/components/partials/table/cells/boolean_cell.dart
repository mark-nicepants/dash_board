import 'package:dash_board/src/components/partials/table/cells/icon_cell.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/boolean_column.dart';
import 'package:jaspr/jaspr.dart';

/// Cell component for BooleanColumn that displays a boolean value as an icon.
///
/// This is essentially a specialized IconCell that uses the BooleanColumn's
/// true/false icon and color configuration.
///
/// Example:
/// ```dart
/// BooleanCell<User>(
///   column: BooleanColumn.make('is_active'),
///   record: user,
/// )
/// ```
class BooleanCell<T extends Model> extends StatelessComponent {
  /// The column configuration.
  final BooleanColumn column;

  /// The record to render.
  final T record;

  const BooleanCell({required this.column, required this.record, super.key});

  @override
  Component build(BuildContext context) {
    // BooleanColumn extends IconColumn, so we can reuse IconCell
    return IconCell<T>(column: column, record: record);
  }
}
