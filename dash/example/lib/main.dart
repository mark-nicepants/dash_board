import 'package:dash/dash.dart';
import 'package:dash_example/commands/seed_commands.dart';
import 'package:dash_example/models/post.dart';
import 'package:dash_example/models/user.dart';
import 'package:dash_example/resources/post_resource.dart';
import 'package:dash_example/resources/user_resource.dart';

Future<void> main({String dbDir = 'database'}) async {
  print('🚀 Dash Example Admin Panel\n');
  print('📁 Database directory: $dbDir\n');

  // Register models and their resource factories
  User.register(UserResource.new);
  Post.register(PostResource.new);

  // Create and configure the admin panel with automatic migrations
  // Schemas are automatically extracted from resources!
  final panel = Panel()
    ..setId('admin')
    ..setPath('/admin')
    ..authModel<User>()
    ..addDevCommands([
      seedUsersCommand(), //
      seedPostsCommand(),
      seedAllCommand(),
      clearDatabaseCommand(),
    ])
    ..database(
      DatabaseConfig.using(SqliteConnector('$dbDir/app.db'), migrations: MigrationConfig.fromResources(verbose: true)),
    );

  print('🔄 Running automatic migrations...\n');

  // Start the server (migrations run automatically on connect)
  // The dev console provides interactive commands while the server is running
  await panel.serve(host: 'localhost', port: 8080);
}
