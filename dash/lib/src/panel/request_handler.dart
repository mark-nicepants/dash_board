import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dash_board/src/auth/auth_service.dart';
import 'package:dash_board/src/auth/session_helper.dart';
import 'package:dash_board/src/cli/cli_logger.dart';
import 'package:dash_board/src/model/model.dart';
import 'package:dash_board/src/panel/panel_config.dart';
import 'package:dash_board/src/storage/file_upload_validator.dart';
import 'package:dash_board/src/storage/storage.dart';
import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';

/// Handles specific HTTP requests for authentication and special routes.
///
/// Processes login, logout, file uploads, and other custom request types
/// that require special handling beyond basic page rendering.
class RequestHandler {
  final PanelConfig _config;
  final AuthService<Model> _authService;

  /// Storage manager for file uploads.
  StorageManager? _storageManager;

  RequestHandler(this._config, this._authService);

  /// Sets the storage manager for file uploads.
  void setStorageManager(StorageManager manager) {
    _storageManager = manager;
  }

  /// Handles custom requests (login POST, logout, file upload, etc.).
  ///
  /// Returns a Response if the request is handled, or a 404 if not.
  FutureOr<Response> handle(Request request) async {
    final path = request.url.path;
    final baseSegment = _config.path.startsWith('/') ? _config.path.substring(1) : _config.path;

    // Handle login POST
    if (path == '$baseSegment/login' && request.method == 'POST') {
      return await _handleLogin(request);
    }

    // Handle logout
    if (path == '$baseSegment/logout') {
      return _handleLogout(request);
    }

    // Handle file upload
    if (path == '$baseSegment/upload' && request.method == 'POST') {
      return await _handleFileUpload(request);
    }

    return Response.notFound('Not found');
  }

  /// Handles login POST request.
  Future<Response> _handleLogin(Request request) async {
    final body = await request.readAsString();

    // Parse form data
    final params = Uri.splitQueryString(body);
    final email = params['email'];
    final password = params['password'];

    if (email == null || password == null) {
      return Response.found('${_config.path}/login?error=missing_credentials');
    }

    // Attempt login
    final sessionId = await _authService.login(email, password);
    if (sessionId == null) {
      return Response.found('${_config.path}/login?error=invalid_credentials');
    }

    // Set session cookie and redirect to dashboard
    return Response.found(_config.path, headers: {'set-cookie': SessionHelper.createSessionCookie(sessionId)});
  }

  /// Handles logout request.
  Response _handleLogout(Request request) {
    // Get session ID from cookie and logout
    final sessionId = SessionHelper.parseSessionId(request);
    if (sessionId != null) {
      _authService.logout(sessionId);
    }

    // Clear cookie and redirect to login
    return Response.found('${_config.path}/login', headers: {'set-cookie': SessionHelper.clearSessionCookie()});
  }

