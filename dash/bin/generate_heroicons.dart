#!/usr/bin/env dart

import 'dart:io';

Future<void> main() async {
  print('🎨 Generating Heroicons...');

  final tempDir = Directory.systemTemp.createTempSync('heroicons');
  final repoPath = '${tempDir.path}/heroicons';

  try {
    // Clone the heroicons repository
    print('📦 Cloning heroicons repository...');
    final cloneResult = await Process.run('git', [
      'clone',
      '--depth',
      '1',
      'https://github.com/tailwindlabs/heroicons.git',
      repoPath,
    ]);

    if (cloneResult.exitCode != 0) {
      print('❌ Failed to clone repository');
      print(cloneResult.stderr);
      exit(1);
    }

    print('✅ Repository cloned');

    // Parse SVG files
    final outlineDir = Directory('$repoPath/optimized/24/outline');
    final solidDir = Directory('$repoPath/optimized/24/solid');

    if (!outlineDir.existsSync() || !solidDir.existsSync()) {
      print('❌ Icon directories not found');
      exit(1);
    }

    final outlineIcons = <String, String>{};
    final solidIcons = <String, String>{};

    print('🔍 Parsing outline icons...');
    await _parseIcons(outlineDir, outlineIcons);
    print('   Found ${outlineIcons.length} outline icons');

    print('🔍 Parsing solid icons...');
    await _parseIcons(solidDir, solidIcons);
    print('   Found ${solidIcons.length} solid icons');

    // Generate the Dart file
    print('📝 Generating heroicon.dart...');
    final output = _generateDartFile(outlineIcons, solidIcons);

    final outputFile = File('lib/src/components/heroicon.dart');
    await outputFile.writeAsString(output);

    print('✅ Generated ${outputFile.path}');
    print('🎉 Done! Generated ${outlineIcons.length + solidIcons.length} icons');
  } finally {
    // Cleanup
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  }
}

Future<void> _parseIcons(Directory dir, Map<String, String> icons) async {
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.svg'));

  for (final file in files) {
    final name = file.uri.pathSegments.last.replaceAll('.svg', '');
    final content = await file.readAsString();

    // Extract the path data from the SVG
    final pathMatch = RegExp(r'<svg[^>]*>(.*?)</svg>', dotAll: true).firstMatch(content);
    if (pathMatch != null) {
      final svgContent = pathMatch.group(1)!.trim();
      icons[name] = svgContent;
    }
  }
}

String _generateDartFile(Map<String, String> outlineIcons, Map<String, String> solidIcons) {
  final buffer = StringBuffer();

  // File header
  buffer.writeln("import 'package:jaspr/jaspr.dart';");
  buffer.writeln();
  buffer.writeln('/// Heroicon component for rendering icons.');
  buffer.writeln('///');
  buffer.writeln('/// Supports both solid and outline variants from heroicons.com');
  buffer.writeln('/// Example: Heroicon(HeroIcons.userGroup, style: HeroIconStyle.solid)');
  buffer.writeln('class Heroicon extends StatelessComponent {');
  buffer.writeln('  final HeroIcons icon;');
  buffer.writeln('  final HeroIconStyle style;');
  buffer.writeln('  final String? className;');
  buffer.writeln();
  buffer.writeln('  const Heroicon(');
  buffer.writeln('    this.icon, {');
  buffer.writeln('    this.style = HeroIconStyle.outline,');
  buffer.writeln('    this.className,');
  buffer.writeln('    super.key,');
  buffer.writeln('  });');
  buffer.writeln();
  buffer.writeln('  @override');
  buffer.writeln('  Component build(BuildContext context) {');
  buffer.writeln('    final pathData = style == HeroIconStyle.solid');
  buffer.writeln('        ? _solidPaths[icon]');
  buffer.writeln('        : _outlinePaths[icon];');
  buffer.writeln();
  buffer.writeln('    if (pathData == null) {');
  buffer.writeln('      return span([text(\'?\')]);');
  buffer.writeln('    }');
  buffer.writeln();
  buffer.writeln('    final fillAttr = style == HeroIconStyle.solid ? \'fill="currentColor"\' : \'fill="none"\';');
  buffer.writeln();
  buffer.writeln('    return raw(');
  buffer.writeln(
    '      \'<svg class="\${className ?? \'nav-icon\'}" xmlns="http://www.w3.org/2000/svg" \$fillAttr viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">\$pathData</svg>\',',
  );
  buffer.writeln('    );');
  buffer.writeln('  }');
  buffer.writeln('}');
  buffer.writeln();

  // Enum
  buffer.writeln('/// Icon style variants');
  buffer.writeln('enum HeroIconStyle {');
  buffer.writeln('  outline,');
  buffer.writeln('  solid,');
  buffer.writeln('}');
  buffer.writeln();

  // Icons enum
  buffer.writeln('/// Available heroicons');
  buffer.writeln('enum HeroIcons {');
  final allIconNames = {...outlineIcons.keys, ...solidIcons.keys}.toList()..sort();
  for (var i = 0; i < allIconNames.length; i++) {
    final name = allIconNames[i];
    final enumName = _toCamelCase(name);
    buffer.write('  $enumName');
    if (i < allIconNames.length - 1) {
      buffer.write(',');
    }
    buffer.writeln();
  }
  buffer.writeln('}');
  buffer.writeln();

  // Outline paths map
  buffer.writeln('/// Outline icon paths');
  buffer.writeln('const Map<HeroIcons, String> _outlinePaths = {');
  final sortedOutline = outlineIcons.keys.toList()..sort();
  for (var i = 0; i < sortedOutline.length; i++) {
    final name = sortedOutline[i];
    final enumName = _toCamelCase(name);
    final path = _escapePath(outlineIcons[name]!);
    buffer.write('  HeroIcons.$enumName: \'$path\'');
    if (i < sortedOutline.length - 1) {
      buffer.write(',');
    }
    buffer.writeln();
  }
  buffer.writeln('};');
  buffer.writeln();

  // Solid paths map
  buffer.writeln('/// Solid icon paths');
  buffer.writeln('const Map<HeroIcons, String> _solidPaths = {');
  final sortedSolid = solidIcons.keys.toList()..sort();
  for (var i = 0; i < sortedSolid.length; i++) {
    final name = sortedSolid[i];
    final enumName = _toCamelCase(name);
    final path = _escapePath(solidIcons[name]!);
    buffer.write('  HeroIcons.$enumName: \'$path\'');
    if (i < sortedSolid.length - 1) {
      buffer.write(',');
    }
    buffer.writeln();
  }
  buffer.writeln('};');

  return buffer.toString();
}

String _escapePath(String path) {
  return path
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\$', '\\\$')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _toCamelCase(String name) {
  // Replace special characters and numbers at the start
  var cleaned = name.replaceAll(RegExp(r'[^a-zA-Z0-9-]'), '').replaceAll(RegExp(r'^[0-9]'), 'icon');

  final parts = cleaned.split('-');

  // Handle empty parts
  if (parts.isEmpty || parts.first.isEmpty) {
    return 'icon';
  }

  // Ensure first character is lowercase
  var result = parts.first.toLowerCase();

  // Capitalize subsequent parts
  for (final part in parts.skip(1)) {
    if (part.isNotEmpty) {
      result += part[0].toUpperCase() + part.substring(1).toLowerCase();
    }
  }

  // Ensure it's a valid Dart identifier
  if (result.isEmpty || !RegExp(r'^[a-zA-Z]').hasMatch(result)) {
    result = 'icon$result';
  }

  return result;
}
