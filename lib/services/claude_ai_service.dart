import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'ai_service_interface.dart';
import '../utils/constants.dart';

class ClaudeAIService implements AIService {
  final String _endpoint;

  ClaudeAIService({String? claudeGatewayUrl})
      : _endpoint = claudeGatewayUrl ??
            'https://awbrfvdyokwkpwrqmfwd.supabase.co/functions/v1/claude-gateway';

  Future<dynamic> _postToClaude(
      String type, Map<String, dynamic> payload) async {
    try {
      developer.log('Sending request to Claude API: $type',
          name: 'ClaudeAIService');

      // Enhanced headers for CORS support
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Origin': 'https://tomofude.app', // Add your app's origin
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers':
            'content-type,authorization,x-client-info,apikey',
      };

      final requestBody = jsonEncode({
        'type': type,
        ...payload,
      });

      developer.log('Request headers: $headers', name: 'ClaudeAIService');
      developer.log('Request body: $requestBody', name: 'ClaudeAIService');

      // Add timeout to prevent hanging requests
      final response = await http
          .post(
        Uri.parse(_endpoint),
        headers: headers,
        body: requestBody,
      )
          .timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Request timed out after 30 seconds');
        },
      );

      developer.log('Response status: ${response.statusCode}',
          name: 'ClaudeAIService');
      developer.log('Response headers: ${response.headers}',
          name: 'ClaudeAIService');

      if (response.statusCode == 200) {
        final responseBody = response.body;
        developer.log('Response body: $responseBody', name: 'ClaudeAIService');
        return jsonDecode(responseBody);
      } else {
        developer.log('Error response: ${response.body}',
            name: 'ClaudeAIService');
        throw Exception(
            'Claude API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Exception in _postToClaude: $e',
          name: 'ClaudeAIService', error: e);

      // If it's a "Failed to fetch" or network-related error, it might be a CORS issue
      if (e.toString().contains('Failed to fetch') ||
          e.toString().contains('XMLHttpRequest error') ||
          e.toString().contains('Network error')) {
        throw Exception(
            'CORS or network error: $e. Please check server CORS configuration.');
      }

      rethrow;
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

  /// Supabase Function を使用して Claude に直接リクエストを送信する
  ///
  /// [userInput] ユーザーの入力テキスト
  /// [buildMessageList] メッセージリストを構築する関数
  /// [buildSystemPrompt] システムプロンプトを構築する関数（オプション）
  Future<Map<String, dynamic>> postToSupabaseClaude(String userInput,
      List<Map<String, String>> Function(String) buildMessageList,
      {String Function()? buildSystemPrompt}) async {
    try {
      developer.log('Sending request to Supabase Claude Gateway',
          name: 'ClaudeAIService');

      final response = await http
          .post(
            Uri.parse(supabaseFnUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system': buildSystemPrompt != null ? buildSystemPrompt() : null,
              'messages': buildMessageList(userInput),
              'max_tokens': 1024,
            }),
          )
          .timeout(const Duration(minutes: 5));

      developer.log('Response status: ${response.statusCode}',
          name: 'ClaudeAIService');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        developer.log('Response data: $data', name: 'ClaudeAIService');
        return data;
      } else {
        developer.log('Error response: ${response.body}',
            name: 'ClaudeAIService');
        throw Exception(
            'Claude error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      developer.log('Exception in postToSupabaseClaude: $e',
          name: 'ClaudeAIService', error: e);
      rethrow;
    }
  }
}
