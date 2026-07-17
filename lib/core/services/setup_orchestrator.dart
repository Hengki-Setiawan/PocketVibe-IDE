import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/setup_step.dart';
import 'termux_bridge_service.dart';
import 'opencode_api_client.dart';
import 'project_storage_service.dart';
import '../constants/termux_config.dart';

class SetupOrchestrator extends StateNotifier<SetupStep> {
  final TermuxBridgeService bridge;
  final OpenCodeApiClient api;
  final ProjectStorageService storage;
  Timer? _pollTimer;
  Timer? _timeoutTimer;
  bool _hasStarted = false;

  SetupOrchestrator(this.bridge, this.api, this.storage) : super(SetupStep.notStarted);

  @override
  void dispose() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> begin() async {
    if (state.index >= SetupStep.checkingTermux.index && _hasStarted) return;
    _hasStarted = true;

    state = SetupStep.checkingTermux;
    final termuxInstalled = await bridge.isTermuxInstalled();
    if (!termuxInstalled) {
      state = SetupStep.promptInstallTermux;
      return;
    }

    state = SetupStep.checkingTermuxApi;
    final apiInstalled = await bridge.isTermuxApiInstalled();
    if (!apiInstalled) {
      state = SetupStep.promptInstallTermuxApi;
      return;
    }

    state = SetupStep.requestPermission;
    await Future.delayed(const Duration(milliseconds: 500));
    state = SetupStep.promptBootstrap;
  }

  void onTermuxConfirmed() {
    if (state == SetupStep.promptInstallTermux) {
      state = SetupStep.checkingTermux;
      _recheck();
    }
  }

  void onTermuxApiConfirmed() {
    if (state == SetupStep.promptInstallTermuxApi) {
      state = SetupStep.checkingTermuxApi;
      _recheck();
    }
  }

  Future<void> _recheck() async {
    final termuxInstalled = await bridge.isTermuxInstalled();
    if (state == SetupStep.checkingTermux) {
      if (!termuxInstalled) {
        state = SetupStep.promptInstallTermux;
        return;
      }
      state = SetupStep.checkingTermuxApi;
    }

    final apiInstalled = await bridge.isTermuxApiInstalled();
    if (state == SetupStep.checkingTermuxApi) {
      if (!apiInstalled) {
        state = SetupStep.promptInstallTermuxApi;
        return;
      }
      state = SetupStep.requestPermission;
      await Future.delayed(const Duration(milliseconds: 500));
      state = SetupStep.promptBootstrap;
    }
  }

  void onBootstrapDone() {
    if (state != SetupStep.promptBootstrap) return;
    state = SetupStep.waitingBootstrapSignal;
    startPollingBootstrapSignal();
  }

  void startPollingBootstrapSignal() {
    _pollTimer = Timer.periodic(TermuxConfig.pollInterval, (t) async {
      try {
        final ready = await bridge.checkFileExists(TermuxConfig.readyMarkerFile);
        if (ready) {
          t.cancel();
          _timeoutTimer?.cancel();
          state = SetupStep.installingOpenCode;
          await _runInstallSequence();
        }
      } catch (e) {
        debugPrint('SetupOrchestrator poll error: $e');
      }
    });

    _timeoutTimer = Timer(TermuxConfig.pollTimeout, () {
      if (state == SetupStep.waitingBootstrapSignal) {
        _pollTimer?.cancel();
        state = SetupStep.failed;
      }
    });
  }

  Future<void> _runInstallSequence() async {
    const scriptBase = '${TermuxConfig.termuxHome}/${TermuxConfig.pocketVibeDir}';

    try {
      await bridge.runScript('$scriptBase/01_install_opencode.sh');
      await Future.delayed(const Duration(seconds: 3));

      state = SetupStep.startingServer;
      await bridge.runScript('$scriptBase/02_start_server.sh');
      await Future.delayed(const Duration(seconds: 2));

      state = SetupStep.healthCheck;
      final ok = await _retryHealthCheck();
      state = ok ? SetupStep.done : SetupStep.failed;
    } catch (e) {
      debugPrint('SetupOrchestrator._runInstallSequence failed: $e');
      state = SetupStep.failed;
    }
  }

  Future<bool> attemptRestartServer() async {
    const scriptBase = '${TermuxConfig.termuxHome}/${TermuxConfig.pocketVibeDir}';
    state = SetupStep.startingServer;
    try {
      await bridge.runScript('$scriptBase/02_start_server.sh');
      await Future.delayed(const Duration(seconds: 3));
      final ok = await _retryHealthCheck(retries: 10);
      state = ok ? SetupStep.done : SetupStep.failed;
      return ok;
    } catch (e) {
      debugPrint('SetupOrchestrator.attemptRestartServer failed: $e');
      state = SetupStep.failed;
      return false;
    }
  }

  Future<bool> _retryHealthCheck({int? retries}) async {
    for (var i = 0; i < (retries ?? TermuxConfig.healthCheckRetries); i++) {
      await Future.delayed(TermuxConfig.healthCheckRetryDelay);
      if (await api.ping()) return true;
    }
    return false;
  }

  void reset() {
    _pollTimer?.cancel();
    _timeoutTimer?.cancel();
    _hasStarted = false;
    state = SetupStep.notStarted;
  }

  bool get hasStarted => _hasStarted;
}
