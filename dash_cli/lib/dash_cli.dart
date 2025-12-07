/// Dash CLI - Command-line tools for Dash admin panel framework.
///
/// This library provides a comprehensive set of CLI commands for:
/// - Code generation (models, resources)
/// - Database management (schema inspection, seeding, record creation)
/// - Server monitoring (logs, status)
/// - MCP server for LLM integration
library;

// Re-export database connector from Dash
export 'package:dash_board/dash_board.dart' show DatabaseConnector, DatabaseConnectorCli, DatabaseConnectorType, SqliteConnector;

// Base command infrastructure
export 'src/commands/base_command.dart';
export 'src/commands/completion_command.dart';
export 'src/commands/completion_configuration.dart';
// Commands
export 'src/commands/db_clear_command.dart';
export 'src/commands/db_create_command.dart';
export 'src/commands/db_schema_command.dart';
export 'src/commands/db_seed_command.dart';
export 'src/commands/dcli_argument.dart';
export 'src/commands/generate_models_command.dart';
export 'src/commands/mcp_server_command.dart';
export 'src/commands/server_log_command.dart';
export 'src/commands/server_status_command.dart';
export 'src/utils/config_loader.dart';
// Utilities
export 'src/utils/console_utils.dart';
export 'src/utils/field_generator.dart';
export 'src/utils/password_utils.dart';
