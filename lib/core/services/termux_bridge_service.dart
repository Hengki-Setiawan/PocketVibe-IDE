import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/termux_config.dart';

class TermuxBridgeService {
  static const _channel = MethodChannel(TermuxConfig.channelName);

  String? lastError;

  void _clearError() => lastError = null;

  Future<bool> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      _clearError();
      await _channel.invokeMethod(method, args);
      return true;
    } on PlatformException catch (e) {
      lastError = '[${e.code}] ${e.message}';
      debugPrint('TermuxBridgeService.$method error: $lastError');
      return false;
    } catch (e) {
      lastError = '$e';
      debugPrint('TermuxBridgeService.$method failed: $e');
      return false;
    }
  }

  Future<bool> isTermuxInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isTermuxInstalled') ?? false;
    } catch (e) {
      debugPrint('TermuxBridgeService.isTermuxInstalled failed: $e');
      return false;
    }
  }

  Future<bool> isTermuxApiInstalled() async {
    try {
      return await _channel.invokeMethod<bool>('isTermuxApiInstalled') ?? false;
    } catch (e) {
      debugPrint('TermuxBridgeService.isTermuxApiInstalled failed: $e');
      return false;
    }
  }

  Future<bool> runScript(String scriptPath, {List<String> args = const [], bool background = true}) async {
    return _invoke('runScript', {
      'path': scriptPath,
      'args': args,
      'background': background,
    });
  }

  Future<bool> runCommand(String command, {List<String> args = const [], bool background = true}) async {
    return _invoke('runCommand', {
      'command': command,
      'args': args,
      'background': background,
    });
  }

  Future<bool> checkFileExists(String path) async {
    try {
      return await _channel.invokeMethod('checkFileExists', {'path': path}) ?? false;
    } catch (e) {
      debugPrint('TermuxBridgeService.checkFileExists failed: $e');
      return false;
    }
  }
}
