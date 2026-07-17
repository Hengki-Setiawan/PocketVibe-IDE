import 'dart:convert';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class OpenCodeApiClient {
  final Dio _dio;
  final String baseUrl;
  String? _directory;
  String? _username;
  String? _password;

  OpenCodeApiClient({this.baseUrl = 'http://127.0.0.1:4096'})
      : _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 30),
        ));

  void setDirectory(String path) {
    _directory = path;
  }

  void setAuth(String username, String password) {
    _username = username;
    _password = password;
  }

  Map<String, String> get _headers {
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_directory != null) {
      h['x-opencode-directory'] = _directory!;
    }
    if (_username != null && _password != null) {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      h['Authorization'] = 'Basic $credentials';
    }
    return h;
  }

  Future<bool> health() async {
    try {
      final res = await _dio.get(
        '$baseUrl/global/health',
        options: Options(headers: _headers),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCodeApiClient.health failed: $e');
      return false;
    }
  }

  Future<String?> createSession({String title = 'PocketVibe Session'}) async {
    try {
      final res = await _dio.post(
        '$baseUrl/session',
        data: {'title': title},
        options: Options(headers: _headers),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final id = (res.data as Map<String, dynamic>)['id'];
        if (id is String) return id;
      }
      return null;
    } catch (e) {
      debugPrint('OpenCodeApiClient.createSession failed: $e');
      return null;
    }
  }

  Future<String> sendMessage({
    required String sessionId,
    required String prompt,
  }) async {
    try {
      final response = await _dio.post(
        '$baseUrl/session/$sessionId/message',
        data: {
          'parts': [
            {'type': 'text', 'text': prompt},
          ],
        },
        options: Options(
          headers: _headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 10),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Server error (${response.statusCode}). Pastikan OpenCode berjalan dengan benar.');
      }
      if (response.data == null || response.data is! Map) {
        throw Exception(
          'AI tidak membalas. Periksa API key provider di Settings > Provider AI, '
          'atau pastikan koneksi ke OpenCode server aktif.',
        );
      }

      final body = response.data as Map<String, dynamic>;
      final parts = body['parts'] as List<dynamic>? ?? [];
      final textParts = parts
          .whereType<Map<String, dynamic>>()
          .where((p) => p['type'] == 'text')
          .map((p) => p['text'] as String? ?? '')
          .join('\n');

      return textParts;
    } catch (e) {
      debugPrint('OpenCodeApiClient.sendMessage failed: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> streamSessionEvents(String sessionId) async* {
    try {
      final response = await _dio.get<ResponseBody>(
        '$baseUrl/global/event',
        queryParameters: {'session': sessionId},
        options: Options(
          responseType: ResponseType.stream,
          headers: {..._headers, 'Accept': 'text/event-stream'},
        ),
      );

      if (response.data == null) return;

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String? eventType;
      await for (final line in stream) {
        if (line.startsWith('event: ')) {
          eventType = line.substring(7);
        } else if (line.startsWith('data: ')) {
          final data = line.substring(6).trim();
          if (data.isEmpty || data == '[DONE]') continue;
          try {
            final parsed = jsonDecode(data) as Map<String, dynamic>;
            if (eventType != null) {
              parsed['_event'] = eventType;
              eventType = null;
            }
            yield parsed;
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('OpenCodeApiClient.streamSessionEvents failed: $e');
      rethrow;
    }
  }

  Future<bool> setProviderAuth(String providerId, String apiKey) async {
    try {
      final res = await _dio.put(
        '$baseUrl/auth/$providerId',
        data: {'apiKey': apiKey},
        options: Options(headers: _headers),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCodeApiClient.setProviderAuth failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listSessions() async {
    try {
      final res = await _dio.get(
        '$baseUrl/session',
        options: Options(headers: _headers),
      );
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('OpenCodeApiClient.listSessions failed: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    try {
      final res = await _dio.get(
        '$baseUrl/session/$sessionId',
        options: Options(headers: _headers),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('OpenCodeApiClient.getSession failed: $e');
      return null;
    }
  }

  Future<bool> abortSession(String sessionId) async {
    try {
      final res = await _dio.post(
        '$baseUrl/session/$sessionId/abort',
        options: Options(headers: _headers),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCodeApiClient.abortSession failed: $e');
      return false;
    }
  }

  Future<bool> summarizeSession(String sessionId) async {
    try {
      final res = await _dio.post(
        '$baseUrl/session/$sessionId/summarize',
        options: Options(headers: _headers),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCodeApiClient.summarizeSession failed: $e');
      return false;
    }
  }

  Future<bool> revertMessage(String sessionId, {String? messageId}) async {
    try {
      final data = <String, dynamic>{};
      if (messageId != null) data['messageID'] = messageId;
      final res = await _dio.post(
        '$baseUrl/session/$sessionId/revert',
        data: data,
        options: Options(headers: _headers),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCodeApiClient.revertMessage failed: $e');
      return false;
    }
  }

  Future<bool> unrevertSession(String sessionId) async {
    try {
      final res = await _dio.post(
        '$baseUrl/session/$sessionId/unrevert',
        options: Options(headers: _headers),
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCodeApiClient.unrevertSession failed: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> listMessages(String sessionId, {int? limit}) async {
    try {
      final params = <String, dynamic>{};
      if (limit != null) params['limit'] = limit;
      final res = await _dio.get(
        '$baseUrl/session/$sessionId/message',
        queryParameters: params,
        options: Options(headers: _headers),
      );
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('OpenCodeApiClient.listMessages failed: $e');
      return [];
    }
  }

  void dispose() {
    _dio.close();
  }
}
