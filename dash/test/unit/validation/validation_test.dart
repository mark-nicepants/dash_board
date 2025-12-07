import 'package:dash/dash.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationException', () {
    test('toString formats errors correctly', () {
      final exception = ValidationException({
        'email': ['The email field is required.', 'The email must be valid.'],
        'name': ['The name field is required.'],
      });

      final result = exception.toString();
      expect(result, contains('Validation failed:'));
      expect(result, contains('email:'));
      expect(result, contains('The email field is required.'));
      expect(result, contains('name:'));
    });
  });

  group('Required', () {
    late Required rule;

    setUp(() {
      rule = Required();
    });

    test('name returns required', () {
      expect(rule.name, equals('required'));
    });

    test('returns error for null value', () {
      expect(rule.validate('field', null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(rule.validate('field', ''), isNotNull);
    });

    test('returns error for empty list', () {
      expect(rule.validate('field', []), isNotNull);
    });

    test('passes for non-empty string', () {
      expect(rule.validate('field', 'value'), isNull);
    });

    test('passes for non-empty list', () {
      expect(rule.validate('field', ['item']), isNull);
    });

    test('passes for zero', () {
      expect(rule.validate('field', 0), isNull);
    });

    test('passes for false boolean', () {
      expect(rule.validate('field', false), isNull);
    });

    test('error message includes field name', () {
      final error = rule.validate('email', null);
      expect(error, contains('email'));
    });
  });

  group('Email', () {
    late Email rule;

    setUp(() {
      rule = Email();
    });

    test('name returns email', () {
      expect(rule.name, equals('email'));
    });

    test('passes for null value (use Required for non-null)', () {
      expect(rule.validate('email', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('email', ''), isNull);
    });

    test('passes for valid email', () {
      expect(rule.validate('email', 'test@example.com'), isNull);
    });

    test('passes for email with subdomain', () {
      expect(rule.validate('email', 'test@mail.example.com'), isNull);
    });

    test('passes for email with plus', () {
      expect(rule.validate('email', 'test+label@example.com'), isNull);
    });

    test('passes for email with dots', () {
      expect(rule.validate('email', 'first.last@example.com'), isNull);
    });

    test('fails for email without @', () {
      expect(rule.validate('email', 'invalid-email'), isNotNull);
    });

    test('fails for email without domain', () {
      expect(rule.validate('email', 'test@'), isNotNull);
    });

    test('fails for email without local part', () {
      expect(rule.validate('email', '@example.com'), isNotNull);
    });

    test('fails for email with spaces', () {
      expect(rule.validate('email', 'test @example.com'), isNotNull);
    });

    test('fails for non-string value', () {
      expect(rule.validate('email', 123), isNotNull);
    });
  });

  group('Url', () {
    late Url rule;

    setUp(() {
      rule = Url();
    });

    test('name returns url', () {
      expect(rule.name, equals('url'));
    });

    test('passes for null value', () {
      expect(rule.validate('website', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('website', ''), isNull);
    });

    test('passes for valid http URL', () {
      expect(rule.validate('website', 'http://example.com'), isNull);
    });

    test('passes for valid https URL', () {
      expect(rule.validate('website', 'https://example.com'), isNull);
    });

    test('passes for URL with path', () {
      expect(rule.validate('website', 'https://example.com/path/to/page'), isNull);
    });

    test('passes for URL with query params', () {
      expect(rule.validate('website', 'https://example.com?foo=bar'), isNull);
    });

    test('fails for URL without scheme', () {
      expect(rule.validate('website', 'example.com'), isNotNull);
    });

    test('fails for ftp URL (only http/https)', () {
      expect(rule.validate('website', 'ftp://example.com'), isNotNull);
    });

    test('fails for non-string value', () {
      expect(rule.validate('website', 123), isNotNull);
    });
  });

  group('MinLength', () {
    late MinLength rule;

    setUp(() {
      rule = MinLength(5);
    });

    test('name includes min value', () {
      expect(rule.name, equals('min:5'));
    });

    test('passes for null value', () {
      expect(rule.validate('name', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('name', ''), isNull);
    });

    test('passes for string at minimum length', () {
      expect(rule.validate('name', '12345'), isNull);
    });

    test('passes for string above minimum length', () {
      expect(rule.validate('name', '123456'), isNull);
    });

    test('fails for string below minimum length', () {
      expect(rule.validate('name', '1234'), isNotNull);
    });

    test('error message includes field and min value', () {
      final error = rule.validate('name', 'ab');
      expect(error, contains('name'));
      expect(error, contains('5'));
    });
  });

  group('MaxLength', () {
    late MaxLength rule;

    setUp(() {
      rule = MaxLength(10);
    });

    test('name includes max value', () {
      expect(rule.name, equals('max:10'));
    });

    test('passes for null value', () {
      expect(rule.validate('bio', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('bio', ''), isNull);
    });

    test('passes for string at maximum length', () {
      expect(rule.validate('bio', '1234567890'), isNull);
    });

    test('passes for string below maximum length', () {
      expect(rule.validate('bio', '12345'), isNull);
    });

    test('fails for string above maximum length', () {
      expect(rule.validate('bio', '12345678901'), isNotNull);
    });

    test('error message includes field and max value', () {
      final error = rule.validate('bio', 'a' * 15);
      expect(error, contains('bio'));
      expect(error, contains('10'));
    });
  });

  group('Numeric', () {
    late Numeric rule;

    setUp(() {
      rule = Numeric();
    });

    test('name returns numeric', () {
      expect(rule.name, equals('numeric'));
    });

    test('passes for null value', () {
      expect(rule.validate('amount', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('amount', ''), isNull);
    });

    test('passes for integer', () {
      expect(rule.validate('amount', 42), isNull);
    });

    test('passes for double', () {
      expect(rule.validate('amount', 3.14), isNull);
    });

    test('passes for numeric string', () {
      expect(rule.validate('amount', '123'), isNull);
    });

    test('passes for negative numeric string', () {
      expect(rule.validate('amount', '-123.45'), isNull);
    });

    test('fails for non-numeric string', () {
      expect(rule.validate('amount', 'abc'), isNotNull);
    });

    test('fails for mixed string', () {
      expect(rule.validate('amount', '12abc'), isNotNull);
    });
  });

  group('Integer', () {
    late Integer rule;

    setUp(() {
      rule = Integer();
    });

    test('name returns integer', () {
      expect(rule.name, equals('integer'));
    });

    test('passes for null value', () {
      expect(rule.validate('count', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('count', ''), isNull);
    });

    test('passes for int', () {
      expect(rule.validate('count', 42), isNull);
    });

    test('passes for integer string', () {
      expect(rule.validate('count', '123'), isNull);
    });

    test('passes for negative integer string', () {
      expect(rule.validate('count', '-456'), isNull);
    });

    test('fails for decimal', () {
      expect(rule.validate('count', '12.34'), isNotNull);
    });

    test('fails for double', () {
      expect(rule.validate('count', 3.14), isNotNull);
    });
  });

  group('Min', () {
    late Min rule;

    setUp(() {
      rule = Min(10);
    });

    test('name includes min value', () {
      expect(rule.name, equals('min:10'));
    });

    test('passes for null value', () {
      expect(rule.validate('age', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('age', ''), isNull);
    });

    test('passes for value at minimum', () {
      expect(rule.validate('age', 10), isNull);
    });

    test('passes for value above minimum', () {
      expect(rule.validate('age', 15), isNull);
    });

    test('passes for string value at minimum', () {
      expect(rule.validate('age', '10'), isNull);
    });

    test('fails for value below minimum', () {
      expect(rule.validate('age', 5), isNotNull);
    });

    test('fails for non-numeric value', () {
      expect(rule.validate('age', 'abc'), isNotNull);
    });
  });

  group('Max', () {
    late Max rule;

    setUp(() {
      rule = Max(100);
    });

    test('name includes max value', () {
      expect(rule.name, equals('max:100'));
    });

    test('passes for null value', () {
      expect(rule.validate('score', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('score', ''), isNull);
    });

    test('passes for value at maximum', () {
      expect(rule.validate('score', 100), isNull);
    });

    test('passes for value below maximum', () {
      expect(rule.validate('score', 50), isNull);
    });

    test('passes for string value below maximum', () {
      expect(rule.validate('score', '75'), isNull);
    });

    test('fails for value above maximum', () {
      expect(rule.validate('score', 150), isNotNull);
    });

    test('fails for non-numeric value', () {
      expect(rule.validate('score', 'abc'), isNotNull);
    });
  });

  group('InList', () {
    late InList rule;

    setUp(() {
      rule = InList(['active', 'inactive', 'pending']);
    });

    test('name includes allowed values', () {
      expect(rule.name, contains('active'));
      expect(rule.name, contains('inactive'));
      expect(rule.name, contains('pending'));
    });

    test('passes for null value', () {
      expect(rule.validate('status', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('status', ''), isNull);
    });

    test('passes for value in list', () {
      expect(rule.validate('status', 'active'), isNull);
    });

    test('passes for all values in list', () {
      expect(rule.validate('status', 'inactive'), isNull);
      expect(rule.validate('status', 'pending'), isNull);
    });

    test('fails for value not in list', () {
      expect(rule.validate('status', 'invalid'), isNotNull);
    });

    test('fails for similar but different case', () {
      expect(rule.validate('status', 'Active'), isNotNull);
    });
  });

  group('Pattern', () {
    late Pattern rule;

    setUp(() {
      rule = Pattern(RegExp(r'^[A-Z]{2}[0-9]{4}$'));
    });

    test('name returns regex', () {
      expect(rule.name, equals('regex'));
    });

    test('passes for null value', () {
      expect(rule.validate('code', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('code', ''), isNull);
    });

    test('passes for matching pattern', () {
      expect(rule.validate('code', 'AB1234'), isNull);
    });

    test('fails for non-matching pattern', () {
      expect(rule.validate('code', 'ABC123'), isNotNull);
    });

    test('fails for lowercase letters', () {
      expect(rule.validate('code', 'ab1234'), isNotNull);
    });

    test('uses custom message when provided', () {
      final customRule = Pattern(
        RegExp(r'^\d+$'),
        message: 'Please enter numbers only.',
      );
      final error = customRule.validate('field', 'abc');
      expect(error, equals('Please enter numbers only.'));
    });
  });

  group('Accepted', () {
    late Accepted rule;

    setUp(() {
      rule = Accepted();
    });

    test('name returns accepted', () {
      expect(rule.name, equals('accepted'));
    });

    test('passes for true boolean', () {
      expect(rule.validate('terms', true), isNull);
    });

    test('passes for 1 integer', () {
      expect(rule.validate('terms', 1), isNull);
    });

    test('passes for "1" string', () {
      expect(rule.validate('terms', '1'), isNull);
    });

    test('passes for "on" string', () {
      expect(rule.validate('terms', 'on'), isNull);
    });

    test('passes for "yes" string', () {
      expect(rule.validate('terms', 'yes'), isNull);
    });

    test('fails for false boolean', () {
      expect(rule.validate('terms', false), isNotNull);
    });

    test('fails for 0 integer', () {
      expect(rule.validate('terms', 0), isNotNull);
    });

    test('fails for null', () {
      expect(rule.validate('terms', null), isNotNull);
    });

    test('fails for empty string', () {
      expect(rule.validate('terms', ''), isNotNull);
    });
  });

  group('Confirmed', () {
    test('name returns confirmed', () {
      final rule = Confirmed('password_confirmation', 'password123');
      expect(rule.name, equals('confirmed'));
    });

    test('passes for null value', () {
      final rule = Confirmed('password_confirmation', 'password123');
      expect(rule.validate('password', null), isNull);
    });

    test('passes for empty string', () {
      final rule = Confirmed('password_confirmation', 'password123');
      expect(rule.validate('password', ''), isNull);
    });

    test('passes for matching values', () {
      final rule = Confirmed('password_confirmation', 'password123');
      expect(rule.validate('password', 'password123'), isNull);
    });

    test('fails for non-matching values', () {
      final rule = Confirmed('password_confirmation', 'differentPassword');
      expect(rule.validate('password', 'password123'), isNotNull);
    });

    test('error message includes field name', () {
      final rule = Confirmed('password_confirmation', 'different');
      final error = rule.validate('password', 'password123');
      expect(error, contains('password'));
      expect(error, contains('confirmation'));
    });
  });

  group('DateAfter', () {
    late DateAfter rule;

    setUp(() {
      rule = DateAfter(DateTime(2024, 1, 1));
    });

    test('name includes date', () {
      expect(rule.name, contains('2024-01-01'));
    });

    test('passes for null value', () {
      expect(rule.validate('start_date', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('start_date', ''), isNull);
    });

    test('passes for date after minimum', () {
      expect(rule.validate('start_date', DateTime(2024, 6, 15)), isNull);
    });

    test('passes for string date after minimum', () {
      expect(rule.validate('start_date', '2024-06-15'), isNull);
    });

    test('fails for date before minimum', () {
      expect(rule.validate('start_date', DateTime(2023, 12, 31)), isNotNull);
    });

    test('passes for date equal to minimum', () {
      // DateAfter uses isBefore, so equal dates pass (they're not before)
      expect(rule.validate('start_date', DateTime(2024, 1, 1)), isNull);
    });

    test('fails for invalid date string', () {
      expect(rule.validate('start_date', 'not-a-date'), isNotNull);
    });
  });

  group('DateBefore', () {
    late DateBefore rule;

    setUp(() {
      rule = DateBefore(DateTime(2024, 12, 31));
    });

    test('name includes date', () {
      expect(rule.name, contains('2024-12-31'));
    });

    test('passes for null value', () {
      expect(rule.validate('end_date', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('end_date', ''), isNull);
    });

    test('passes for date before maximum', () {
      expect(rule.validate('end_date', DateTime(2024, 6, 15)), isNull);
    });

    test('passes for string date before maximum', () {
      expect(rule.validate('end_date', '2024-06-15'), isNull);
    });

    test('fails for date after maximum', () {
      expect(rule.validate('end_date', DateTime(2025, 1, 1)), isNotNull);
    });

    test('passes for date equal to maximum', () {
      // DateBefore uses isAfter, so equal dates pass (they're not after)
      expect(rule.validate('end_date', DateTime(2024, 12, 31)), isNull);
    });

    test('fails for invalid date string', () {
      expect(rule.validate('end_date', 'not-a-date'), isNotNull);
    });
  });

  group('DateBetween', () {
    late DateBetween rule;

    setUp(() {
      rule = DateBetween(DateTime(2024, 1, 1), DateTime(2024, 12, 31));
    });

    test('name returns date_between', () {
      expect(rule.name, equals('date_between'));
    });

    test('passes for null value', () {
      expect(rule.validate('event_date', null), isNull);
    });

    test('passes for empty string', () {
      expect(rule.validate('event_date', ''), isNull);
    });

    test('passes for date within range', () {
      expect(rule.validate('event_date', DateTime(2024, 6, 15)), isNull);
    });

    test('passes for date at start of range', () {
      expect(rule.validate('event_date', DateTime(2024, 1, 1)), isNull);
    });

    test('passes for date at end of range', () {
      expect(rule.validate('event_date', DateTime(2024, 12, 31)), isNull);
    });

    test('fails for date before range', () {
      expect(rule.validate('event_date', DateTime(2023, 12, 31)), isNotNull);
    });

    test('fails for date after range', () {
      expect(rule.validate('event_date', DateTime(2025, 1, 1)), isNotNull);
    });

    test('fails for invalid date string', () {
      expect(rule.validate('event_date', 'not-a-date'), isNotNull);
    });
  });
}
