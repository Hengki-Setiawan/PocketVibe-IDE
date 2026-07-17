import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'opencode_api_client.dart';
import 'project_storage_service.dart';
import 'secure_config_service.dart';

export 'opencode_api_client.dart';
export 'project_storage_service.dart';
export 'secure_config_service.dart';

final serverConfigProvider = StateProvider<({String host, int port})>(
  (_) => (host: '127.0.0.1', port: 4096),
);

final openCodeApiClientProvider = Provider<OpenCodeApiClient>((ref) {
  final cfg = ref.watch(serverConfigProvider);
  return OpenCodeApiClient(baseUrl: 'http://${cfg.host}:${cfg.port}');
});

final projectStorageServiceProvider = Provider<ProjectStorageService>((_) => ProjectStorageService());

final secureConfigServiceProvider = Provider<SecureConfigService>((_) => SecureConfigService());
