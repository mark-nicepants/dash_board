import 'package:dash_board/src/components/partials/table/cells/boolean_cell.dart';
import 'package:dash_board/src/components/partials/table/cells/icon_cell.dart';
import 'package:dash_board/src/components/partials/table/cells/image_cell.dart';
import 'package:dash_board/src/components/partials/table/cells/text_cell.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/boolean_column.dart';
import 'package:dash_board/src/table/columns/column.dart';
import 'package:dash_board/src/table/columns/icon_column.dart';
import 'package:dash_board/src/table/columns/image_column.dart';
import 'package:dash_board/src/table/columns/text_column.dart';
import 'package:jaspr/jaspr.dart';

/// Factory for creating the appropriate cell component based on column type.
///
/// This factory pattern allows for easy extension when new column types are added.
class TableCellFactory {
  /// Creates the appropriate cell component for the given column and record.
  static Component build<T extends Model>(TableColumn column, T record) {
    if (column is TextColumn) {
      return TextCell<T>(column: column, record: record);
    }

    if (column is BooleanColumn) {
      return BooleanCell<T>(column: column, record: record);
    }

    if (column is ImageColumn) {
      return ImageCell<T>(column: column, record: record);
    }

    if (column is IconColumn) {
      return IconCell<T>(column: column, record: record);
    }

    // Fallback: render as plain text
    final state = column.getState(record);
    return span([text(column.formatState(state))]);
  }
}
