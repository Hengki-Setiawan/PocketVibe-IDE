import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/provider_manager.dart';
import '../models/connection_status.dart';

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final controller = StreamController<ConnectionStatus>();
  final api = ref.watch(openCodeApiClientProvider);
  Timer? timer;
  bool cancelled = false;

  void poll() async {
    if (cancelled) return;
    controller.add(ConnectionStatus.checking);
    try {
      final alive = await api.health();
      if (!cancelled) {
        controller.add(alive ? ConnectionStatus.connected : ConnectionStatus.disconnected);
      }
    } catch (e) {
      debugPrint('ConnectionStatusProvider poll failed: $e');
      if (!cancelled) {
        controller.add(ConnectionStatus.error);
      }
    }
    if (!cancelled) {
      timer = Timer(const Duration(seconds: 5), poll);
    }
  }

  ref.onDispose(() {
    cancelled = true;
    timer?.cancel();
    controller.close();
  });

  poll();
  return controller.stream;
});
