import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Handles secure serialization and deserialization of component state.
///
/// State is encoded as JSON and signed with a checksum to prevent tampering.
/// This is similar to Laravel Livewire's approach to state security.
///
/// The serialized format is: `base64(json) + '.' + signature`
class ComponentState {
  /// Secret key for signing state (should be configured in Panel).
  /// For now using a default, but this should be injected.
  static String _secretKey = 'dash-wire-secret-key-change-me';

  /// Sets the secret key used for signing state.
  ///
  /// Should be called during Panel initialization with a secure key.
  static void setSecretKey(String key) {
    _secretKey = key;
  }

  /// Generates a random secret key.
  static String generateSecretKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  /// Serializes component state to a secure string.
  ///
  /// The output format is: `base64(json).signature`
  /// where signature = HMAC-SHA256(base64(json), secretKey)
  static String serialize(String componentId, Map<String, dynamic> state) {
    final payload = {'id': componentId, 'state': state, 'timestamp': DateTime.now().millisecondsSinceEpoch};

    final jsonString = jsonEncode(payload);
    final encoded = base64Url.encode(utf8.encode(jsonString));
    final signature = _sign(encoded);

    return '$encoded.$signature';
  }

  /// Deserializes component state from a secure string.
  ///
  /// Returns null if the signature is invalid or the format is wrong.
  static Map<String, dynamic>? deserialize(String serializedState) {
    try {
      final parts = serializedState.split('.');
      if (parts.length != 2) {
        return null;
      }

      final encoded = parts[0];
      final signature = parts[1];

      // Verify signature
      if (!_verify(encoded, signature)) {
        print('ComponentState: Invalid signature');
        return null;
      }

      // Decode payload
      final jsonString = utf8.decode(base64Url.decode(encoded));
      final payload = jsonDecode(jsonString) as Map<String, dynamic>;

      return payload['state'] as Map<String, dynamic>?;
    } catch (e) {
      print('ComponentState: Failed to deserialize - $e');
      return null;
    }
  }

  /// Extracts the component ID from serialized state without full deserialization.
  static String? extractComponentId(String serializedState) {
    try {
      final parts = serializedState.split('.');
      if (parts.length != 2) return null;

      final encoded = parts[0];
      final jsonString = utf8.decode(base64Url.decode(encoded));
      final payload = jsonDecode(jsonString) as Map<String, dynamic>;

      return payload['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Creates a HMAC-SHA256 signature for the given data.
  static String _sign(String data) {
    final key = utf8.encode(_secretKey);
    final bytes = utf8.encode(data);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    return digest.toString();
  }

  /// Verifies a signature against the given data.
  static bool _verify(String data, String signature) {
    final expected = _sign(data);
    return _secureCompare(expected, signature);
  }

  /// Constant-time string comparison to prevent timing attacks.
  static bool _secureCompare(String a, String b) {
    if (a.length != b.length) return false;

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

/// Extension on Map for convenient state operations.
extension StateMapExtensions on Map<String, dynamic> {
  /// Gets a value with type casting and optional default.
  T? getValue<T>(String key, [T? defaultValue]) {
    final value = this[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Gets an int value, parsing from string if necessary.
  int getInt(String key, [int defaultValue = 0]) {
    final value = this[key];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? defaultValue;
    if (value is double) return value.toInt();
    return defaultValue;
  }

  /// Gets a double value, parsing from string if necessary.
  double getDouble(String key, [double defaultValue = 0.0]) {
    final value = this[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  /// Gets a bool value, parsing from string if necessary.
  bool getBool(String key, [bool defaultValue = false]) {
    final value = this[key];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// Gets a string value.
  String getString(String key, [String defaultValue = '']) {
    final value = this[key];
    if (value is String) return value;
    if (value != null) return value.toString();
    return defaultValue;
  }

  /// Gets a list value.
  List<T> getList<T>(String key, [List<T> defaultValue = const []]) {
    final value = this[key];
    if (value is List) return value.cast<T>();
    return defaultValue;
  }
}