  /// Handles file upload via multipart form data.
  ///
  /// Validates uploaded files for:
  /// - File size limits
  /// - Allowed/blocked file extensions
  /// - MIME type validation
  /// - Filename sanitization
  ///
  /// Security measures:
  /// - Blocks executable and script files
  /// - Prevents double extension attacks
  /// - Sanitizes filenames to prevent path traversal
  /// - Generates unique filenames for storage
  Future<Response> _handleFileUpload(Request request) async {
    try {
      // Check if storage is configured
      if (_storageManager == null) {
        return _jsonError('Storage not configured', 500);
      }

      // Parse multipart form data
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('multipart/form-data')) {
        return _jsonError('Invalid content type. Expected multipart/form-data', 400);
      }

      // Extract boundary from content type
      final boundaryMatch = RegExp(r'boundary=(.+)$').firstMatch(contentType);
      if (boundaryMatch == null) {
        return _jsonError('Missing boundary in content type', 400);
      }
      final boundary = boundaryMatch.group(1)!;

      // Read the body as bytes
      final bodyBytes = await request.read().expand((chunk) => chunk).toList();
      final body = Uint8List.fromList(bodyBytes);

      // Parse multipart data
      final parts = _parseMultipart(body, boundary);

      // Extract file and form fields
      Uint8List? fileData;
      String? fileName;
      String? fileType;
      String? diskName;
      String? directory;
      String? uploadType;
      int? maxSizeKb;
      List<String>? acceptedTypes;

      for (final part in parts) {
        if (part.filename != null) {
          fileData = part.data;
          fileName = part.filename;
          fileType = part.contentType;
        } else if (part.name == 'disk') {
          diskName = String.fromCharCodes(part.data);
        } else if (part.name == 'directory') {
          directory = String.fromCharCodes(part.data);
        } else if (part.name == 'uploadType') {
          uploadType = String.fromCharCodes(part.data);
        } else if (part.name == 'maxSize') {
          maxSizeKb = int.tryParse(String.fromCharCodes(part.data));
        } else if (part.name == 'acceptedTypes') {
          acceptedTypes = String.fromCharCodes(part.data).split(',').map((t) => t.trim()).toList();
        }
      }

      if (fileData == null || fileName == null) {
        return _jsonError('No file provided', 400);
      }

      // Build validation configuration based on upload type and field settings
      final validationConfig = _buildValidationConfig(
        uploadType: uploadType,
        maxSizeKb: maxSizeKb,
        acceptedTypes: acceptedTypes,
      );

      // Validate the file
      final validationError = validationConfig.validate(fileData, fileName, fileType);
      if (validationError != null) {
        return _jsonError(validationError, 400);
      }

      // Sanitize the filename
      final sanitizedName = sanitizeFilename(fileName);

      // Get storage disk
      final storage = _storageManager!.disk(diskName);

      // Generate unique filename with sanitized original name
      final extension = p.extension(sanitizedName);
      final uniqueId = _generateUniqueId();
      final storedFileName = '$uniqueId$extension';

      // Build storage path
      final storagePath = directory != null ? '$directory/$storedFileName' : storedFileName;

      // Store the file
      await storage.put(storagePath, fileData);

      // Return success response
      final url = storage.url(storagePath);
      return Response.ok(
        jsonEncode({
          'id': uniqueId,
          'name': sanitizedName,
          'originalName': fileName,
          'path': storagePath,
          'url': url,
          'size': fileData.length,
          'type': fileType ?? 'application/octet-stream',
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      cliLogException(e);
      return _jsonError('Upload failed. Please try again.', 500);
    }
  }

  /// Builds validation configuration based on upload type and field settings.
  FileUploadValidationConfig _buildValidationConfig({String? uploadType, int? maxSizeKb, List<String>? acceptedTypes}) {
    // Calculate max size in bytes
    final maxSizeBytes = maxSizeKb != null ? maxSizeKb * 1024 : 10 * 1024 * 1024;

    // Use predefined configs for known upload types
    if (uploadType == 'image') {
      return FileUploadValidationConfig.images(maxFileSizeBytes: maxSizeBytes);
    } else if (uploadType == 'document') {
      return FileUploadValidationConfig.documents(maxFileSizeBytes: maxSizeBytes);
    }

    // Build custom config from field settings
    final List<String> allowedExtensions = [];
    final List<String> allowedMimeTypes = [];

    if (acceptedTypes != null && acceptedTypes.isNotEmpty) {
      for (final type in acceptedTypes) {
        if (type.contains('/')) {
          // It's a MIME type
          allowedMimeTypes.add(type);
          // Also extract extensions from common MIME types
          allowedExtensions.addAll(_mimeTypeToExtensions(type));
        } else if (type.startsWith('.')) {
          // It's an extension
          allowedExtensions.add(type.substring(1).toLowerCase());
        } else {
          // Assume it's an extension without dot
          allowedExtensions.add(type.toLowerCase());
        }
      }
    }

    return FileUploadValidationConfig(
      maxFileSizeBytes: maxSizeBytes,
      allowedExtensions: allowedExtensions,
      allowedMimeTypes: allowedMimeTypes,
    );
  }

  /// Maps MIME types to common file extensions.
  List<String> _mimeTypeToExtensions(String mimeType) {
    final mapping = {
      'image/jpeg': ['jpg', 'jpeg'],
      'image/png': ['png'],
      'image/gif': ['gif'],
      'image/webp': ['webp'],
      'image/svg+xml': ['svg'],
      'image/*': ['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'ico', 'bmp'],
      'application/pdf': ['pdf'],
      'application/msword': ['doc'],
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document': ['docx'],
      'application/vnd.ms-excel': ['xls'],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': ['xlsx'],
      'text/plain': ['txt'],
      'text/csv': ['csv'],
    };

    return mapping[mimeType] ?? [];
  }

  /// Parses multipart form data.
  List<_MultipartPart> _parseMultipart(Uint8List body, String boundary) {
    final parts = <_MultipartPart>[];
    final boundaryBytes = '--$boundary'.codeUnits;

    // Find all boundary positions
    final positions = <int>[];
    for (var i = 0; i <= body.length - boundaryBytes.length; i++) {
      var matches = true;
      for (var j = 0; j < boundaryBytes.length; j++) {
        if (body[i + j] != boundaryBytes[j]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        positions.add(i);
      }
    }

    // Parse each part
    for (var i = 0; i < positions.length - 1; i++) {
      final start = positions[i] + boundaryBytes.length;
      final end = positions[i + 1];

      // Skip CRLF after boundary
      var dataStart = start;
      while (dataStart < end && (body[dataStart] == 13 || body[dataStart] == 10)) {
        dataStart++;
      }

      // Find end of headers (double CRLF)
      var headerEnd = dataStart;
      for (var j = dataStart; j < end - 3; j++) {
        if (body[j] == 13 && body[j + 1] == 10 && body[j + 2] == 13 && body[j + 3] == 10) {
          headerEnd = j;
          break;
        }
      }

      // Parse headers
      final headerBytes = body.sublist(dataStart, headerEnd);
      final headerString = String.fromCharCodes(headerBytes);
      final headers = _parseHeaders(headerString);

      // Get data (after headers + CRLF CRLF, before next boundary - CRLF)
      final contentStart = headerEnd + 4;
      var contentEnd = end;
      // Remove trailing CRLF before next boundary
      while (contentEnd > contentStart && (body[contentEnd - 1] == 13 || body[contentEnd - 1] == 10)) {
        contentEnd--;
      }

      final data = body.sublist(contentStart, contentEnd);

      // Extract name and filename from Content-Disposition
      final contentDisposition = headers['content-disposition'] ?? '';
      final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(contentDisposition);
      final filenameMatch = RegExp(r'filename="([^"]*)"').firstMatch(contentDisposition);

      parts.add(
        _MultipartPart(
          name: nameMatch?.group(1),
          filename: filenameMatch?.group(1),
          contentType: headers['content-type'],
          data: data,
        ),
      );
    }

    return parts;
  }

  /// Parses HTTP headers from a string.
  Map<String, String> _parseHeaders(String headerString) {
    final headers = <String, String>{};
    for (final line in headerString.split(RegExp(r'\r?\n'))) {
      final colonIndex = line.indexOf(':');
      if (colonIndex > 0) {
        final key = line.substring(0, colonIndex).trim().toLowerCase();
        final value = line.substring(colonIndex + 1).trim();
        headers[key] = value;
      }
    }
    return headers;
  }

  /// Generates a unique ID for file storage.
  String _generateUniqueId() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toRadixString(36);
    final random = Random().nextInt(0xFFFFFF).toRadixString(36).padLeft(4, '0');
    return '$timestamp$random';
  }

  /// Creates a JSON error response.
  Response _jsonError(String message, int statusCode) {
    return Response(statusCode, body: jsonEncode({'error': message}), headers: {'content-type': 'application/json'});
  }
}

/// Represents a part of multipart form data.
class _MultipartPart {
  final String? name;
  final String? filename;
  final String? contentType;
  final Uint8List data;

  _MultipartPart({this.name, this.filename, this.contentType, required this.data});
}
