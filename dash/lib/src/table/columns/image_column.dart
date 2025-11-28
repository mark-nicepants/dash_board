import 'package:dash/src/model/model.dart';
import 'package:dash/src/service_locator.dart';
import 'package:dash/src/table/columns/column.dart';

/// A column that displays an image.
///
/// This column is useful for displaying user avatars, product images,
/// or any other image data in a table.
///
/// Example:
/// ```dart
/// ImageColumn.make('avatar')
///   .circular()
///   .size(40)
///   .disk('public'),  // Prepends storage URL for 'public' disk
///
/// ImageColumn.make('product_image')
///   .label('Image')
///   .size(60)
///   .rounded(),
///
/// ImageColumn.make('cover')
///   .square()
///   .size(80),
/// ```
class ImageColumn extends TableColumn {
  /// The size of the image in pixels (width and height for square/circular).
  int _size = 40;

  /// The width of the image (if different from size).
  int? _width;

  /// The height of the image (if different from size).
  int? _height;

  /// Whether the image is circular (for avatars).
  bool _circular = false;

  /// Whether the image has rounded corners.
  bool _rounded = false;

  /// Border radius for custom rounding.
  String? _borderRadius;

  /// Whether the image is square (equal width and height).
  bool _square = true;

  /// Default image URL when the value is null.
  String? _defaultImageUrl;

  /// Alt text for the image.
  String? _alt;

  /// Function to generate alt text from the model.
  String Function(Model)? _altResolver;

  /// Whether the image is clickable/expandable.
  bool _expandable = false;

  /// Whether to show a border around the image.
  bool _bordered = false;

  /// Border color class.
  String _borderColor = 'border-gray-600';

  /// Background color class for loading/empty state.
  String _backgroundColor = 'bg-gray-700';

  /// Whether to lazy load the image.
  bool _lazyLoad = true;

  /// Object fit style.
  ImageFit _fit = ImageFit.cover;

  /// Storage disk name for URL generation.
  String? _disk;

  ImageColumn(super.name);

