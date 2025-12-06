# Dash CLI

Command-line interface for the Dash admin panel framework. Provides model generation, database management, and server monitoring tools.

## Installation

```bash
# From within your Dash project
dart pub global activate --source path ./dash_cli

# Or install the executable directly
cd dash_cli && dart pub get
```

### Development Setup

When developing the Dash CLI itself, you'll need to install it globally from source. This is only required when not pulling from pub.dev.

```bash
# From the dash_cli directory
dart pub global activate --source path .

# Or build the executable manually
dart build cli
```

The global activation will automatically compile the CLI to a native executable, avoiding dependency resolution output that can interfere with MCP server communication.

### MCP Server Setup

The Dash CLI includes an MCP (Model Context Protocol) server for LLM integration, providing tools to interact with a running Dash server.

#### For Development (when not using pub.dev)

1. **Install globally from source:**
   ```bash
   cd dash_cli
   dart pub global activate --source path .
   ```

2. **Create MCP configuration** in your VS Code workspace (`.vscode/mcp.json`):
   ```json
   {
     "servers": {
       "dash": {
         "command": "/Users/mark/Developer/web/dash_board/dash_cli/build/cli/macos_arm64/bundle/bin/dcli",
         "args": ["mcp-server"]
       }
     }
   }
   ```

#### For Production (when installed from pub.dev)

When installed from pub.dev, the MCP server is automatically compiled and ready to use:

```json
{
  "servers": {
    "dash": {
      "command": "dcli",
      "args": ["mcp-server"]
    }
  }
}
```

#### MCP Server Features

The MCP server provides these tools for LLMs:
- `get_server_status` - Check server health and uptime
- `get_registered_resources` - List admin panel resources
- `get_request_logs` - Query HTTP request logs
- `get_sql_logs` - Query database query logs
- `get_exceptions` - View error logs with stack traces
- `get_all_logs` - Combined log querying
- `get_slow_requests` - Find performance bottlenecks
- `get_slow_queries` - Identify slow database queries
- `generate_models` - Generate Dart models from YAML schemas

**Usage:**
```bash
# Start MCP server (usually handled by VS Code)
dcli mcp-server --url http://localhost:8080 --path /admin
```

## Usage

```bash
dcli <command> [arguments]
```

## Available Commands

### Code Generation

#### `generate:models`

Generate Dart model and resource classes from schema YAML files.

```bash
# Generate models from default location (schemas/models -> lib)
dcli generate:models

# Specify custom paths
dcli generate:models -s path/to/schemas -o lib/src

# Verbose output
dcli generate:models -v

# Force overwrite existing resource files
dcli generate:models --force
```

**Options:**
- `-s, --schemas` - Path to directory containing schema YAML files (default: `schemas/models`)
- `-o, --output` - Output directory for generated code (default: `lib`)
- `-f, --force` - Overwrite existing resource files
- `-v, --verbose` - Show detailed output

**Generated Files:**
- `models/{model}.model.dart` - Active Record model classes
- `models/{model}.model.g.dart` - Generated serialization code
- `resources/{model}_resource.dart` - Admin panel resource classes
- `models/models.dart` - Barrel export file

### Database Commands

#### `db:schema`

Display database table schemas with column information, indexes, and foreign keys.

```bash
# Show all tables
dcli db:schema

# Specify database path
dcli db:schema -d storage/app.db

# Show specific table only
dcli db:schema -t users

# Compact output (just column names)
dcli db:schema -c
```

**Options:**
- `-d, --database` - Path to SQLite database file (default: `storage/app.db`)
- `-t, --table` - Show only specific table
- `-c, --compact` - Compact output without column details

**Example Output:**
```
📊 Database Schema
──────────────────
users (63 rows)
───────────────────────────────────────────────────────────────────────────
Column                   Type           Null    Primary   Default        
───────────────────────────────────────────────────────────────────────────
id                       INTEGER        YES     ✓ PK                     
name                     TEXT           NO                               
email                    TEXT           NO                               
role                     TEXT           NO                               
  Indexes:
    • sqlite_autoindex_users_1: email (UNIQUE)
```

#### `db:create`

Interactively create a single model record with user input or generated values.

```bash
# Create a user record interactively
dcli db:create User

# Create a post with generated values (non-interactive)
dcli db:create Post --non-interactive

# List available models
dcli db:create --list
```

**Options:**
- Model name (positional) - The model to create a record for
- `-d, --database` - Path to database file (default: `storage/app.db`)
- `-s, --schemas` - Path to schema YAML files (default: `schemas/models`)
- `--non-interactive` - Use generated values without prompting
- `-l, --list` - List available models

**Interactive Mode:**
When run interactively, you'll be prompted to enter values for each field. Press Enter to use default values or generated data.

**Non-Interactive Mode:**
Generates appropriate fake data based on field types (emails, names, content, etc.).

#### `db:seed`

Seed the database with fake data based on model schema.

```bash
# List available models
dcli db:seed --list

# Seed 100 users
dcli db:seed User 100

# Seed with custom schema path
dcli db:seed User 50 -s example/schemas/models

# Verbose output
dcli db:seed User 10 -v
```

**Options:**
- Model name (positional) - The model to seed (e.g., `User`, `Post`)
- Count (positional) - Number of records to create (default: 10)
- `-d, --database` - Path to SQLite database file (default: `storage/app.db`)
- `-s, --schemas` - Path to schema YAML files (default: `schemas/models`)
- `-v, --verbose` - Show detailed output
- `-l, --list` - List available models

