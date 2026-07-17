abstract class TermuxConfig {
  static const termuxPackage = 'com.termux';
  static const termuxApiPackage = 'com.termux.api';
  static const channelName = 'pocketvibe/termux_bridge';
  static const storageChannelName = 'pocketvibe/storage';

  static const defaultPort = 4096;
  static const defaultHost = '127.0.0.1';
  static const baseUrl = 'http://127.0.0.1:4096';

  static const readyMarkerFile = '/storage/emulated/0/.pocketvibe_ready';
  static const pocketVibeDir = '.pocketvibe';
  static const projectsDir = 'PocketVibeProjects';

  static const termuxHome = '/data/data/com.termux/files/home';

  static const bootstrapUrl = 'https://raw.githubusercontent.com/Hengki-Setiawan/PocketVibe-IDE/main/assets/termux_scripts/00_bootstrap.sh';

  static const healthCheckInterval = Duration(seconds: 5);
  static const pollInterval = Duration(seconds: 2);
  static const pollTimeout = Duration(minutes: 5);
  static const healthCheckRetries = 5;
  static const healthCheckRetryDelay = Duration(seconds: 2);
}
