import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'ai_service_interface.dart';
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
      // Ensure session validity before making the request
      try {
        final sessionValid = await _supabaseService.ensureValidSession();
        if (!sessionValid) {
          developer.log('Failed to ensure valid session',
              name: 'ClaudeAIService');
          throw Exception(
              'User not authenticated or session expired. Please log in again.');
        }
      } catch (e) {
        developer.log('Error ensuring valid session: $e',
            name: 'ClaudeAIService', error: e);
        throw Exception('Authentication error: $e');
      }

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
      'messages': [
        {'role': 'user', 'content': content}
      ],
      'aiDocs': aiDocs,
      'contentType': contentType,
    });
    return result;
  }

  @override
  Future<Map<String, dynamic>> generatePlotAnalysis(String content,
      {String? aiDocs, String? newContent}) async {
    final result = await _postToClaude('generatePlotAnalysis', {
      'messages': [
        {'role': 'user', 'content': content}
      ],
      'aiDocs': aiDocs,
      'newContent': newContent,
    });
    return result;
  }

  @override
  Future<Map<String, String>> generateReview(String analysisContent) async {
    final result = await _postToClaude('generateReview', {
      'messages': [
        {'role': 'user', 'content': analysisContent}
      ],
    });
    return Map<String, String>.from(result);
  }

  @override
  Future<List<String>> generateContinuations(String content,
      {String? aiDocs, String? newContent, String? settingInfo}) async {
    final result = await _postToClaude('generateContinuations', {
      'messages': [
        {'role': 'user', 'content': content}
      ],
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
      'messages': [
        {'role': 'user', 'content': '$content\n\nSuggestion: $suggestion'}
      ],
      'aiDocs': aiDocs,
      'recentContent': recentContent,
    });
    return result['expanded'];
  }

  @override
  Future<Map<String, dynamic>> analyzeEmotion(String content,
      {String? aiDocs}) async {
    final result = await _postToClaude('analyzeEmotion', {
      'messages': [
        {'role': 'user', 'content': content}
      ],
      'aiDocs': aiDocs,
    });
    return result;
  }

  @override
  Future<String> generateAIDocs(String content,
      {String? settingInfo, String? plotInfo, String? emotionInfo}) async {
    // Combine all information into a single message
    String fullContent = content;
    if (settingInfo != null) fullContent += '\n\nSetting Info: $settingInfo';
    if (plotInfo != null) fullContent += '\n\nPlot Info: $plotInfo';
    if (emotionInfo != null) fullContent += '\n\nEmotion Info: $emotionInfo';

    final result = await _postToClaude('generateAIDocs', {
      'messages': [
        {'role': 'user', 'content': fullContent}
      ],
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
      // Ensure session validity before making the request
      try {
        final sessionValid = await _supabaseService.ensureValidSession();
        if (!sessionValid) {
          developer.log('Failed to ensure valid session',
              name: 'ClaudeAIService');
          throw Exception(
              'User not authenticated or session expired. Please log in again.');
        }
      } catch (e) {
        developer.log('Error ensuring valid session: $e',
            name: 'ClaudeAIService', error: e);
        throw Exception('Authentication error: $e');
      }

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
    // Check and ensure session validity before making the request
    try {
      final sessionValid = await _supabaseService.ensureValidSession();
      if (!sessionValid) {
        developer.log('Failed to ensure valid session',
            name: 'ClaudeAIService');
        throw Exception(
            'User not authenticated or session expired. Please log in again.');
      }
    } catch (e) {
      developer.log('Error ensuring valid session: $e',
          name: 'ClaudeAIService', error: e);
      throw Exception('Authentication error: $e');
    }

    // Use async* for streams
    final uri = Uri.parse(_endpoint);
    final client = http.Client();
    final request = http.Request('POST', uri);

    // Get the access token after ensuring session is valid
    final accessToken =
        _supabaseService.client.auth.currentSession?.accessToken;
    // Use the public anon key from the Supabase service interface
    final anonKey = _supabaseService.supabaseAnonKey;

    if (accessToken == null) {
      // This should not happen after ensureValidSession, but check anyway
      developer.log('User session invalid or expired after refresh attempt.',
          name: 'ClaudeAIService');
      throw Exception(
          'User not authenticated or session expired after refresh attempt.');
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
    developer.log('📤 REQUEST >>> ${request.body}', name: 'ClaudeAIService');

    try {
      final response = await client
          .send(request)
          .timeout(const Duration(minutes: 5)); // Add timeout

      developer.log('Streaming response status: ${response.statusCode}',
          name: 'ClaudeAIService');

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        developer.log('❌ ERROR BODY <<< $errorBody', name: 'ClaudeAIService');
        throw Exception(
            'Claude streaming error ${response.statusCode}: $errorBody');
      }

      // Yield chunks from the stream
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        developer.log('Received stream chunk: $chunk',
            name: 'ClaudeAIService'); // Log received chunks
        yield chunk;
      }
      developer.log('Stream finished.', name: 'ClaudeAIService');
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
