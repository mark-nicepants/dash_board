import 'package:dash_board/src/components/partials/forms/form_components.dart';
import 'package:dash_board/src/components/partials/heroicon.dart';
import 'package:dash_board/src/form/fields/field.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:jaspr/jaspr.dart';

/// SVG icon for file document (HeroIcons.document).
/// Used in raw HTML templates for Alpine.js.
const _fileIconSvg = '''
<svg class="w-6 h-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 14.25v-2.625a3.375 3.375 0 0 0-3.375-3.375h-1.5A1.125 1.125 0 0 1 13.5 7.125v-1.5a3.375 3.375 0 0 0-3.375-3.375H8.25m2.25 0H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 0 0-9-9Z"/>
</svg>
''';

/// SVG icon for download (HeroIcons.arrowDownTray).
/// Used in raw HTML templates for Alpine.js.
const _downloadIconSvg = '''
<svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" d="M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3"/>
</svg>
''';

/// SVG icon for close/remove (HeroIcons.xMark).
/// Used in raw HTML templates for Alpine.js.
const _closeIconSvg = '''
<svg class="w-4 h-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12"/>
</svg>
''';

/// A file upload field with drag-and-drop support.
///
/// This field provides an interactive file upload experience with:
/// - Drag and drop file uploads
/// - Instant async uploads
/// - Image preview for uploaded images
/// - Progress indicator during upload
/// - Multiple file support
///
/// Example:
/// ```dart
/// FileUpload.make('avatar')
///   .label('Profile Picture')
///   .image()
///   .avatar()
///   .directory('avatars')
///   .maxSize(2048), // 2MB
///
/// FileUpload.make('attachments')
///   .label('Attachments')
///   .multiple()
///   .acceptedFileTypes(['application/pdf', 'image/*'])
///   .maxFiles(5),
///
/// FileUpload.make('document')
///   .label('Document')
///   .disk('documents')
///   .directory('contracts')
///   .visibility('private'),
/// ```
class FileUpload extends FormField {
  /// The storage disk to use.
  String? _disk;

  /// The directory within the disk to store files.
  String? _directory;

  /// Accepted file types (MIME types).
  List<String>? _acceptedFileTypes;

  /// Maximum file size in KB.
  int? _maxSize;

  /// Minimum file size in KB.
  int? _minSize;

  /// Maximum number of files (for multiple uploads).
  int? _maxFiles;

  /// Minimum number of files (for multiple uploads).
  int? _minFiles;

  /// Whether multiple files can be uploaded.
  bool _multiple = false;

  /// File visibility ('public' or 'private').
  String? _visibility;

  /// Whether to preserve original filenames.
  bool _preserveFilenames = false;

  /// Whether this is an image-only upload.
  bool _isImage = false;

  /// Whether to display as avatar (circular image).
  bool _isAvatar = false;

  /// Whether files can be reordered.
  bool _isReorderable = false;

  /// Whether files can be downloaded.
  bool _isDownloadable = false;

  /// Whether files can be opened in a new tab.
  bool _isOpenable = false;

  /// Whether to show image previews.
  bool _isPreviewable = true;

  /// Whether files can be deleted.
  bool _isDeletable = true;

  /// Image crop aspect ratio (e.g., '16:9', '1:1').
  String? _imageCropAspectRatio;

  /// Image resize target width.
  int? _imageResizeTargetWidth;

  /// Image resize target height.
  int? _imageResizeTargetHeight;

  /// Placeholder text for the drop zone.
  String _dropzonePlaceholder = 'Drag and drop a file here, or click to browse';

  /// The message shown while uploading.
  String _uploadingMessage = 'Uploading...';

  /// Panel layout ('compact', 'grid', 'list').
  String _panelLayout = 'compact';

  /// Aspect ratio for the panel.
  String? _panelAspectRatio;

  /// Whether to append files (true) or prepend (false) when adding new files.
  bool _appendFiles = true;

  FileUpload(super.name);

  /// Creates a new file upload field.
  static FileUpload make(String name) {
    return FileUpload(name);
  }

  // ============================================================
  // Covariant overrides for fluent API
  // ============================================================

  @override
  FileUpload id(String id) {
    super.id(id);
    return this;
  }

  @override
  FileUpload label(String label) {
    super.label(label);
    return this;
  }

  @override
  FileUpload placeholder(String placeholder) {
    super.placeholder(placeholder);
    return this;
  }

