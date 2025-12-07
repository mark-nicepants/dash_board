import 'dart:async';
import 'dart:io';

import 'package:dash_board/src/service_locator.dart';
import 'package:dash_board/src/storage/storage.dart';

/// Handles writing logs to a file with a queue to prevent concurrent writes.
class LogWriter {
  final DateTime _startTime;
  IOSink? _sink;
  final _queue = <String>[];
  bool _isWriting = false;
  File? _logFile;

  bool _initialized = false;

  LogWriter() : _startTime = DateTime.now();

  /// Initializes the log file.
  Future<void> init() async {
    if (_initialized) return;

    if (!inject.isRegistered<StorageManager>()) {
      return;
    }

    final storage = inject<StorageManager>();
    if (!storage.hasDisk('logs')) {
      return;
    }

    final logsDisk = storage.disk('logs');
    final fileName = _getLogFileName(_startTime);
    final filePath = logsDisk.path(fileName);
    _logFile = File(filePath);

    final dir = _logFile!.parent;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    _sink = _logFile!.openWrite(mode: FileMode.append);
    _initialized = true;
  }

  /// Writes a message to the log file.
  void write(String message) {
    _queue.add(message);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (!_initialized) {
      await init();
      if (!_initialized) {
        // Still not initialized (e.g. StorageManager not ready or no logs disk)
        // We can't write, but we should probably keep the queue or drop it?
        // If we drop it, we lose logs.
        // If we keep it, it might grow indefinitely if StorageManager never comes.
        // Let's try to init again next time.
        // But we should stop processing this time.
        return;
      }
    }

    if (_isWriting || _sink == null || _queue.isEmpty) {
      return;
    }

    _isWriting = true;
    try {
      while (_queue.isNotEmpty) {
        final message = _queue.removeAt(0);
        _sink!.write(message);
      }
      await _sink!.flush();
    } catch (e) {
      // Ignore errors
    } finally {
      _isWriting = false;
      // Check if more items were added while writing
      if (_queue.isNotEmpty) {
        _processQueue();
      }
    }
  }

  /// Generates the log file name based on the start time.
  ///
  /// Format: `dash_YYYYMMDD_HHMMSS.log`
  String _getLogFileName(DateTime timestamp) {
    final year = timestamp.year.toString();
    final month = timestamp.month.toString().padLeft(2, '0');
    final day = timestamp.day.toString().padLeft(2, '0');
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final second = timestamp.second.toString().padLeft(2, '0');
    return 'dash_$year$month${day}_$hour$minute$second.log';
  }

  /// Closes the log writer.
  Future<void> close() async {
    await _sink?.close();
    _sink = null;
  }
}