  /// Creates a new image column.
  static ImageColumn make(String name) {
    return ImageColumn(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  ImageColumn label(String label) {
    super.label(label);
    return this;
  }

  @override
  ImageColumn sortable([bool sortable = true]) {
    super.sortable(sortable);
    return this;
  }

  @override
  ImageColumn searchable([bool searchable = true]) {
    super.searchable(searchable);
    return this;
  }

  @override
  ImageColumn toggleable({bool toggleable = true, bool isToggledHiddenByDefault = false}) {
    super.toggleable(toggleable: toggleable, isToggledHiddenByDefault: isToggledHiddenByDefault);
    return this;
  }

  @override
  ImageColumn hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  ImageColumn alignment(ColumnAlignment alignment) {
    super.alignment(alignment);
    return this;
  }

  @override
  ImageColumn alignStart() {
    super.alignStart();
    return this;
  }

  @override
  ImageColumn alignCenter() {
    super.alignCenter();
    return this;
  }

  @override
  ImageColumn alignEnd() {
    super.alignEnd();
    return this;
  }

  @override
  ImageColumn width(String width) {
    super.width(width);
    return this;
  }

  @override
  ImageColumn grow([bool grow = true]) {
    super.grow(grow);
    return this;
  }

  @override
  ImageColumn placeholder(String text) {
    super.placeholder(text);
    return this;
  }

  @override
  ImageColumn defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  ImageColumn state(dynamic Function(Model) resolver) {
    super.state(resolver);
    return this;
  }

  // ============================================================
  // ImageColumn-specific methods
  // ============================================================

  /// Sets the size of the image (width and height).
  ImageColumn size(int size) {
    _size = size;
    return this;
  }

  /// Gets the size.
  int getSize() => _size;

  /// Sets the width of the image.
  ImageColumn imageWidth(int width) {
    _width = width;
    return this;
  }

  /// Gets the width.
  int getImageWidth() => _width ?? _size;

  /// Sets the height of the image.
  ImageColumn imageHeight(int height) {
    _height = height;
    return this;
  }

  /// Gets the height.
  int getImageHeight() => _height ?? _size;

  /// Makes the image circular (for avatars).
  ImageColumn circular([bool circular = true]) {
    _circular = circular;
    if (circular) {
      _rounded = false;
    }
    return this;
  }

  /// Checks if the image is circular.
  bool isCircular() => _circular;

  /// Makes the image have rounded corners.
  ImageColumn rounded([bool rounded = true]) {
    _rounded = rounded;
    if (rounded) {
      _circular = false;
    }
    return this;
  }

  /// Checks if the image has rounded corners.
  bool isRounded() => _rounded;

  /// Sets a custom border radius.
  ImageColumn radius(String radius) {
    _borderRadius = radius;
    return this;
  }

  /// Gets the border radius.
  String? getBorderRadius() => _borderRadius;

  /// Makes the image square.
  ImageColumn square([bool square = true]) {
    _square = square;
    return this;
  }

  /// Checks if the image is square.
  bool isSquare() => _square;

  /// Sets the default image URL for null values.
  ImageColumn defaultImage(String url) {
    _defaultImageUrl = url;
    return this;
  }

  /// Gets the default image URL.
  String? getDefaultImageUrl() => _defaultImageUrl;

  /// Sets the alt text for the image.
  ImageColumn alt(String alt) {
    _alt = alt;
    return this;
  }

  /// Sets a function to generate alt text from the model.
  ImageColumn altFrom(String Function(Model) resolver) {
    _altResolver = resolver;
    return this;
  }

  /// Gets the alt text for a model.
  String getAlt(Model model) {
    if (_altResolver != null) {
      return _altResolver!(model);
    }
    return _alt ?? '';
  }

  /// Makes the image expandable/clickable for a larger view.
  ImageColumn expandable([bool expandable = true]) {
    _expandable = expandable;
    return this;
  }

  /// Checks if the image is expandable.
  bool isExpandable() => _expandable;

  /// Adds a border around the image.
  ImageColumn bordered([bool bordered = true]) {
    _bordered = bordered;
    return this;
  }

  /// Checks if the image has a border.
  bool isBordered() => _bordered;

  /// Sets the border color class.
  ImageColumn borderColor(String color) {
    _borderColor = color;
    return this;
  }

  /// Gets the border color class.
  String getBorderColor() => _borderColor;

  /// Sets the background color class.
  ImageColumn backgroundColor(String color) {
    _backgroundColor = color;
    return this;
  }

  /// Gets the background color class.
  String getBackgroundColor() => _backgroundColor;

  /// Enables or disables lazy loading.
  ImageColumn lazyLoad([bool lazy = true]) {
    _lazyLoad = lazy;
    return this;
  }

  /// Checks if lazy loading is enabled.
  bool isLazyLoad() => _lazyLoad;

  /// Sets the object fit style.
  ImageColumn fit(ImageFit fit) {
    _fit = fit;
    return this;
  }

  /// Gets the object fit style.
  ImageFit getFit() => _fit;

  /// Convenience method for cover fit.
  ImageColumn cover() => fit(ImageFit.cover);

  /// Convenience method for contain fit.
  ImageColumn contain() => fit(ImageFit.contain);

  /// Convenience method for fill fit.
  ImageColumn fill() => fit(ImageFit.fill);

  /// Sets the storage disk for URL generation.
  ///
  /// When set, the column will prepend the storage URL prefix to the path.
  /// Use this when the model stores relative paths like 'avatars/file.jpg'
  /// and needs to be served from '/admin/storage/{disk}/avatars/file.jpg'.
  ImageColumn disk(String disk) {
    _disk = disk;
    return this;
  }

  /// Gets the storage disk name.
  String? getDisk() => _disk;

  /// Gets the image URL from the state.
  String? getImageUrl(Model model) {
    final state = getState(model);
    if (state == null || state.toString().isEmpty) {
      return _defaultImageUrl;
    }

    final path = state.toString();

    // If it's already a full URL or absolute path, return as-is
    if (path.startsWith('http://') || path.startsWith('https://') || path.startsWith('/')) {
      return path;
    }

    // Use the service locator helper to get the proper storage URL
    return getStorageUrl(path, disk: _disk);
  }

  @override
  String formatState(dynamic state) {
    if (state == null) return _defaultImageUrl ?? '';
    return state.toString();
  }
}

/// Object fit options for images.
enum ImageFit {
  /// Scale to fill, cropping as needed.
  cover,

  /// Scale to fit within bounds.
  contain,

  /// Stretch to fill exactly.
  fill,

  /// No scaling.
  none,

  /// Scale down only if needed.
  scaleDown,
}
