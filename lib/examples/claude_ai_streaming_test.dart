import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/claude_ai_service.dart';
import '../services/supabase_service_interface.dart';
import '../services/service_locator.dart';

/// A test widget to demonstrate Claude AI streaming functionality
class ClaudeAIStreamingTest extends StatefulWidget {
  const ClaudeAIStreamingTest({Key? key}) : super(key: key);

  @override
  State<ClaudeAIStreamingTest> createState() => _ClaudeAIStreamingTestState();
}

class _ClaudeAIStreamingTestState extends State<ClaudeAIStreamingTest> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedText = '';
  bool _isLoading = false;
  bool _isStreaming = false;
  String _error = '';

  // Claude AI Service instance
  late final ClaudeAIService _aiService;

  @override
  void initState() {
    super.initState();

    // Initialize Claude AI Service with default endpoint
    _aiService = ClaudeAIService();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // Test the streaming functionality - Step 1 implementation
  // This uses the raw http.Client().send() approach while keeping Edge Function as is
  Future<void> _testStreamingStep1() async {
    if (_promptController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a prompt';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isStreaming = true;
      _generatedText = '';
      _error = '';
    });

    try {
      // Use a hardcoded endpoint URL that matches what's in ClaudeAIService
      final uri = Uri.parse(
          'https://awbrfvdyokwkpwrqmfwd.supabase.co/functions/v1/claude-gateway');
      final client = http.Client();
      final request = http.Request('POST', uri);

      // Get the access token and anon key from the Supabase service
      final supabaseService = serviceLocator<SupabaseServiceInterface>();
      final accessToken =
          supabaseService.client.auth.currentSession?.accessToken;
      final anonKey = supabaseService.supabaseAnonKey;

      if (accessToken == null) {
        throw Exception('User not authenticated or session expired.');
      }

      // Set headers
      request.headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'apikey': anonKey,
      });

      // Set body - Note: we're keeping stream:false for Step 1
      final requestBody = {
        'model': 'claude-3-7-sonnet-20250219',
        'max_tokens': 1024,
        'stream': false, // Keep this false for Step 1
        'system': 'You are a helpful AI assistant.',
        'content': _promptController.text,
      };

      request.body = jsonEncode(requestBody);

      developer.log('Sending streaming request: ${request.body}',
          name: 'ClaudeAIStreamingTest');

      // Send the request and get the response stream
      final response = await client.send(request);

      if (response.statusCode == 200) {
        // Process the stream
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          developer.log('Received chunk: $chunk',
              name: 'ClaudeAIStreamingTest');

          // In Step 1, we expect a complete JSON response
          try {
            final data = jsonDecode(chunk) as Map<String, dynamic>;
            final content = data['content'] as String? ?? '';

            setState(() {
              _generatedText = content;
            });
          } catch (e) {
            developer.log('Error parsing JSON: $e',
                name: 'ClaudeAIStreamingTest', error: e);
          }
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Error ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
      developer.log('Streaming error: $e',
          name: 'ClaudeAIStreamingTest', error: e);
    } finally {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
      });
    }
  }

  // Test using the streamFromClaude method in ClaudeAIService
  Future<void> _testStreamFromClaude() async {
    if (_promptController.text.isEmpty) {
      setState(() {
        _error = 'Please enter a prompt';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isStreaming = true;
      _generatedText = '';
      _error = '';
    });

    try {
      // Use the streamFromClaude method
      final stream = _aiService.streamFromClaude(
        _promptController.text,
        (userInput) => [
          {'role': 'user', 'content': userInput}
        ],
        buildSystemPrompt: () => 'You are a helpful AI assistant.',
      );

      // Subscribe to the stream
      await for (final chunk in stream) {
        developer.log('Received chunk from streamFromClaude: $chunk',
            name: 'ClaudeAIStreamingTest');

        // In Step 1, we expect a complete JSON response
        try {
          final data = jsonDecode(chunk) as Map<String, dynamic>;
          final content = data['content'] as String? ?? '';

          setState(() {
            _generatedText = content;
          });
        } catch (e) {
          developer.log('Error parsing JSON: $e',
              name: 'ClaudeAIStreamingTest', error: e);
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
      developer.log('streamFromClaude error: $e',
          name: 'ClaudeAIStreamingTest', error: e);
    } finally {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude AI Streaming Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter your prompt here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testStreamingStep1,
                    child: const Text('Test Streaming (Step 1)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testStreamFromClaude,
                    child: const Text('Test streamFromClaude'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading && !_isStreaming)
              const Center(child: CircularProgressIndicator())
            else if (_isStreaming)
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text('Streaming...'),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text('Generated Text:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(_generatedText),
                ),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.red.withOpacity(0.1),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A simple main function to run the Claude AI Streaming test
void main() {
  runApp(const ClaudeAIStreamingTestApp());
}

/// A simple app to run the Claude AI Streaming test
class ClaudeAIStreamingTestApp extends StatelessWidget {
  const ClaudeAIStreamingTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claude AI Streaming Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ClaudeAIStreamingTest(),
    );
  }
}
