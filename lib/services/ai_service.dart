// A drop‑in replacement for DummyAIService that actually calls your Supabase Edge Function
// Assumes: `http` package is in pubspec, and you have a build‑time constant or env var containing
// the Supabase project URL.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service_interface.dart';
import '../utils/constants.dart';

class SupabaseAIService implements AIService {
  final Duration _timeout;

  const SupabaseAIService({
    Duration timeout = const Duration(minutes: 5),
  }) : _timeout = timeout;

  @override
  Future<Map<String, dynamic>> generateSettings(
    String content, {
    String? aiDocs,
    String? contentType,
  }) async {
    return _postJson(
      type: 'generateSettings',
      payload: {
        'content': content,
        if (aiDocs != null) 'aiDocs': aiDocs,
        if (contentType != null) 'contentType': contentType,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> generatePlotAnalysis(
    String content, {
    String? aiDocs,
    String? newContent,
  }) async {
    return _postJson(
      type: 'generatePlotAnalysis',
      payload: {
        'content': content,
        if (aiDocs != null) 'aiDocs': aiDocs,
        if (newContent != null) 'newContent': newContent,
      },
    );
  }

  @override
  Future<Map<String, String>> generateReview(String analysisContent) async {
    final raw = await _postJson(
      type: 'generateReview',
      payload: {'content': analysisContent},
    );
    return raw.cast<String, String>();
  }

  @override
  Future<List<String>> generateContinuations(
    String content, {
    String? aiDocs,
    String? newContent,
    String? settingInfo,
  }) async {
    final raw = await _postJson(
      type: 'generateContinuations',
      payload: {
        'content': content,
        if (aiDocs != null) 'aiDocs': aiDocs,
        if (newContent != null) 'newContent': newContent,
        if (settingInfo != null) 'settingInfo': settingInfo,
      },
    );
    return List<String>.from(raw['suggestions'] ?? []);
  }

  @override
  Future<String> expandSuggestion(
    String content,
    String suggestion, {
    String? aiDocs,
    String? recentContent,
  }) async {
    final raw = await _postJson(
      type: 'expandSuggestion',
      payload: {
        'content': content,
        'suggestion': suggestion,
        if (aiDocs != null) 'aiDocs': aiDocs,
        if (recentContent != null) 'recentContent': recentContent,
      },
    );
    return raw['expanded'] ?? '';
  }

  @override
  Future<Map<String, dynamic>> analyzeEmotion(
    String content, {
    String? aiDocs,
  }) async {
    return _postJson(
      type: 'analyzeEmotion',
      payload: {
        'content': content,
        if (aiDocs != null) 'aiDocs': aiDocs,
      },
    );
  }

  @override
  Future<String> generateAIDocs(
    String content, {
    String? settingInfo,
    String? plotInfo,
    String? emotionInfo,
  }) async {
    final raw = await _postJson(
      type: 'generateAIDocs',
      payload: {
        'content': content,
        if (settingInfo != null) 'settingInfo': settingInfo,
        if (plotInfo != null) 'plotInfo': plotInfo,
        if (emotionInfo != null) 'emotionInfo': emotionInfo,
      },
    );
    return raw['markdown'] ?? '';
  }

  Future<Map<String, dynamic>> _postJson({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final client = http.Client();

      final req = http.Request('POST', Uri.parse(supabaseFnUrl))
        ..headers['Content-Type'] = 'application/json'
        ..headers['Authorization'] =
            'Bearer ${Supabase.instance.client.auth.currentSession?.accessToken}'
        ..body = jsonEncode(payload); // ← 送るメッセージ

      final streamed =
          await client.send(req).timeout(const Duration(minutes: 2));

      await for (final chunk in streamed.stream.transform(utf8.decoder)) {
        for (final line in const LineSplitter().convert(chunk)) {
          if (line.startsWith('data:')) {
            final jsonStr = line.substring(5).trim();
            if (jsonStr == "[DONE]") break;

            try {
              final json = jsonDecode(jsonStr);
              final content = json["content"] ?? "";
              // 🔽 ここで逐次UIに表示するなど処理する
              debugPrint(content);
              return json; // Return the JSON response
            } catch (_) {
              debugPrint("⚠️ JSON decode error: $jsonStr");
            }
          }
        }
      }
      // If we get here without returning, return an empty map
      return {};
    } catch (e) {
      debugPrint("⚠️ Fetch error: $e");
      rethrow;
    }
  }
}