  @override
  FileUpload helperText(String text) {
    super.helperText(text);
    return this;
  }

  @override
  FileUpload hint(String hint) {
    super.hint(hint);
    return this;
  }

  @override
  FileUpload defaultValue(dynamic value) {
    super.defaultValue(value);
    return this;
  }

  @override
  FileUpload required([bool required = true]) {
    super.required(required);
    return this;
  }

  @override
  FileUpload disabled([bool disabled = true]) {
    super.disabled(disabled);
    return this;
  }

  @override
  FileUpload readonly([bool readonly = true]) {
    super.readonly(readonly);
    return this;
  }

  @override
  FileUpload hidden([bool hidden = true]) {
    super.hidden(hidden);
    return this;
  }

  @override
  FileUpload columnSpan(int span) {
    super.columnSpan(span);
    return this;
  }

  @override
  FileUpload columnSpanBreakpoint(String breakpoint, int span) {
    super.columnSpanBreakpoint(breakpoint, span);
    return this;
  }

  @override
  FileUpload columnSpanFull() {
    super.columnSpanFull();
    return this;
  }

  @override
  FileUpload extraClasses(String classes) {
    super.extraClasses(classes);
    return this;
  }

  @override
  FileUpload rule(ValidationRule rule) {
    super.rule(rule);
    return this;
  }

  @override
  FileUpload rules(List<ValidationRule> rules) {
    super.rules(rules);
    return this;
  }

  @override
  FileUpload validationMessage(String rule, String message) {
    super.validationMessage(rule, message);
    return this;
  }

  @override
  FileUpload autofocus([bool autofocus = true]) {
    super.autofocus(autofocus);
    return this;
  }

  @override
  FileUpload autocomplete(String value) {
    super.autocomplete(value);
    return this;
  }

  @override
  FileUpload tabindex(int index) {
    super.tabindex(index);
    return this;
  }

  @override
  FileUpload dehydrate(dynamic Function(dynamic value) callback) {
    super.dehydrate(callback);
    return this;
  }

  @override
  FileUpload hydrate(dynamic Function(dynamic value) callback) {
    super.hydrate(callback);
    return this;
  }

  // ============================================================
  // FileUpload-specific methods
  // ============================================================

  /// Sets the storage disk to use.
  ///
  /// The disk must be registered in the StorageManager.
  /// If not set, uses the default disk.
  FileUpload disk(String disk) {
    _disk = disk;
    return this;
  }

  /// Gets the disk name.
  String? getDisk() => _disk;

  /// Sets the directory within the disk.
  ///
  /// Files will be stored in this subdirectory of the disk's base path.
  /// Example: `directory('avatars')` stores files in `{disk}/avatars/`
  FileUpload directory(String directory) {
    _directory = directory;
    return this;
  }

  /// Gets the directory.
  String? getDirectory() => _directory;

  /// Sets accepted file types.
  ///
  /// Uses MIME types. Can use wildcards like 'image/*'.
  /// Example: `acceptedFileTypes(['image/jpeg', 'image/png', 'application/pdf'])`
  FileUpload acceptedFileTypes(List<String> types) {
    _acceptedFileTypes = types;
    return this;
  }

  /// Gets accepted file types.
  List<String>? getAcceptedFileTypes() => _acceptedFileTypes;

  /// Sets maximum file size in KB.
  FileUpload maxSize(int sizeKb) {
    _maxSize = sizeKb;
    return this;
  }

  /// Gets the maximum size in KB.
  int? getMaxSize() => _maxSize;

  /// Sets minimum file size in KB.
  FileUpload minSize(int sizeKb) {
    _minSize = sizeKb;
    return this;
  }

  /// Gets the minimum size in KB.
  int? getMinSize() => _minSize;

  /// Enables multiple file uploads.
  FileUpload multiple([bool multiple = true]) {
    _multiple = multiple;
    return this;
  }

  /// Checks if multiple uploads are enabled.
  bool isMultiple() => _multiple;

  /// Sets maximum number of files for multiple uploads.
  FileUpload maxFiles(int count) {
    _maxFiles = count;
    return this;
  }

  /// Gets maximum files count.
  int? getMaxFiles() => _maxFiles;

  /// Sets minimum number of files for multiple uploads.
  FileUpload minFiles(int count) {
    _minFiles = count;
    return this;
  }

