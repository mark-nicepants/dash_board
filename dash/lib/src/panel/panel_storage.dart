import 'package:dash_board/src/panel/panel_server.dart';
import 'package:dash_board/src/service_locator.dart';
import 'package:dash_board/src/storage/storage.dart';

/// Encapsulates storage configuration and registration for a panel.
class PanelStorageManager {
  StorageConfig? _config;

  /// Whether storage has been configured.
  bool get isConfigured => _config != null;

  /// Stores the provided storage configuration for later use.
  void configure(StorageConfig config) {
    _config = config;
  }

  /// Applies the configured storage settings to the running server.
  void applyToServer(PanelServer server) {
    final config = _config;
    if (config == null) {
      return;
    }

    server.configureStorage(config);

    // Ensure storage manager is available for URL generation and injections.
    if (!inject.isRegistered<StorageManager>()) {
      inject.registerSingleton<StorageManager>(config.createManager());
    }
  }
}
