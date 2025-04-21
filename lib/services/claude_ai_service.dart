import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service_interface.dart';

class ClaudeAIService implements AIService {
  final String _endpoint;

  ClaudeAIService({String? claudeGatewayUrl})
      : _endpoint = claudeGatewayUrl ??
            'https://awbrfvdyokwkpwrqmfwd.functions.supabase.co/claude-gateway';

  Future<dynamic> _postToClaude(
      String type, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': type,
        ...payload,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          'Claude API error: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Future<Map<String, dynamic>> generateSettings(String content,
      {String? aiDocs, String? contentType}) async {
    final result = await _postToClaude('generateSettings', {
      'content': content,
      'aiDocs': aiDocs,
      'contentType': contentType,
    });
    return result;
  }

  @override
  Future<Map<String, dynamic>> generatePlotAnalysis(String content,
      {String? aiDocs, String? newContent}) async {
    final result = await _postToClaude('generatePlotAnalysis', {
      'content': content,
      'aiDocs': aiDocs,
      'newContent': newContent,
    });
    return result;
  }

  @override
  Future<Map<String, String>> generateReview(String analysisContent) async {
    final result = await _postToClaude('generateReview', {
      'analysisContent': analysisContent,
    });
    return Map<String, String>.from(result);
  }

  @override
  Future<List<String>> generateContinuations(String content,
      {String? aiDocs, String? newContent, String? settingInfo}) async {
    final result = await _postToClaude('generateContinuations', {
      'content': content,
      'aiDocs': aiDocs,
      'newContent': newContent,
      'settingInfo': settingInfo,
    });
    return List<String>.from(result['suggestions']);
  }

  @override
  Future<String> expandSuggestion(String content, String suggestion,
      {String? aiDocs, String? recentContent}) async {
    final result = await _postToClaude('expandSuggestion', {
      'content': content,
      'suggestion': suggestion,
      'aiDocs': aiDocs,
      'recentContent': recentContent,
    });
    return result['expanded'];
  }

  @override
  Future<Map<String, dynamic>> analyzeEmotion(String content,
      {String? aiDocs}) async {
    final result = await _postToClaude('analyzeEmotion', {
      'content': content,
      'aiDocs': aiDocs,
    });
    return result;
  }

  @override
  Future<String> generateAIDocs(String content,
      {String? settingInfo, String? plotInfo, String? emotionInfo}) async {
    final result = await _postToClaude('generateAIDocs', {
      'content': content,
      'settingInfo': settingInfo,
      'plotInfo': plotInfo,
      'emotionInfo': emotionInfo,
    });
    return result['markdown'];
  }
}