  /// Gets minimum files count.
  int? getMinFiles() => _minFiles;

  /// Sets file visibility.
  ///
  /// Use 'public' for publicly accessible files or 'private' for protected files.
  FileUpload visibility(String visibility) {
    _visibility = visibility;
    return this;
  }

  /// Gets the visibility setting.
  String? getVisibility() => _visibility;

  /// Preserves original filenames when storing.
  ///
  /// By default, files are renamed with ULIDs for uniqueness.
  FileUpload preserveFilenames([bool preserve = true]) {
    _preserveFilenames = preserve;
    return this;
  }

  /// Checks if filenames should be preserved.
  bool shouldPreserveFilenames() => _preserveFilenames;

  /// Restricts uploads to images only.
  ///
  /// Shorthand for `acceptedFileTypes(['image/*'])`.
  FileUpload image([bool isImage = true]) {
    _isImage = isImage;
    if (isImage) {
      _acceptedFileTypes = ['image/*'];
    }
    return this;
  }

  /// Checks if this is an image-only upload.
  bool isImage() => _isImage;

  /// Enables avatar mode (circular image display).
  ///
  /// Automatically enables image mode and sets a 1:1 crop ratio.
  FileUpload avatar([bool isAvatar = true]) {
    _isAvatar = isAvatar;
    if (isAvatar) {
      _isImage = true;
      _acceptedFileTypes = ['image/*'];
      _imageCropAspectRatio = '1:1';
      _panelLayout = 'compact';
    }
    return this;
  }

  /// Checks if avatar mode is enabled.
  bool isAvatar() => _isAvatar;

  /// Enables file reordering for multiple uploads.
  FileUpload reorderable([bool reorderable = true]) {
    _isReorderable = reorderable;
    return this;
  }

  /// Checks if reordering is enabled.
  bool isReorderable() => _isReorderable;

  /// Enables file download buttons.
  FileUpload downloadable([bool downloadable = true]) {
    _isDownloadable = downloadable;
    return this;
  }

  /// Checks if downloads are enabled.
  bool isDownloadable() => _isDownloadable;

  /// Enables opening files in a new tab.
  FileUpload openable([bool openable = true]) {
    _isOpenable = openable;
    return this;
  }

  /// Checks if files can be opened.
  bool isOpenable() => _isOpenable;

  /// Enables or disables image previews.
  FileUpload previewable([bool previewable = true]) {
    _isPreviewable = previewable;
    return this;
  }

  /// Checks if previews are enabled.
  bool isPreviewable() => _isPreviewable;

  /// Enables or disables file deletion.
  FileUpload deletable([bool deletable = true]) {
    _isDeletable = deletable;
    return this;
  }

  /// Checks if deletion is enabled.
  bool isDeletable() => _isDeletable;

  /// Sets the image crop aspect ratio.
  ///
  /// Example: '16:9', '4:3', '1:1'
  FileUpload imageCropAspectRatio(String ratio) {
    _imageCropAspectRatio = ratio;
    return this;
  }

  /// Gets the crop aspect ratio.
  String? getImageCropAspectRatio() => _imageCropAspectRatio;

  /// Sets the target width for image resizing.
  FileUpload imageResizeTargetWidth(int width) {
    _imageResizeTargetWidth = width;
    return this;
  }

  /// Gets the resize target width.
  int? getImageResizeTargetWidth() => _imageResizeTargetWidth;

  /// Sets the target height for image resizing.
  FileUpload imageResizeTargetHeight(int height) {
    _imageResizeTargetHeight = height;
    return this;
  }

  /// Gets the resize target height.
  int? getImageResizeTargetHeight() => _imageResizeTargetHeight;

  /// Sets the placeholder text for the dropzone.
  FileUpload dropzonePlaceholder(String text) {
    _dropzonePlaceholder = text;
    return this;
  }

  /// Gets the dropzone placeholder.
  String getDropzonePlaceholder() => _dropzonePlaceholder;

  /// Sets the message shown during upload.
  FileUpload uploadingMessage(String message) {
    _uploadingMessage = message;
    return this;
  }

  /// Gets the uploading message.
  String getUploadingMessage() => _uploadingMessage;

  /// Sets the panel layout.
  ///
  /// Options: 'compact', 'grid', 'list'
  FileUpload panelLayout(String layout) {
    _panelLayout = layout;
    return this;
  }

  /// Gets the panel layout.
  String getPanelLayout() => _panelLayout;

