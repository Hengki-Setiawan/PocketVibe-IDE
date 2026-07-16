import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../constants/termux_config.dart';

class TermuxBridgeService {
  static const _channel = MethodChannel(TermuxConfig.channelName);

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

  Future<void> runScript(String scriptPath, {List<String> args = const [], bool background = true}) async {
    try {
      await _channel.invokeMethod('runScript', {
        'path': scriptPath,
        'args': args,
        'background': background,
      });
    } catch (e) {
      debugPrint('TermuxBridgeService.runScript failed: $e');
    }
  }

  Future<void> runCommand(String command, {List<String> args = const [], bool background = true}) async {
    try {
      await _channel.invokeMethod('runCommand', {
        'command': command,
        'args': args,
        'background': background,
      });
    } catch (e) {
      debugPrint('TermuxBridgeService.runCommand failed: $e');
    }
  }
}
