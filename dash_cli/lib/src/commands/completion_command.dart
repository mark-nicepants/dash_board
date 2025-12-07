import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:dash_panel_cli/src/commands/completion_configuration.dart';
import 'package:dash_panel_cli/src/commands/dcli_argument.dart';
import 'package:dash_panel_cli/src/utils/console_utils.dart';

/// Generate shell completion scripts.
///
/// Usage:
///   dcli completion [shell]
///
/// Shells:
///   zsh     Generate Zsh completion script
///   bash    Generate Bash completion script
///
/// The completion scripts are generated dynamically based on
/// the CompletionConfiguration of each registered command.
class CompletionCommand extends Command<int> with CompletionConfigurable {
  CompletionCommand() {
    DcliArgument.addToParser(argParser, _arguments);
  }

  /// Unified argument definitions.
  static final _arguments = [
    DcliArgument.positional(name: 'shell', help: 'Shell type (zsh or bash)', completionType: CompletionType.shell),
    DcliArgument.flag(name: 'install', abbr: 'i', help: 'Install the completion script to your shell config'),
  ];

  @override
  final String name = 'completion';

  @override
  final String description = 'Generate shell completion scripts';

  @override
  final String invocation = 'dcli completion [shell]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    final install = argResults!['install'] as bool;

    final shell = rest.isNotEmpty ? rest[0] : _detectShell();

    // Collect completion configs from all commands in the runner
    final configs = _collectCompletionConfigs();

