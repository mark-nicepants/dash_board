import 'package:dash/dash.dart';
// Import service_locator directly to test internal functions
import 'package:dash/src/service_locator.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

/// Test model for service locator tests
class TestModel extends Model {
  int? id;
  String name;

  TestModel({this.id, this.name = ''});

  @override
  String get table => 'test_models';

  @override
  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  @override
  TestModel fromMap(Map<String, dynamic> map) {
    return TestModel(id: map['id'] as int?, name: map['name'] as String? ?? '');
  }

  @override
  dynamic getKey() => id;

  @override
  void setKey(dynamic key) {
    id = key as int?;
  }

  @override
  List<String> getFields() => ['id', 'name'];

  @override
  @mustBeOverridden
  TableSchema get schema => throw UnimplementedError();
}

void main() {
  group('getStorageUrl', () {
    test('returns http URLs unchanged', () {
      expect(getStorageUrl('http://example.com/image.jpg'), equals('http://example.com/image.jpg'));
    });

    test('returns https URLs unchanged', () {
      expect(getStorageUrl('https://example.com/image.jpg'), equals('https://example.com/image.jpg'));
    });

    test('returns absolute paths unchanged', () {
      expect(getStorageUrl('/static/image.jpg'), equals('/static/image.jpg'));
    });

    test('constructs storage URL with default path when no config', () {
      final url = getStorageUrl('uploads/image.jpg');
      expect(url, equals('/admin/storage/uploads/image.jpg'));
    });

    test('constructs storage URL with disk parameter', () {
      final url = getStorageUrl('image.jpg', disk: 'public');
      expect(url, equals('/admin/storage/public/image.jpg'));
    });

    test('uses panel config path when registered', () {
      final config = PanelConfig()..setPath('/custom-admin');
      inject.registerSingleton<PanelConfig>(config);

      final url = getStorageUrl('uploads/image.jpg');
      expect(url, equals('/custom-admin/storage/uploads/image.jpg'));
    });
  });

  group('PanelConfig', () {
    test('should have default values', () {
      final config = PanelConfig();

      expect(config.id, equals('admin'));
      expect(config.path, equals('/admin'));
      expect(config.resources, isEmpty);
      expect(config.widgets, isEmpty);
    });

    test('should allow setting id', () {
      final config = PanelConfig()..setId('custom');

      expect(config.id, equals('custom'));
    });

    test('should allow setting path', () {
      final config = PanelConfig()..setPath('/custom-admin');

      expect(config.path, equals('/custom-admin'));
    });

    test('should have default colors', () {
      final config = PanelConfig();

      expect(config.colors, isA<PanelColors>());
      expect(config.colors.primary, equals('cyan'));
    });

    test('should allow setting custom colors', () {
      final customColors = const PanelColors(primary: 'purple');
      final config = PanelConfig()..setColors(customColors);

      expect(config.colors.primary, equals('purple'));
    });
  });

  group('PanelColors', () {
    test('should have default color values', () {
      const colors = PanelColors();

      expect(colors.primary, equals('cyan'));
      expect(colors.danger, equals('red'));
      expect(colors.warning, equals('amber'));
      expect(colors.success, equals('green'));
      expect(colors.info, equals('blue'));
    });

    test('should allow custom primary color', () {
      const colors = PanelColors(primary: 'indigo');

      expect(colors.primary, equals('indigo'));
    });

    test('should allow custom danger color', () {
      const colors = PanelColors(danger: 'pink');

      expect(colors.danger, equals('pink'));
    });

    test('should allow all custom colors', () {
      const colors = PanelColors(primary: 'purple', danger: 'rose', warning: 'yellow', success: 'emerald', info: 'sky');

      expect(colors.primary, equals('purple'));
      expect(colors.danger, equals('rose'));
      expect(colors.warning, equals('yellow'));
      expect(colors.success, equals('emerald'));
      expect(colors.info, equals('sky'));
    });

    test('should provide static defaults', () {
      expect(PanelColors.defaults.primary, equals('cyan'));
    });

    test('should generate primary background class', () {
      const colors = PanelColors(primary: 'indigo');

      expect(colors.primaryBg, equals('bg-indigo-500'));
    });

    test('should generate primary text class', () {
      const colors = PanelColors(primary: 'violet');

      expect(colors.primaryText, equals('text-violet-500'));
    });

    test('should generate primary border class', () {
      const colors = PanelColors(primary: 'rose');

      expect(colors.primaryBorder, equals('border-rose-500'));
    });

    test('should generate danger background class', () {
      const colors = PanelColors(danger: 'orange');

      expect(colors.dangerBg, equals('bg-orange-600'));
    });
  });
}