**Smart Data Generation:**
The seeder inspects your schema and generates appropriate fake data:
- `email` fields → fake email addresses
- `name` fields → fake names
- `password` fields → bcrypt-like hashes
- `slug` fields → URL-friendly slugs
- `content`/`body` fields → lorem ipsum paragraphs
- `avatar`/`image` fields → placeholder image URLs
- Enum fields → random selection from allowed values
- Boolean fields → context-aware (e.g., `isActive` → 80% true)

#### `db:clear`

Clear all data from database tables (keeps table structure).

```bash
# Clear all tables (with confirmation)
dcli db:clear

# Clear specific table
dcli db:clear -t users

# Skip confirmation
dcli db:clear --force
```

**Options:**
- `-d, --database` - Path to SQLite database file (default: `storage/app.db`)
- `-t, --table` - Clear only specific table
- `-f, --force` - Skip confirmation prompt

**Safety Features:**
- Shows row counts before clearing
- Requires confirmation unless `--force` is used
- Only clears data, preserves table structure and indexes

### Server Commands

#### `server:status`

Display server status and health information.

```bash
# Check default server
dcli server:status

# Check custom server URL
dcli server:status --url http://localhost:3000 --path /admin
```

**Options:**
- `--url` - Server URL (default: `http://localhost:8080`)
- `--path` - Admin panel base path (default: `/admin`)

**Example Output:**
```
📊 Server Status
────────────────

  ● Status:        Running
  ○ Version:       0.1.0
  ○ Response time: 44ms
  ○ Uptime:        5m 30s

Resources
  ○ Resources:     3 registered
  ● Database:      Connected

Registered Resources
  ○ Post (/post)
  ○ Tag (/tag)
  ○ User (/user)
```

#### `server:log`

Stream server logs to the console.

```bash
# Show last 50 log entries
dcli server:log

# Show last N lines
dcli server:log -n 100

# Follow logs in real-time (like tail -f)
dcli server:log -f
```

**Options:**
- `-f, --follow` - Follow log output (like `tail -f`)
- `-n, --lines` - Number of lines to show (default: 50)
- `--url` - Server URL
- `--path` - Admin panel base path

**Log Types:**
- `request` - HTTP requests with method, path, status, and duration
- `query` - Database queries with execution time and row counts
- `error` - Application errors and exceptions
- `info` - General application events

### MCP Server

#### `mcp-server`

Start an MCP (Model Context Protocol) server for LLM integration.

```bash
# Start MCP server with default settings
dcli mcp-server

# Connect to custom server
dcli mcp-server --url http://localhost:3000 --path /admin
```

**Options:**
- `--url` - Server URL (default: `http://localhost:8080`)
- `--path` - Admin panel base path (default: `/admin`)

**Available Tools:**
- `get_server_status` - Check server health and uptime
- `get_registered_resources` - List admin panel resources
- `get_request_logs` - Query HTTP request logs
- `get_sql_logs` - Query database query logs
- `get_exceptions` - View error logs with stack traces
- `get_all_logs` - Combined log querying
- `get_slow_requests` - Find performance bottlenecks
- `get_slow_queries` - Identify slow database queries
- `generate_models` - Generate Dart models from YAML schemas

### Shell Completion

#### `completion`

Generate shell completion scripts for auto-complete support.

```bash
# Generate Zsh completion script
dcli completion zsh

# Install Zsh completion
dcli completion zsh --install

# Generate Bash completion script
dcli completion bash

# Install Bash completion
dcli completion bash --install
```

**Zsh Setup:**
After installing, add to your `~/.zshrc`:
```bash
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
```

Then restart your shell or run `source ~/.zshrc`.

## Server API

The CLI communicates with the Dash server via a REST API. This API is automatically enabled in development mode.

**Endpoints:**
- `GET /_cli/status` - Server status and health information
- `GET /_cli/logs` - Query log entries
- `GET /_cli/health` - Simple health check

To disable the CLI API in production, set the environment variable:
```bash
DASH_ENV=production dart run your_app.dart
```

## Configuration

The CLI looks for configuration in the following order:
1. `dash.yaml` in current directory
2. `schemas/panel.yaml`
3. `pubspec.yaml` (under `dash:` key)
4. Command-line arguments (highest priority)

**Example `dash.yaml`:**
```yaml
database:
  path: storage/app.db

schemas:
  path: schemas/models

output:
  path: lib

server:
  url: http://localhost
  port: 8080
  basePath: /admin
```

## Examples

### Setting up a new project

```bash
# Generate models from schema files
dcli generate:models -s schemas/models -o lib

# Seed initial test data
dcli db:seed User 10
dcli db:seed Post 50

# Check schema
dcli db:schema
```

### Development workflow

```bash
# Terminal 1: Run the server
dart run lib/main.dart

# Terminal 2: Monitor logs
dcli server:log -f

# Terminal 3: Check status
dcli server:status
```

### Database management

```bash
# View all tables and their structure
dcli db:schema

# View specific table
dcli db:schema -t users

# Create a single record interactively
dcli db:create User

# Seed test data
dcli db:seed User 100 -v

# Clear and reseed
dcli db:clear -t users --force
dcli db:seed User 50
```

## Troubleshooting

### "Schemas directory not found"
Specify the correct path to your schema files:
```bash
dcli generate:models -s path/to/schemas
```

### "Database not found"
The database file doesn't exist. Make sure your Dash server has been started at least once to create the database.

### "Cannot connect to server"
The server must be running for `server:status` and `server:log` commands. Start it with:
```bash
dart run lib/main.dart
```

### "CLI API not enabled"
The CLI API is disabled in production mode. For local testing, ensure `DASH_ENV` is not set to `production`.

## License

MIT License - See LICENSE file for details.