    switch (shell.toLowerCase()) {
      case 'zsh':
        if (install) {
          return await _installZshCompletion(configs);
        }
        print(_generateZshCompletion(configs));
        return 0;

      case 'bash':
        if (install) {
          return await _installBashCompletion(configs);
        }
        print(_generateBashCompletion(configs));
        return 0;

      default:
        ConsoleUtils.error('Unsupported shell: $shell');
        print('');
        print('Supported shells: zsh, bash');
        return 1;
    }
  }

  /// Collect completion configurations from all registered commands.
  List<CompletionConfiguration> _collectCompletionConfigs() {
    final configs = <CompletionConfiguration>[];

    // Get commands from the parent runner if available
    final commands = runner?.commands.values ?? <Command<int>>[];

    for (final command in commands) {
      if (command is CompletionConfigurable) {
        final configurable = command as CompletionConfigurable;
        final config = configurable.getCompletionConfig();
        if (config != null) {
          configs.add(config);
        } else {
          configs.add(
            CompletionConfiguration(name: command.name, description: command.description, aliases: command.aliases),
          );
        }
      } else {
        configs.add(
          CompletionConfiguration(name: command.name, description: command.description, aliases: command.aliases),
        );
      }
    }

    return configs;
  }

  String _detectShell() {
    final shell = Platform.environment['SHELL'] ?? '';
    if (shell.contains('zsh')) return 'zsh';
    if (shell.contains('bash')) return 'bash';
    return 'zsh';
  }

  String _generateZshCompletion(List<CompletionConfiguration> configs) {
    final buffer = StringBuffer();

    buffer.writeln('#compdef dcli');
    buffer.writeln('');
    buffer.writeln('# Dash CLI Zsh Completion');
    buffer.writeln('# Generated dynamically based on registered commands');
    buffer.writeln('# Install: dcli completion zsh > ~/.zsh/completions/_dcli');
    buffer.writeln('# Or: dcli completion zsh --install');
    buffer.writeln('');

    // Command list function - include main names and aliases
    buffer.writeln('_dcli_commands() {');
    buffer.writeln('  local -a commands');
    buffer.writeln('  commands=(');

    // Use a set to avoid duplicates
    final seen = <String>{};
    for (final config in configs) {
      if (!seen.contains(config.name)) {
        seen.add(config.name);
        final escaped = config.name.replaceAll(':', r'\:');
        final descEscaped = _escapeZsh(config.description);
        buffer.writeln("    '$escaped:$descEscaped'");

        // Add aliases
        for (final alias in config.aliases) {
          if (!seen.contains(alias)) {
            seen.add(alias);
            final aliasEscaped = alias.replaceAll(':', r'\:');
            buffer.writeln("    '$aliasEscaped:$descEscaped'");
          }
        }
      }
    }
    buffer.writeln("    'help:Display help for a command'");
    buffer.writeln('  )');
    buffer.writeln("  _describe 'command' commands");
    buffer.writeln('}');
    buffer.writeln('');

    // Model completion function
    buffer.writeln('_dcli_models() {');
    buffer.writeln('  local -a models');
    buffer.writeln('  local schema_dirs=("schemas/models" "schemas" "lib/schemas")');
    buffer.writeln(r'  for dir in "$schema_dirs[@]"; do');
    buffer.writeln(r'    if [[ -d "$dir" ]]; then');
    buffer.writeln(r'      models=(${(f)"$(ls $dir/*.yaml 2>/dev/null | xargs -I {} basename {} .yaml)"})');
    buffer.writeln(r'      if [[ ${#models[@]} -gt 0 ]]; then');
    buffer.writeln("        _describe 'model' models");
    buffer.writeln('        return');
    buffer.writeln('      fi');
    buffer.writeln('    fi');
    buffer.writeln('  done');
    buffer.writeln('}');
    buffer.writeln('');

    // Table completion function
    buffer.writeln('_dcli_tables() {');
    buffer.writeln('  local db_path="storage/app.db"');
    buffer.writeln(r'  if [[ -f "$db_path" ]]; then');
    buffer.writeln('    local -a tables');
    buffer.writeln(
      r'    tables=(${(f)'
      r'"$(sqlite3 $db_path "SELECT name FROM sqlite_master WHERE type='
      r"'table' AND name NOT LIKE 'sqlite_%'"
      r'" 2>/dev/null)"})',
    );
    buffer.writeln("    _describe 'table' tables");
    buffer.writeln('  fi');
    buffer.writeln('}');
    buffer.writeln('');

    // Main completion function
    buffer.writeln('_dcli() {');
    buffer.writeln(r'  local curcontext="$curcontext" state line');
    buffer.writeln('  typeset -A opt_args');
    buffer.writeln('');
    buffer.writeln(r'  _arguments -C \');
    buffer.writeln(r"    '1: :_dcli_commands' \");
    buffer.writeln(r"    '*::arg:->args'");
    buffer.writeln('');
    buffer.writeln(r'  case $state in');
    buffer.writeln('    args)');
    buffer.writeln(r'      case $line[1] in');

    // Generate case for each command (deduplicated)
    final seenCommands = <String>{};
    for (final config in configs) {
      if (!seenCommands.contains(config.name)) {
        seenCommands.add(config.name);
        _generateZshCommandCase(buffer, config);
      }
    }

    buffer.writeln('      esac');
    buffer.writeln('      ;;');
    buffer.writeln('  esac');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln(r'_dcli "$@"');

    return buffer.toString();
  }

  void _generateZshCommandCase(StringBuffer buffer, CompletionConfiguration config) {
    final patterns = [config.name, ...config.aliases].map((n) => n.replaceAll(':', r'\:')).join('|');
    buffer.writeln('        $patterns)');
    buffer.writeln(r'          _arguments \');

    var argIndex = 1;
    for (final arg in config.positionalArgs) {
      final completion = _getZshCompletionForType(arg.type, arg.values, arg.filePattern);
      buffer.writeln("            '$argIndex:${arg.name}:$completion' \\");
      argIndex++;
    }

    for (final opt in config.options) {
      final completion = _getZshCompletionForType(opt.type, opt.values, opt.filePattern);
      final desc = opt.description ?? opt.name;

      if (opt.type == CompletionType.flag) {
        if (opt.abbr != null) {
          buffer.writeln("            '-${opt.abbr}[$desc]' \\");
        }
        buffer.writeln("            '--${opt.name}[$desc]' \\");
      } else {
        if (opt.abbr != null) {
          buffer.writeln("            '-${opt.abbr}[$desc]:${opt.name}:$completion' \\");
        }
        buffer.writeln("            '--${opt.name}[$desc]:${opt.name}:$completion' \\");
      }
    }

    buffer.writeln('          ;;');
  }

  String _getZshCompletionForType(CompletionType type, List<String>? values, String? filePattern) {
    switch (type) {
      case CompletionType.model:
        return '_dcli_models';
      case CompletionType.table:
        return '_dcli_tables';
      case CompletionType.file:
        final pattern = filePattern ?? '*';
        return '_files -g "$pattern"';
      case CompletionType.directory:
        return '_files -/';
      case CompletionType.enumeration:
        if (values != null && values.isNotEmpty) {
          return '(${values.join(' ')})';
        }
        return '';
      case CompletionType.shell:
        return '(zsh bash)';
      case CompletionType.number:
      case CompletionType.flag:
      case CompletionType.string:
      case CompletionType.custom:
        return '';
    }
  }

  String _escapeZsh(String text) {
    return text.replaceAll("'", r"\'").replaceAll(':', r'\:');
  }

  String _generateBashCompletion(List<CompletionConfiguration> configs) {
    final buffer = StringBuffer();

    buffer.writeln('# Dash CLI Bash Completion');
    buffer.writeln('# Generated dynamically based on registered commands');
    buffer.writeln('# Install: dcli completion bash > /etc/bash_completion.d/dcli');
    buffer.writeln('# Or: dcli completion bash >> ~/.bashrc');
    buffer.writeln('');

    buffer.writeln('_dcli_completions() {');
    buffer.writeln('  local cur prev commands');
    buffer.writeln('  COMPREPLY=()');
    buffer.writeln(r'  cur="${COMP_WORDS[COMP_CWORD]}"');
    buffer.writeln(r'  prev="${COMP_WORDS[COMP_CWORD-1]}"');
    buffer.writeln('');

    // Build command names list with aliases, deduplicated
    final allCommands = <String>[];
    final seenNames = <String>{};
    for (final config in configs) {
      if (!seenNames.contains(config.name)) {
        seenNames.add(config.name);
        allCommands.add(config.name);
        for (final alias in config.aliases) {
          if (!seenNames.contains(alias)) {
            seenNames.add(alias);
            allCommands.add(alias);
          }
        }
      }
    }
    final commandNames = allCommands.join(' ');
    buffer.writeln('  commands="$commandNames help"');
    buffer.writeln('');

    buffer.writeln(r'  if [[ ${COMP_CWORD} -eq 1 ]]; then');
    buffer.writeln(r'    COMPREPLY=($(compgen -W "$commands" -- "$cur"))');
    buffer.writeln('    return 0');
    buffer.writeln('  fi');
    buffer.writeln('');

    buffer.writeln(r'  case "${COMP_WORDS[1]}" in');

    // Generate cases for each command (deduplicated)
    final seenCommands = <String>{};
    for (final config in configs) {
      if (!seenCommands.contains(config.name)) {
        seenCommands.add(config.name);
        _generateBashCommandCase(buffer, config);
      }
    }

    buffer.writeln('  esac');
    buffer.writeln('');
    buffer.writeln('  return 0');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln('complete -F _dcli_completions dcli');

    return buffer.toString();
  }

  void _generateBashCommandCase(StringBuffer buffer, CompletionConfiguration config) {
    final patterns = [config.name, ...config.aliases].join('|');
    buffer.writeln('    $patterns)');

    if (config.positionalArgs.isNotEmpty) {
      final firstArg = config.positionalArgs.first;
      buffer.writeln(r'      if [[ ${COMP_CWORD} -eq 2 ]]; then');
      final bashCompletion = _getBashCompletionForType(firstArg.type, firstArg.values);
      buffer.writeln('        $bashCompletion');
      buffer.writeln('      else');
    }

    final optionsList = <String>[];
    for (final opt in config.options) {
      if (opt.abbr != null) optionsList.add('-${opt.abbr}');
      optionsList.add('--${opt.name}');
    }

    if (optionsList.isNotEmpty) {
      final opts = optionsList.join(' ');
      buffer.writeln(
        r'        COMPREPLY=($(compgen -W "'
        '$opts'
        r'" -- "$cur"))',
      );
    }

    if (config.positionalArgs.isNotEmpty) {
      buffer.writeln('      fi');
    }

    buffer.writeln('      ;;');
  }

  String _getBashCompletionForType(CompletionType type, List<String>? values) {
    switch (type) {
      case CompletionType.model:
        return r'''local models=""
        for dir in schemas/models schemas lib/schemas; do
          if [[ -d "$dir" ]]; then
            models=$(ls $dir/*.yaml 2>/dev/null | xargs -I {} basename {} .yaml)
            break
          fi
        done
        COMPREPLY=($(compgen -W "$models" -- "$cur"))''';
      case CompletionType.table:
        return r'''local tables=""
        if [[ -f "storage/app.db" ]]; then
          tables=$(sqlite3 storage/app.db "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'" 2>/dev/null)
        fi
        COMPREPLY=($(compgen -W "$tables" -- "$cur"))''';
      case CompletionType.enumeration:
        if (values != null && values.isNotEmpty) {
          return 'COMPREPLY=(\$(compgen -W "${values.join(' ')}" -- "\$cur"))';
        }
        return '';
      case CompletionType.shell:
        return r'COMPREPLY=($(compgen -W "zsh bash" -- "$cur"))';
      default:
        return '';
    }
  }

  Future<int> _installZshCompletion(List<CompletionConfiguration> configs) async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) {
      ConsoleUtils.error('Could not determine home directory');
      return 1;
    }

    final completionDirs = ['$home/.zsh/completions', '$home/.zfunc', '/usr/local/share/zsh/site-functions'];

    String? targetDir;
    for (final dir in completionDirs) {
      if (Directory(dir).existsSync()) {
        targetDir = dir;
        break;
      }
    }

    if (targetDir == null) {
      targetDir = '$home/.zsh/completions';
      try {
        Directory(targetDir).createSync(recursive: true);
      } catch (e) {
        ConsoleUtils.error('Could not create completion directory: $e');
        return 1;
      }
    }

    final targetFile = '$targetDir/_dcli';

    try {
      File(targetFile).writeAsStringSync(_generateZshCompletion(configs));
      ConsoleUtils.success('Installed completion to $targetFile');
      print('');
      print('Add the following to your ~/.zshrc if not already present:');
      print('');
      print('  ${ConsoleUtils.cyan}fpath=($targetDir \$fpath)${ConsoleUtils.reset}');
      print('  ${ConsoleUtils.cyan}autoload -Uz compinit && compinit${ConsoleUtils.reset}');
      print('');
      print('Then restart your shell or run:');
      print('  ${ConsoleUtils.cyan}source ~/.zshrc${ConsoleUtils.reset}');
      print('');
      return 0;
    } catch (e) {
      ConsoleUtils.error('Failed to install completion: $e');
      return 1;
    }
  }

  Future<int> _installBashCompletion(List<CompletionConfiguration> configs) async {
    final home = Platform.environment['HOME'] ?? '';
    if (home.isEmpty) {
      ConsoleUtils.error('Could not determine home directory');
      return 1;
    }

    final systemDir = '/etc/bash_completion.d';
    if (Directory(systemDir).existsSync()) {
      final targetFile = '$systemDir/dcli';
      try {
        File(targetFile).writeAsStringSync(_generateBashCompletion(configs));
        ConsoleUtils.success('Installed completion to $targetFile');
        print('');
        print('Restart your shell to enable completions.');
        return 0;
      } catch (_) {
        // Fall through to user directory
      }
    }

    final bashrc = '$home/.bashrc';
    try {
      final content = File(bashrc).existsSync() ? File(bashrc).readAsStringSync() : '';

      if (content.contains('_dcli_completions')) {
        ConsoleUtils.info('Bash completion already installed');
        return 0;
      }

      final completionScript = _generateBashCompletion(configs);
      File(bashrc).writeAsStringSync('$content\n\n# Dash CLI completion\n$completionScript\n');

      ConsoleUtils.success('Installed completion to $bashrc');
      print('');
      print('Restart your shell or run:');
      print('  ${ConsoleUtils.cyan}source ~/.bashrc${ConsoleUtils.reset}');
      print('');
      return 0;
    } catch (e) {
      ConsoleUtils.error('Failed to install completion: $e');
      return 1;
    }
  }

  @override
  CompletionConfiguration? getCompletionConfig() {
    return DcliArgument.toCompletionConfig(name: name, description: description, arguments: _arguments);
  }
}
