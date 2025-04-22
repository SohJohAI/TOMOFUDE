import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'ai_service_interface.dart';
import '../utils/constants.dart';
import 'supabase_service_interface.dart';
import 'service_locator.dart';

class ClaudeAIService implements AIService {
  final String _endpoint;
  final SupabaseServiceInterface _supabaseService;

  ClaudeAIService({String? claudeGatewayUrl})
      : _endpoint = claudeGatewayUrl ??
            'https://awbrfvdyokwkpwrqmfwd.supabase.co/functions/v1/claude-gateway',
        _supabaseService = serviceLocator<SupabaseServiceInterface>();

  Future<dynamic> _postToClaude(
      String type, Map<String, dynamic> payload) async {
    try {
      developer.log('Sending request to Claude API: $type',
          name: 'ClaudeAIService');

      final requestBody = {
        'type': type,
        ...payload,
      };

      developer.log('Request body: $requestBody', name: 'ClaudeAIService');

      // Use Supabase SDK's functions.invoke() method
      final response = await _supabaseService.client.functions
          .invoke(
        'claude-gateway',
        body: requestBody,
      )
          .timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Request timed out after 5 minutes');
        },
      );

      developer.log('Response status: ${response.status}',
          name: 'ClaudeAIService');

      if (response.status == 200) {
        final data = response.data;
        developer.log('Response data: $data', name: 'ClaudeAIService');
        return data;
      } else {
        developer.log('Error response status: ${response.status}',
            name: 'ClaudeAIService');
        throw Exception('Claude API error: ${response.status}');
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

      final requestBody = {
        'system': buildSystemPrompt != null ? buildSystemPrompt() : null,
        'messages': buildMessageList(userInput),
        'max_tokens': 1024,
      };

      // Use Supabase SDK's functions.invoke() method
      final response = await _supabaseService.client.functions
          .invoke(
            'claude-gateway',
            body: requestBody,
          )
          .timeout(const Duration(minutes: 5));

      developer.log('Response status: ${response.status}',
          name: 'ClaudeAIService');

      if (response.status == 200) {
        final data = response.data;
        developer.log('Response data: $data', name: 'ClaudeAIService');
        return Map<String, dynamic>.from(data);
      } else {
        developer.log('Error response status: ${response.status}',
            name: 'ClaudeAIService');
        throw Exception('Claude error ${response.status}');
      }
    } catch (e) {
      developer.log('Exception in postToSupabaseClaude: $e',
          name: 'ClaudeAIService', error: e);
      rethrow;
    }
  }

  /// Calls the Claude gateway function to get a streaming response.
  ///
  /// Returns a stream of raw SSE event strings. The caller is responsible
  /// for parsing these events (e.g., lines starting with "data: ").
  Stream<String> streamFromClaude(
    String userInput,
    List<Map<String, String>> Function(String) buildMessageList, {
    String Function()? buildSystemPrompt,
    String model = "claude-3-sonnet-20240229", // Or your preferred default
    int maxTokens = 1024,
  }) async* {
    // Use async* for streams
    final uri = Uri.parse(_endpoint);
    final client = http.Client();
    final request = http.Request('POST', uri);

    final accessToken =
        _supabaseService.client.auth.currentSession?.accessToken;
    // Use the public anon key from the Supabase service interface
    final anonKey = _supabaseService.supabaseAnonKey;

    if (accessToken == null) {
      // It's often better to let Supabase handle token refresh automatically,
      // but check if the session is valid. If not, throw an error.
      developer.log('User session invalid or expired.',
          name: 'ClaudeAIService');
      throw Exception('User not authenticated or session expired.');
    }
    if (anonKey == null) {
      developer.log('Supabase anon key is missing.', name: 'ClaudeAIService');
      throw Exception(
          'Supabase client not properly initialized (missing anon key).');
    }

    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
      'apikey': anonKey, // Use the actual anon key
      // Add other headers if required by your Supabase function policies
    });

    // Construct the body based on the Edge Function's expectation
    // It seems the function expects 'messages', 'system', 'model', 'max_tokens', 'stream'
    final requestBody = {
      'model': model,
      'max_tokens': maxTokens,
      'stream': true, // Ensure streaming is requested
      'system': buildSystemPrompt != null ? buildSystemPrompt() : null,
      'messages': buildMessageList(userInput),
      // Note: The Edge function uses 'messages', not 'content' directly in the body for the API call
    };

    request.body = jsonEncode(requestBody);
    developer.log('Streaming request body: ${request.body}',
        name: 'ClaudeAIService');

    try {
      final response = await client
          .send(request)
          .timeout(const Duration(minutes: 5)); // Add timeout

      developer.log('Streaming response status: ${response.statusCode}',
          name: 'ClaudeAIService');

      if (response.statusCode == 200) {
        // Yield chunks from the stream
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          developer.log('Received stream chunk: $chunk',
              name: 'ClaudeAIService'); // Log received chunks
          yield chunk;
        }
        developer.log('Stream finished.', name: 'ClaudeAIService');
      } else {
        // Handle non-200 responses (errors)
        final errorBody = await response.stream.bytesToString();
        developer.log(
            'Error streaming from Claude: ${response.statusCode} - $errorBody',
            name: 'ClaudeAIService');
        throw Exception(
            'Claude streaming error ${response.statusCode}: $errorBody');
      }
    } catch (e, stackTrace) {
      // Catch stackTrace
      developer.log('Exception during streaming: $e\n$stackTrace',
          name: 'ClaudeAIService',
          error: e,
          stackTrace: stackTrace); // Log stacktrace
      // Rethrow specific exception types if needed, or a generic one
      throw Exception('Failed to stream from Claude: $e');
    } finally {
      client.close(); // Ensure the client is closed
      developer.log('HTTP client closed.', name: 'ClaudeAIService');
    }
  }
}
