import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'termux_bridge_service.dart';
import 'opencode_api_client.dart';
import 'project_storage_service.dart';
import 'secure_config_service.dart';

export 'termux_bridge_service.dart';
export 'opencode_api_client.dart';
export 'project_storage_service.dart';
export 'secure_config_service.dart';

final termuxBridgeServiceProvider = Provider<TermuxBridgeService>((_) => TermuxBridgeService());

final openCodeApiClientProvider = Provider<OpenCodeApiClient>((_) => OpenCodeApiClient());

final projectStorageServiceProvider = Provider<ProjectStorageService>((_) => ProjectStorageService());

final secureConfigServiceProvider = Provider<SecureConfigService>((_) => SecureConfigService());
