import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('sanitizeSearchQuery', () {
    test('returns empty string for null input', () {
      expect(sanitizeSearchQuery(null), equals(''));
    });

    test('returns empty string for empty input', () {
      expect(sanitizeSearchQuery(''), equals(''));
    });

    test('trims whitespace', () {
      expect(sanitizeSearchQuery('  hello  '), equals('hello'));
    });

    test('escapes percent signs', () {
      expect(sanitizeSearchQuery('admin%'), equals(r'admin\%'));
    });

    test('escapes underscores', () {
      expect(sanitizeSearchQuery('admin_user'), equals(r'admin\_user'));
    });

    test('escapes backslashes', () {
      expect(sanitizeSearchQuery(r'admin\test'), equals(r'admin\\test'));
    });

    test('handles SQL injection attempt with percent', () {
      final malicious = "admin%' OR '1'='1";
      final sanitized = sanitizeSearchQuery(malicious);
      expect(sanitized, equals(r"admin\%' OR '1'='1"));
    });

    test('handles multiple wildcards', () {
      expect(sanitizeSearchQuery('a%b_c%d'), equals(r'a\%b\_c\%d'));
    });

    test('limits length to maxLength', () {
      final longString = 'a' * 300;
      final sanitized = sanitizeSearchQuery(longString);
      expect(sanitized.length, equals(255));
    });

    test('respects custom maxLength', () {
      final longString = 'a' * 100;
      final sanitized = sanitizeSearchQuery(longString, maxLength: 50);
      expect(sanitized.length, equals(50));
    });

    test('preserves normal text', () {
      expect(sanitizeSearchQuery('john doe'), equals('john doe'));
    });

    test('preserves special characters that are not wildcards', () {
      expect(sanitizeSearchQuery("john's email: test@example.com"), equals("john's email: test@example.com"));
    });
  });

  group('sanitizeHtml', () {
    test('escapes HTML entities', () {
      expect(
        sanitizeHtml('<script>alert("XSS")</script>'),
        equals('&lt;script&gt;alert(&quot;XSS&quot;)&lt;&#x2F;script&gt;'),
      );
    });

    test('returns empty string for null', () {
      expect(sanitizeHtml(null), equals(''));
    });

    test('handles all special characters', () {
      expect(sanitizeHtml('&<>"\'/'), equals('&amp;&lt;&gt;&quot;&#x27;&#x2F;'));
    });
  });

  group('isValidColumnName', () {
    test('accepts valid column names', () {
      expect(isValidColumnName('user_id'), isTrue);
      expect(isValidColumnName('firstName'), isTrue);
      expect(isValidColumnName('_private'), isTrue);
      expect(isValidColumnName('column123'), isTrue);
    });

    test('rejects invalid column names', () {
      expect(isValidColumnName('user-id'), isFalse); // Dash not allowed
      expect(isValidColumnName('user.id'), isFalse); // Dot not allowed
      expect(isValidColumnName('user id'), isFalse); // Space not allowed
      expect(isValidColumnName('123column'), isFalse); // Cannot start with number
      expect(isValidColumnName('user;id'), isFalse); // Semicolon not allowed
      expect(isValidColumnName('DROP TABLE'), isFalse);
    });

    test('rejects null and empty strings', () {
      expect(isValidColumnName(null), isFalse);
      expect(isValidColumnName(''), isFalse);
    });
  });
}
