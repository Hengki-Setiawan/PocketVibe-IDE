import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import '../constants/termux_config.dart';

class OpenCodeApiClient {
  final Dio _dio;
  final String baseUrl;

  OpenCodeApiClient({this.baseUrl = TermuxConfig.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 30),
        ));

  Future<bool> ping() async {
    try {
      final res = await _dio.get('/doc');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('OpenCodeApiClient.ping failed: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchOpenApiSpec() async {
    try {
      final res = await _dio.get('/doc');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        return res.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('OpenCodeApiClient.fetchOpenApiSpec failed: $e');
      return null;
    }
  }

  Future<String?> createSession({required String projectPath}) async {
    try {
      final res = await _dio.post('/session', data: {'path': projectPath});
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

  Stream<String> sendMessage({
    required String sessionId,
    required String prompt,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '/session/$sessionId/message',
        data: {'text': prompt},
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      if (response.data == null) {
        debugPrint('OpenCodeApiClient.sendMessage: response.data is null');
        return;
      }

      final stream = response.data!.stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final payload = line.substring(6);
          if (payload.trim().isEmpty || payload == '[DONE]') continue;
          yield payload;
        }
      }
    } catch (e) {
      debugPrint('OpenCodeApiClient.sendMessage failed: $e');
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
}
