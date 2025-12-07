import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/table/columns/image_column.dart';
import 'package:jaspr/jaspr.dart';

/// Cell component for ImageColumn that displays an image.
///
/// Supports circular avatars, rounded corners, and various sizing options.
///
/// Example:
/// ```dart
/// ImageCell<User>(
///   column: ImageColumn.make('avatar').circular().size(40),
///   record: user,
/// )
/// ```
class ImageCell<T extends Model> extends StatelessComponent {
  final ImageColumn column;
  final T record;

  const ImageCell({required this.column, required this.record, super.key});

  @override
  Component build(BuildContext context) {
    final imageUrl = column.getImageUrl(record);
    final width = column.getImageWidth();
    final height = column.getImageHeight();
    final alt = column.getAlt(record);

    // Build classes for the container
    final containerClasses = <String>['overflow-hidden', 'flex-shrink-0', column.getBackgroundColor()];

    // Add shape classes
    if (column.isCircular()) {
      containerClasses.add('rounded-full');
    } else if (column.isRounded()) {
      containerClasses.add('rounded-lg');
    } else if (column.getBorderRadius() != null) {
      containerClasses.add(column.getBorderRadius()!);
    }

    // Add border if needed
    if (column.isBordered()) {
      containerClasses.add('border-2');
      containerClasses.add(column.getBorderColor());
    }

    // Build object-fit class
    final fitClass = switch (column.getFit()) {
      ImageFit.cover => 'object-cover',
      ImageFit.contain => 'object-contain',
      ImageFit.fill => 'object-fill',
      ImageFit.none => 'object-none',
      ImageFit.scaleDown => 'object-scale-down',
    };

    // Style for dimensions
    final style = 'width: ${width}px; height: ${height}px;';

    if (imageUrl == null || imageUrl.isEmpty) {
      // Show placeholder
      return div(
        classes: containerClasses.join(' '),
        attributes: {'style': style},
        [
          div(classes: 'w-full h-full flex items-center justify-center text-gray-500', [
            const Heroicon(HeroIcons.user, size: 20),
          ]),
        ],
      );
    }

    // Build the image
    return div(
      classes: containerClasses.join(' '),
      attributes: {'style': style},
      [
        img(
          classes: 'w-full h-full $fitClass',
          src: imageUrl,
          alt: alt,
          attributes: {if (column.isLazyLoad()) 'loading': 'lazy'},
        ),
      ],
    );
  }
}
