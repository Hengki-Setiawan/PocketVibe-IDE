import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/provider_manager.dart';
import '../core/services/setup_orchestrator.dart';
import '../models/setup_step.dart';

final setupProvider = StateNotifierProvider<SetupOrchestrator, SetupStep>((ref) {
  return SetupOrchestrator(
    ref.watch(termuxBridgeServiceProvider),
    ref.watch(openCodeApiClientProvider),
    ref.watch(projectStorageServiceProvider),
  );
});
