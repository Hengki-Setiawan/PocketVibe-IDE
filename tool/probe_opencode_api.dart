import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args[0] : 'http://127.0.0.1:4096';

  print('=== PocketVibe OpenCode API Prober ===');
  print('Server: $host');
  print('');

  final client = HttpClient();
  client.connectionTimeout = const Duration(seconds: 5);

  try {
    final request = await client.getUrl(Uri.parse('$host/doc'));
    final response = await request.close();

    if (response.statusCode != 200) {
      print('Server tidak reachable (HTTP ${response.statusCode}).');
      print('Jalankan bootstrap dulu di Termux.');
      exit(1);
    }

    final body = await response.transform(utf8.decoder).join();
    final spec = jsonDecode(body) as Map<String, dynamic>;
    final paths = (spec['paths'] as Map?)?.keys.toList() ?? [];

    print('Endpoint tersedia:');
    for (final p in paths) {
      final methods = (spec['paths']![p] as Map).keys.join(', ');
      print('  $p -> $methods');
    }

    final snapshotFile = File('tool/opencode_openapi_snapshot.json');
    await snapshotFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(spec),
    );
    print('');
    print('Snapshot disimpan ke ${snapshotFile.path}');
    print('');

    if (paths.contains('/session')) {
      final sessionPath = paths.firstWhere(
        (p) => p.contains('/session') && !p.contains('{') || p == '/session',
        orElse: () => '/session',
      );
      print('Info: endpoint sesi ditemukan di $sessionPath');
    }

    client.close();
  } on SocketException catch (e) {
    print('Gagal terhubung ke $host');
    print('Error: $e');
    print('Pastikan opencode serve sudah berjalan di Termux.');
    exit(1);
  } catch (e) {
    print('Error tak terduga: $e');
    exit(1);
  }
}
