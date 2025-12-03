import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Abstract storage interface for file operations.
///
/// Provides a consistent API for storing, retrieving, and managing files
/// across different storage backends (local, cloud, etc.).
///
/// Example:
/// ```dart
/// final storage = LocalStorage('/var/www/app/storage');
/// await storage.put('avatars/user-1.jpg', fileBytes);
/// final url = storage.url('avatars/user-1.jpg');
/// ```
abstract class Storage {
  /// Stores file data at the given path.
  ///
  /// Returns the stored file path.
  Future<String> put(String filePath, Uint8List data);

  /// Stores a file from an IO File object.
  ///
  /// Returns the stored file path.
  Future<String> putFile(String filePath, File file);

  /// Retrieves file data from the given path.
  Future<Uint8List?> get(String filePath);

  /// Checks if a file exists at the given path.
  Future<bool> exists(String filePath);

  /// Deletes a file at the given path.
  Future<bool> delete(String filePath);

  /// Gets the URL for accessing a file.
  String url(String filePath);

  /// Gets the full path for a file.
  String path(String filePath);

  /// Gets the size of a file in bytes.
  Future<int?> size(String filePath);

  /// Gets the MIME type of a file.
  Future<String?> mimeType(String filePath);

  /// Creates a temporary URL for private files.
  ///
  /// Some storage backends support time-limited URLs for private files.
  /// Falls back to regular URL if not supported.
  Future<String> temporaryUrl(String filePath, Duration expiration) async {
    return url(filePath);
  }

  /// Gets the visibility of a file ('public' or 'private').
  Future<String> getVisibility(String filePath);

  /// Sets the visibility of a file.
  Future<void> setVisibility(String filePath, String visibility);
}

/// Local filesystem storage implementation.
///
/// Stores files on the local disk with configurable base path and URL prefix.
///
/// Example:
/// ```dart
/// final storage = LocalStorage(
///   basePath: '/var/www/app/storage/uploads',
///   urlPrefix: '/uploads',
/// );
/// ```
class LocalStorage extends Storage {
  /// The base path on disk where files are stored.
  final String basePath;

  /// The URL prefix for generating file URLs.
  final String urlPrefix;

  /// Default visibility for new files.
  final String defaultVisibility;

  LocalStorage({required this.basePath, this.urlPrefix = '/storage', this.defaultVisibility = 'public'});

  @override
  Future<String> put(String filePath, Uint8List data) async {
    final fullPath = p.join(basePath, filePath);
    final file = File(fullPath);

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    // Write the file
    await file.writeAsBytes(data);

    return filePath;
  }

  @override
  Future<String> putFile(String sourcePath, File sourceFile) async {
    final data = await sourceFile.readAsBytes();
    return put(sourcePath, data);
  }

  @override
  Future<Uint8List?> get(String filePath) async {
    final fullPath = p.join(basePath, filePath);
    final file = File(fullPath);

    if (await file.exists()) {
      return await file.readAsBytes();
    }
    return null;
  }

  @override
  Future<bool> exists(String filePath) async {
    final fullPath = p.join(basePath, filePath);
    return File(fullPath).exists();
  }

  @override
  Future<bool> delete(String filePath) async {
    final fullPath = p.join(basePath, filePath);
    final file = File(fullPath);

    if (await file.exists()) {
      await file.delete();
      return true;
    }
    return false;
  }

  @override
  String url(String filePath) {
    // Normalize path separators for URL
    final normalizedPath = filePath.replaceAll('\\', '/');
    return '$urlPrefix/$normalizedPath';
  }

  @override
  String path(String filePath) {
    return p.join(basePath, filePath);
  }

  @override
  Future<int?> size(String filePath) async {
    final fullPath = p.join(basePath, filePath);
    final file = File(fullPath);

    if (await file.exists()) {
      return await file.length();
    }
    return null;
  }

  @override
  Future<String?> mimeType(String filePath) async {
    final extension = p.extension(filePath).toLowerCase();

    return _mimeTypes[extension] ?? 'application/octet-stream';
  }

  @override
  Future<String> getVisibility(String filePath) async {
    // Local storage doesn't have true visibility control
    // This could be enhanced to use file permissions
    return defaultVisibility;
  }

  @override
  Future<void> setVisibility(String filePath, String visibility) async {
    // Local storage visibility is controlled by web server config
    // This is a no-op for local storage
  }