  /// Sets the panel aspect ratio.
  ///
  /// Example: '16:9', '4:3', '1:1'
  FileUpload panelAspectRatio(String ratio) {
    _panelAspectRatio = ratio;
    return this;
  }

  /// Gets the panel aspect ratio.
  String? getPanelAspectRatio() => _panelAspectRatio;

  /// Sets whether new files are appended (true) or prepended (false).
  FileUpload appendFiles([bool append = true]) {
    _appendFiles = append;
    return this;
  }

  /// Checks if files should be appended.
  bool shouldAppendFiles() => _appendFiles;

  /// Generates the accept attribute string for the file input.
  String? _getAcceptAttribute() {
    if (_acceptedFileTypes == null || _acceptedFileTypes!.isEmpty) {
      return null;
    }
    return _acceptedFileTypes!.join(',');
  }

  @override
  Component build(BuildContext context) {
    final inputId = getId();
    final fieldName = getName();
    final currentValue = getDefaultValue();

    // Build file info for existing file(s)
    List<Map<String, dynamic>> existingFiles = [];
    if (currentValue != null) {
      if (_multiple && currentValue is List) {
        existingFiles = currentValue.map(_parseFileValue).toList();
      } else if (currentValue is String && currentValue.isNotEmpty) {
        existingFiles = [_parseFileValue(currentValue)];
      }
    }

    return FormFieldWrapper(
      extraClasses: getExtraClasses(),
      children: [
        // Label
        if (getLabel().isNotEmpty)
          FormLabel(labelText: getLabel(), forId: inputId, required: isRequired(), hint: getHint()),

        // File upload container with Alpine.js
        div(
          classes: 'file-upload-container',
          attributes: {'x-data': _buildAlpineData(inputId, fieldName, existingFiles)},
          [
            // Hidden input(s) for form submission - using raw for template
            if (_multiple)
              raw(
                '<template x-for="file in files" :key="file.id"><input type="hidden" :name="\'$fieldName[]\'" :value="file.path"></template>',
              )
            else
              input(
                type: InputType.hidden,
                name: fieldName,
                attributes: {':value': "files.length > 0 ? files[0].path : ''"},
              ),

            // Dropzone
            div(
              classes: _buildDropzoneClasses(),
              attributes: {
                'x-on:click': r'if (!disabled) $refs.fileInput.click()',
                'x-on:drop.prevent': r'handleDrop($event)',
                'x-on:dragover.prevent': 'dragging = true',
                'x-on:dragleave': 'dragging = false',
                ':class': "{'border-lime-500 bg-lime-500/10': dragging, 'opacity-50 cursor-not-allowed': disabled}",
              },
              [
                // Upload icon
                div(classes: 'flex justify-center mb-3', [
                  const Heroicon(HeroIcons.cloudArrowUp, size: 40, color: 'text-gray-400'),
                ]),

                // Placeholder text
                p(
                  classes: 'text-sm text-gray-400 text-center',
                  attributes: {'x-show': '!uploading'},
                  [text(_dropzonePlaceholder)],
                ),

                // Uploading indicator
                div(
                  classes: 'text-center',
                  attributes: {'x-show': 'uploading', 'x-cloak': ''},
                  [
                    div(classes: 'flex items-center justify-center gap-2 text-sm text-lime-500', [
                      const Heroicon(HeroIcons.arrowPath, size: 20, className: 'animate-spin'),
                      span([text(_uploadingMessage)]),
                    ]),
                    // Progress bar
                    div(classes: 'mt-2 h-1 bg-gray-700 rounded overflow-hidden', [
                      div(
                        classes: 'h-full bg-lime-500 transition-all duration-200',
                        attributes: {':style': r'`width: ${progress}%`'},
                        [],
                      ),
                    ]),
                  ],
                ),

                // Hidden file input
                input(
                  type: InputType.file,
                  classes: 'hidden',
                  attributes: {
                    'x-ref': 'fileInput',
                    'x-on:change': r'handleFileSelect($event)',
                    if (_getAcceptAttribute() != null) 'accept': _getAcceptAttribute()!,
                    if (_multiple) 'multiple': '',
                    if (isDisabled()) 'disabled': '',
                  },
                ),
              ],
            ),

            // Error message
            div(
              classes: 'mt-2 text-sm text-red-500',
              attributes: {'x-show': 'error', 'x-text': 'error', 'x-cloak': ''},
              [],
            ),

            // File preview(s) - using raw HTML for Alpine.js template
            _buildFilePreviewTemplate(fieldName),
          ],
        ),

        // Helper text
        if (getHelperText() != null) FormHelperText(helperText: getHelperText()!),
      ],
    );
  }

