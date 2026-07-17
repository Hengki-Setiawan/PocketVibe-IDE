import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/termux_config.dart';

class StoragePermissionHelper {
  static const _channel = MethodChannel(TermuxConfig.storageChannelName);

  static Future<bool> hasFullStorageAccess() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasFullStorageAccess');
      return result ?? false;
    } catch (e) {
      debugPrint('StoragePermissionHelper.hasFullStorageAccess error: $e');
      return false;
    }
  }

  static Future<bool> requestFullStorageAccess() async {
    try {
      await _channel.invokeMethod('requestFullStorageAccess');
      return true;
    } catch (e) {
      debugPrint('StoragePermissionHelper.requestFullStorageAccess error: $e');
      return false;
    }
  }
}