  /// Common MIME type mappings.
  static const _mimeTypes = <String, String>{
    '.jpg': 'image/jpeg',
    '.jpeg': 'image/jpeg',
    '.png': 'image/png',
    '.gif': 'image/gif',
    '.webp': 'image/webp',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.bmp': 'image/bmp',
    '.pdf': 'application/pdf',
    '.doc': 'application/msword',
    '.docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    '.xls': 'application/vnd.ms-excel',
    '.xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    '.ppt': 'application/vnd.ms-powerpoint',
    '.pptx': 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    '.txt': 'text/plain',
    '.csv': 'text/csv',
    '.json': 'application/json',
    '.xml': 'application/xml',
    '.zip': 'application/zip',
    '.rar': 'application/x-rar-compressed',
    '.tar': 'application/x-tar',
    '.gz': 'application/gzip',
    '.mp3': 'audio/mpeg',
    '.wav': 'audio/wav',
    '.ogg': 'audio/ogg',
    '.mp4': 'video/mp4',
    '.avi': 'video/x-msvideo',
    '.mov': 'video/quicktime',
    '.webm': 'video/webm',
  };
}

/// Storage manager for managing multiple storage disks.
///
/// Allows configuring and accessing different storage backends by name.
///
/// Example:
/// ```dart
/// final manager = StorageManager();
/// manager.registerDisk('local', LocalStorage('/storage/app'));
/// manager.registerDisk('public', LocalStorage('/storage/public', urlPrefix: '/storage'));
///
/// final disk = manager.disk('public');
/// await disk.put('avatar.jpg', bytes);
/// ```
class StorageManager {
  final Map<String, Storage> _disks = {};
  String _defaultDisk = 'local';

  /// Registers a storage disk.
  void registerDisk(String name, Storage storage) {
    _disks[name] = storage;
  }

  /// Sets the default disk name.
  void setDefaultDisk(String name) {
    _defaultDisk = name;
  }

  /// Gets a storage disk by name.
  ///
  /// Returns the default disk if name is null.
  Storage disk([String? name]) {
    final diskName = name ?? _defaultDisk;
    final storage = _disks[diskName];

    if (storage == null) {
      throw StateError('Storage disk "$diskName" is not registered');
    }

    return storage;
  }

  /// Gets the default storage disk.
  Storage get defaultDisk => disk();

  /// Checks if a disk is registered.
  bool hasDisk(String name) => _disks.containsKey(name);

  /// Gets all registered disk names.
  List<String> get diskNames => _disks.keys.toList();
}

/// Storage configuration for the panel.
///
/// Configures storage disks and default settings.
///
/// By default, the following disks are registered if not explicitly configured:
/// - `public`: For publicly accessible files (uploads, images, etc.)
/// - `logs`: For application log files
///
/// Example:
/// ```dart
/// final config = StorageConfig(
///   defaultDisk: 'public',
///   basePath: 'storage',
///   panelPath: '/admin',
///   disks: {
///     'local': LocalStorage(basePath: 'storage/app'),
///     'public': LocalStorage(basePath: 'storage/public', urlPrefix: '/storage'),
///   },
/// );
/// ```
class StorageConfig {
  /// The default disk to use.
  final String defaultDisk;

  /// Configured storage disks.
  final Map<String, Storage> disks;

  /// The base storage path (used for default disk creation).
  final String basePath;

  /// The panel path (used for URL prefix generation).
  final String panelPath;

  StorageConfig({
    this.defaultDisk = 'public',
    this.disks = const {},
    this.basePath = 'storage',
    this.panelPath = '/admin',
  });

  /// Creates a StorageManager from this configuration.
  ///
  /// Automatically registers default disks (public, logs) if not explicitly configured.
  StorageManager createManager() {
    final manager = StorageManager();

    // Register explicitly configured disks
    for (final entry in disks.entries) {
      manager.registerDisk(entry.key, entry.value);
    }

    // Register default 'public' disk if not configured
    if (!disks.containsKey('public')) {
      manager.registerDisk(
        'public',
        LocalStorage(basePath: '$basePath/public', urlPrefix: '$panelPath/storage/public'),
      );
    }

    // Register default 'logs' disk if not configured
    if (!disks.containsKey('logs')) {
      manager.registerDisk('logs', LocalStorage(basePath: '$basePath/logs', urlPrefix: '$panelPath/storage/logs'));
    }

    manager.setDefaultDisk(defaultDisk);
    return manager;
  }
}