  /// Builds the file preview template section with Alpine.js templating.
  Component _buildFilePreviewTemplate(String fieldName) {
    final downloadButton = _isDownloadable
        ? '''
<button type="button" class="p-1.5 text-gray-400 hover:text-gray-200 rounded hover:bg-gray-700" x-on:click.stop="window.open(file.url, '_blank')" title="Download">
  $_downloadIconSvg
</button>'''
        : '';

    final deleteButton = (_isDeletable && !isDisabled())
        ? '''
<button type="button" class="p-1.5 text-gray-400 hover:text-red-500 rounded hover:bg-gray-700" x-on:click.stop="removeFile(file.id)" title="Remove">
  $_closeIconSvg
</button>'''
        : '';

    return raw('''
<div class="mt-3 space-y-2" x-show="files.length > 0">
  <template x-for="file in files" :key="file.id">
    <div class="flex items-center gap-3 p-3 bg-gray-800/50 border border-gray-700 rounded-lg group">
      <div class="flex-shrink-0 w-12 h-12 rounded overflow-hidden bg-gray-700">
        <template x-if="file.isImage">
          <img class="w-full h-full object-cover" :src="file.previewUrl || file.url" :alt="file.name">
        </template>
        <template x-if="!file.isImage">
          <div class="w-full h-full flex items-center justify-center text-gray-400">
            $_fileIconSvg
          </div>
        </template>
      </div>
      <div class="flex-1 min-w-0">
        <p class="text-sm font-medium text-gray-200 truncate" x-text="file.name"></p>
        <p class="text-xs text-gray-500" x-text="formatFileSize(file.size)"></p>
      </div>
      <div class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
        $downloadButton
        $deleteButton
      </div>
    </div>
  </template>
</div>
''');
  }

  /// Builds Alpine.js data object for the component.
  String _buildAlpineData(String inputId, String fieldName, List<Map<String, dynamic>> existingFiles) {
    final filesJson = _encodeJson(existingFiles);
    final config = {
      'maxSize': _maxSize,
      'minSize': _minSize,
      'maxFiles': _maxFiles,
      'multiple': _multiple,
      'acceptedTypes': _acceptedFileTypes,
      'disk': _disk,
      'directory': _directory,
      'fieldName': fieldName,
    };
    final configJson = _encodeJson(config);

    return '''fileUpload({
      fieldName: '$fieldName',
      files: $filesJson,
      config: $configJson,
      disabled: ${isDisabled()}
    })''';
  }

  /// Builds CSS classes for the dropzone.
  String _buildDropzoneClasses() {
    final classes = [
      'w-full',
      'border-2',
      'border-dashed',
      'border-gray-600',
      'rounded-lg',
      'p-6',
      'text-center',
      'cursor-pointer',
      'transition-colors',
      'hover:border-gray-500',
    ];

    if (_isAvatar) {
      classes.addAll(['w-32', 'h-32', 'rounded-full', 'mx-auto', 'flex', 'items-center', 'justify-content']);
    }

    return classes.join(' ');
  }

  /// Parses a file value into structured data.
  Map<String, dynamic> _parseFileValue(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    // Assume it's a file path string
    final path = value.toString();
    final name = path.split('/').last;
    final extension = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp'].contains(extension);

    // Build URL using the service locator helper (respects panel base path)
    final url = getStorageUrl(path, disk: _disk);

    return {'id': path.hashCode.toString(), 'name': name, 'path': path, 'url': url, 'isImage': isImage, 'size': 0};
  }

  /// Encodes a value to JSON-like string for Alpine.js.
  String _encodeJson(dynamic value) {
    if (value == null) return 'null';
    if (value is bool) return value.toString();
    if (value is num) return value.toString();
    if (value is String) return "'${value.replaceAll("'", "\\'")}'";
    if (value is List) {
      final items = value.map(_encodeJson).join(', ');
      return '[$items]';
    }
    if (value is Map) {
      final entries = value.entries.map((e) => '${e.key}: ${_encodeJson(e.value)}').join(', ');
      return '{$entries}';
    }
    return 'null';
  }
}
