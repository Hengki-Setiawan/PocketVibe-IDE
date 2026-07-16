import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureConfigService {
  final FlutterSecureStorage _storage;

  SecureConfigService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyProviderApiKey = 'provider_api_key';
  static const _keyProviderType = 'provider_type';
  static const _keyOpenCodeAuthToken = 'opencode_auth_token';

  Future<void> saveProviderApiKey(String key) async {
    try {
      await _storage.write(key: _keyProviderApiKey, value: key);
    } catch (e) {
      debugPrint('SecureConfigService.saveProviderApiKey failed: $e');
    }
  }

  Future<String?> getProviderApiKey() async {
    try {
      return await _storage.read(key: _keyProviderApiKey);
    } catch (e) {
      debugPrint('SecureConfigService.getProviderApiKey failed: $e');
      return null;
    }
  }

  Future<void> saveProviderType(String type) async {
    try {
      await _storage.write(key: _keyProviderType, value: type);
    } catch (e) {
      debugPrint('SecureConfigService.saveProviderType failed: $e');
    }
  }

  Future<String?> getProviderType() async {
    try {
      return await _storage.read(key: _keyProviderType);
    } catch (e) {
      debugPrint('SecureConfigService.getProviderType failed: $e');
      return null;
    }
  }

  Future<void> saveOpenCodeAuthToken(String token) async {
    try {
      await _storage.write(key: _keyOpenCodeAuthToken, value: token);
    } catch (e) {
      debugPrint('SecureConfigService.saveOpenCodeAuthToken failed: $e');
    }
  }

  Future<String?> getOpenCodeAuthToken() async {
    try {
      return await _storage.read(key: _keyOpenCodeAuthToken);
    } catch (e) {
      debugPrint('SecureConfigService.getOpenCodeAuthToken failed: $e');
      return null;
    }
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('SecureConfigService.clearAll failed: $e');
    }
  }

  Future<bool> hasApiKey() async {
    try {
      final key = await getProviderApiKey();
      return key != null && key.isNotEmpty;
    } catch (e) {
      debugPrint('SecureConfigService.hasApiKey failed: $e');
      return false;
    }
  }
}
