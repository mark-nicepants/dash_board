import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('Policy', () {
    test('AllowAllPolicy allows all actions by default', () async {
      final policy = AllowAllPolicy<_TestModel>();

      expect(await policy.viewAny(null), isTrue);
      expect(await policy.view(null, _TestModel()), isTrue);
      expect(await policy.create(null), isTrue);
      expect(await policy.update(null, _TestModel()), isTrue);
      expect(await policy.delete(null, _TestModel()), isTrue);
      expect(await policy.restore(null, _TestModel()), isTrue);
      expect(await policy.forceDelete(null, _TestModel()), isTrue);
    });

    test('DenyAllPolicy denies all actions', () async {
      final policy = DenyAllPolicy<_TestModel>();

      expect(await policy.viewAny(null), isFalse);
      expect(await policy.view(null, _TestModel()), isFalse);
      expect(await policy.create(null), isFalse);
      expect(await policy.update(null, _TestModel()), isFalse);
      expect(await policy.delete(null, _TestModel()), isFalse);
      expect(await policy.restore(null, _TestModel()), isFalse);
      expect(await policy.forceDelete(null, _TestModel()), isFalse);
    });

    test('authorize method dispatches to correct policy method', () async {
      final policy = AllowAllPolicy<_TestModel>();
      final model = _TestModel();

      expect(await policy.authorize('viewAny', null), isTrue);
      expect(await policy.authorize('view', null, model), isTrue);
      expect(await policy.authorize('create', null), isTrue);
      expect(await policy.authorize('update', null, model), isTrue);
      expect(await policy.authorize('delete', null, model), isTrue);
      expect(await policy.authorize('restore', null, model), isTrue);
      expect(await policy.authorize('forceDelete', null, model), isTrue);
    });

    test('authorize returns false for unknown ability', () async {
      final policy = AllowAllPolicy<_TestModel>();
      expect(await policy.authorize('unknownAbility', null), isFalse);
    });

    test('before hook can override policy decisions', () async {
      final policy = _BeforePolicy();

      // Before hook returns true for 'delete' ability
      expect(await policy.authorize('delete', null, _TestModel()), isTrue);

      // Before hook returns false for 'forceDelete' ability
      expect(await policy.authorize('forceDelete', null, _TestModel()), isFalse);

      // Before hook returns null for other abilities, so normal policy runs
      expect(await policy.authorize('viewAny', null), isTrue);
    });

    test('custom policy can implement business logic', () async {
      final policy = _OwnerPolicy();
      final user = _TestUser(id: 1);
      final ownedModel = _TestModel()..ownerId = 1;
      final otherModel = _TestModel()..ownerId = 2;

      // User can update their own content
      expect(await policy.update(user, ownedModel), isTrue);

      // User cannot update others' content
      expect(await policy.update(user, otherModel), isFalse);
    });
  });

  group('PolicyRegistry', () {
    setUp(PolicyRegistry.clear);

    test('returns default AllowAllPolicy when no policy registered', () async {
      final result = await PolicyRegistry.authorize<_TestModel>('viewAny', null);
      expect(result, isTrue);
    });

    test('can set DenyAllPolicy as default', () async {
      PolicyRegistry.setDefaultPolicy(DenyAllPolicy.new);

      final result = await PolicyRegistry.authorize<_TestModel>('viewAny', null);
      expect(result, isFalse);
    });

    test('register and retrieve policy for model type', () async {
      PolicyRegistry.register<_TestModel>(_OwnerPolicy());

      final user = _TestUser(id: 1);
      final model = _TestModel()..ownerId = 1;

      expect(await PolicyRegistry.canUpdate(user, model), isTrue);
    });

    test('registerFactory enables convention-based lookup', () async {
      PolicyRegistry.registerFactory('_TestModel', DenyAllPolicy<_TestModel>.new);

      final result = await PolicyRegistry.authorize<_TestModel>('viewAny', null);
      expect(result, isFalse);
    });

    test('convenience methods work correctly', () async {
      PolicyRegistry.register<_TestModel>(AllowAllPolicy<_TestModel>());
      final model = _TestModel();

      expect(await PolicyRegistry.canViewAny<_TestModel>(null), isTrue);
      expect(await PolicyRegistry.canView(null, model), isTrue);
      expect(await PolicyRegistry.canCreate<_TestModel>(null), isTrue);
      expect(await PolicyRegistry.canUpdate(null, model), isTrue);
      expect(await PolicyRegistry.canDelete(null, model), isTrue);
      expect(await PolicyRegistry.canRestore(null, model), isTrue);
      expect(await PolicyRegistry.canForceDelete(null, model), isTrue);
    });

    test('clear removes all registered policies', () async {
      PolicyRegistry.register<_TestModel>(DenyAllPolicy<_TestModel>());
      expect(await PolicyRegistry.canViewAny<_TestModel>(null), isFalse);

      PolicyRegistry.clear();
      // Back to default AllowAllPolicy
      expect(await PolicyRegistry.canViewAny<_TestModel>(null), isTrue);
    });
  });
}

// Test model
class _TestModel extends Model {
  int? id;
  int? ownerId;

  @override
  String get table => 'test_models';

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) {
    id = value as int?;
  }

  @override
  List<String> getFields() => ['id', 'owner_id'];

  @override
  Map<String, dynamic> toMap() => {'id': id, 'owner_id': ownerId};

  @override
  void fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
    ownerId = map['owner_id'] as int?;
  }
}

// Test user model
class _TestUser extends Model {
  int? id;

  _TestUser({this.id});

  @override
  String get table => 'test_users';

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic value) {
    id = value as int?;
  }

  @override
  List<String> getFields() => ['id'];

  @override
  Map<String, dynamic> toMap() => {'id': id};

  @override
  void fromMap(Map<String, dynamic> map) {
    id = map['id'] as int?;
  }
}

// Policy that uses before hook
class _BeforePolicy extends Policy<_TestModel> {
  @override
  Future<bool?> before(Model? user, String ability) async {
    if (ability == 'delete') return true;
    if (ability == 'forceDelete') return false;
    return null; // Continue with normal checks
  }
}

// Policy that checks ownership
class _OwnerPolicy extends Policy<_TestModel> {
  @override
  Future<bool> update(Model? user, _TestModel model) async {
    if (user == null) return false;
    return model.ownerId == user.getKey();
  }
}
