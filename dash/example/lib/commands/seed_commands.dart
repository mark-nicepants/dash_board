import 'package:dash/dash.dart';
import 'package:dash_example/models/post.dart';
import 'package:dash_example/models/user.dart';
import 'package:faker/faker.dart';

final _faker = Faker();

/// Command to seed the database with sample users.
DevCommand seedUsersCommand() => DevCommand(
  name: 'seed:users',
  description: 'Seed the database with sample users',
  usage: 'seed:users [count]',
  handler: (args) async {
    final count = args.isNotEmpty ? int.tryParse(args.first) ?? 5 : 5;
    print('\n🌱 Seeding $count users...\n');

    final roles = ['user', 'admin', 'moderator'];

    for (var i = 0; i < count; i++) {
      final name = _faker.person.name();
      final email = _faker.internet.email();
      final role = roles[i % roles.length];
      final password = 'password123'; // In production, hash this!

      final user = User(name: name, email: email, password: password, role: role);
      await user.save();
      print('   ✓ Created user: $name ($email)');
    }

    print('\n✅ Seeded $count users\n');
  },
);

/// Command to seed the database with sample posts.
DevCommand seedPostsCommand() => DevCommand(
  name: 'seed:posts',
  description: 'Seed the database with sample posts',
  usage: 'seed:posts [count]',
  handler: (args) async {
    final count = args.isNotEmpty ? int.tryParse(args.first) ?? 10 : 10;
    print('\n🌱 Seeding $count posts...\n');

    // Get existing users to assign as authors
    final users = await User.all();
    if (users.isEmpty) {
      print('   ⚠️  No users found. Run "seed:users" first.\n');
      return;
    }

    for (var i = 0; i < count; i++) {
      final authorUser = users[i % users.length];
      final title = _faker.lorem.sentence();
      final slug = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
      final content = _faker.lorem.sentences(5).join(' ');

      final post = Post(title: title, slug: slug, content: content, author: authorUser.id!, isPublished: i % 2 == 0);
      await post.save();
      print('   ✓ Created post: ${post.title}');
    }

    print('\n✅ Seeded $count posts\n');
  },
);

/// Command to clear all data from the database.
DevCommand clearDatabaseCommand() => DevCommand(
  name: 'db:clear',
  description: 'Clear all data from the database (keeps tables)',
  handler: (args) async {
    print('\n🗑️  Clearing database...\n');

    // Delete all posts first (foreign key constraint)
    final posts = await Post.all();
    for (final post in posts) {
      await post.delete();
    }
    print('   ✓ Deleted ${posts.length} posts');

    // Delete all users
    final users = await User.all();
    for (final user in users) {
      await user.delete();
    }
    print('   ✓ Deleted ${users.length} users');

    print('\n✅ Database cleared\n');
  },
);

/// Command to seed all data.
DevCommand seedAllCommand() => DevCommand(
  name: 'seed',
  description: 'Seed the database with sample users and posts',
  handler: (args) async {
    await seedUsersCommand().handler(['5']);
    await seedPostsCommand().handler(['10']);
  },
);
