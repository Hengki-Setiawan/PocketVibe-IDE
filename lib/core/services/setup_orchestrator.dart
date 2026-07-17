import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/setup_step.dart';
import '../constants/termux_config.dart';
import 'termux_bridge_service.dart';
import 'opencode_api_client.dart';
import 'project_storage_service.dart';

class SetupOrchestrator extends StateNotifier<SetupStep> {
  final TermuxBridgeService bridge;
  final OpenCodeApiClient api;
  final ProjectStorageService storage;
  bool _hasStarted = false;

  SetupOrchestrator(this.bridge, this.api, this.storage) : super(SetupStep.notStarted);

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

  String? lastError;

  Future<void> continueAfterBootstrap() async {
    if (state == SetupStep.done) return;

    state = SetupStep.installingOpenCode;
    await Future.delayed(const Duration(milliseconds: 500));
    lastError = null;

    // Server sudah jalan dari bootstrap? Cek langsung.
    state = SetupStep.healthCheck;
    if (await _retryHealthCheck(retries: 2)) {
      state = SetupStep.done;
      return;
    }

    // Coba start server via bridge
    state = SetupStep.startingServer;
    const scriptBase = '${TermuxConfig.termuxHome}/${TermuxConfig.pocketVibeDir}';
    if (!await bridge.runScript('$scriptBase/02_start_server.sh')) {
      lastError = bridge.lastError;
      state = SetupStep.failed;
      return;
    }
    await Future.delayed(const Duration(seconds: 3));

    state = SetupStep.healthCheck;
    final ok = await _retryHealthCheck();
    state = ok ? SetupStep.done : SetupStep.failed;
  }

  Future<bool> attemptRestartServer() async {
    const scriptBase = '${TermuxConfig.termuxHome}/${TermuxConfig.pocketVibeDir}';
    state = SetupStep.startingServer;
    final ok2 = await bridge.runScript('$scriptBase/02_start_server.sh');
    if (!ok2) {
      lastError = bridge.lastError;
      state = SetupStep.failed;
      return false;
    }
    await Future.delayed(const Duration(seconds: 3));
    final ok = await _retryHealthCheck(retries: 10);
    state = ok ? SetupStep.done : SetupStep.failed;
    return ok;
  }

  Future<bool> _retryHealthCheck({int? retries}) async {
    for (var i = 0; i < (retries ?? TermuxConfig.healthCheckRetries); i++) {
      await Future.delayed(TermuxConfig.healthCheckRetryDelay);
      if (await api.ping()) return true;
    }
    return false;
  }

  void reset() {
    _hasStarted = false;
    state = SetupStep.notStarted;
  }

  bool get hasStarted => _hasStarted;
}
