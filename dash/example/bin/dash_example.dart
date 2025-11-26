import 'package:dash_example/main.dart' as app;

Future<void> main(List<String> args) async {
  // Get database directory from arguments or use default
  final dbDir = args.isNotEmpty ? args[0] : 'database';
  await app.main(dbDir: dbDir);
}
