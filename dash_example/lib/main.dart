import 'package:dash/dash.dart';
import 'package:dash_example/models/post.dart';
import 'package:dash_example/models/user.dart';

import 'resources/post_resource.dart';
import 'resources/user_resource.dart';

Future<void> main({String dbDir = 'database'}) async {
  print('🚀 Dash Example Admin Panel\n');
  print('📁 Database directory: $dbDir\n');

  // Register model resource builders
  UserModel.register(UserResource.new);
  PostModel.register(PostResource.new);

  // Create and configure the admin panel with automatic migrations
  // Schemas are automatically extracted from resources!
  final panel = Panel()
    ..setId('admin')
    ..setPath('/admin')
    ..database(
      DatabaseConfig.using(SqliteConnector('$dbDir/app.db'), migrations: MigrationConfig.fromResources(verbose: true)),
    );

  print('🔄 Running automatic migrations...\n');

  // Start the server (migrations run automatically on connect)
  await panel.serve(host: 'localhost', port: 8080);

  // Keep the server running
  print('\n⌨️  Press Ctrl+C to stop the server\n');
}
