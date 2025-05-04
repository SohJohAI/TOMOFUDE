import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/claude_ai_service.dart';
import '../services/supabase_service_interface.dart';
import '../services/service_locator.dart';

/// A complete example demonstrating Claude AI streaming functionality
/// This example includes all three steps of the streaming implementation
class ClaudeAIStreamingCompleteExample extends StatefulWidget {
  const ClaudeAIStreamingCompleteExample({Key? key}) : super(key: key);

  @override
  State<ClaudeAIStreamingCompleteExample> createState() =>
      _ClaudeAIStreamingCompleteExampleState();
}

class _ClaudeAIStreamingCompleteExampleState
    extends State<ClaudeAIStreamingCompleteExample> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedText = '';
  bool _isLoading = false;
  bool _isStreaming = false;
  String _error = '';

  // Implementation step
  int _currentStep = 1;

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

  // Step 1: Basic streaming with stream:false on Edge Function
  Future<void> _testStep1() async {
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
      _currentStep = 1;
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
        'model': 'claude-3-sonnet-20240229',
        'max_tokens': 1024,
        'stream': false, // Keep this false for Step 1
        'system': 'You are a helpful AI assistant.',
        'messages': [
          {'role': 'user', 'content': _promptController.text}
        ],
      };

      request.body = jsonEncode(requestBody);

      developer.log('Sending streaming request: ${request.body}',
          name: 'ClaudeAIStreamingExample');

      // Send the request and get the response stream
      final response = await client.send(request);

      if (response.statusCode == 200) {
        // Process the stream
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          developer.log('Received chunk: $chunk',
              name: 'ClaudeAIStreamingExample');

          // In Step 1, we expect a complete JSON response
          try {
            final data = jsonDecode(chunk) as Map<String, dynamic>;
            final content = data['content'] as String? ?? '';

            setState(() {
              _generatedText = content;
            });
          } catch (e) {
            developer.log('Error parsing JSON: $e',
                name: 'ClaudeAIStreamingExample', error: e);
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
          name: 'ClaudeAIStreamingExample', error: e);
    } finally {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
      });
    }
  }

  // Step 2: Direct streaming from Edge Function with stream:true
  Future<void> _testStep2() async {
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
      _currentStep = 2;
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

      // Set body - Note: we're setting stream:true for Step 2
      final requestBody = {
        'model': 'claude-3-sonnet-20240229',
        'max_tokens': 1024,
        'stream': true, // Set to true for Step 2
        'system': 'You are a helpful AI assistant.',
        'messages': [
          {'role': 'user', 'content': _promptController.text}
        ],
      };

      request.body = jsonEncode(requestBody);

      developer.log('Sending streaming request: ${request.body}',
          name: 'ClaudeAIStreamingExample');

      // Send the request and get the response stream
      final response = await client.send(request);

      if (response.statusCode == 200) {
        // Process the stream - in Step 2, we just log the raw chunks
        // but don't try to parse them yet
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          developer.log('Received raw chunk: $chunk',
              name: 'ClaudeAIStreamingExample');

          // Just append the raw chunk to show what's coming through
          setState(() {
            _generatedText += 'RAW CHUNK: $chunk\n\n';
          });
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
          name: 'ClaudeAIStreamingExample', error: e);
    } finally {
      setState(() {
        _isLoading = false;
        _isStreaming = false;
      });
    }
  }

  // Step 3: Parse SSE format with "data:" lines
  Future<void> _testStep3() async {
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
      _currentStep = 3;
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

      // Set body - Note: we're setting stream:true for Step 3
      final requestBody = {
        'model': 'claude-3-7-sonnet-20250219',
        'max_tokens': 1024,
        'stream': true, // Set to true for Step 3
        'system': 'You are a helpful AI assistant.',
        'messages': [
          {'role': 'user', 'content': _promptController.text}
        ],
      };

      request.body = jsonEncode(requestBody);

      developer.log('Sending streaming request: ${request.body}',
          name: 'ClaudeAIStreamingExample');

      // Send the request and get the response stream
      final response = await client.send(request);

      if (response.statusCode == 200) {
        // Process the stream with SSE parsing
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          developer.log('Received chunk: $chunk',
              name: 'ClaudeAIStreamingExample');

          // Parse SSE format (lines starting with "data: ")
          for (final line in LineSplitter.split(chunk)) {
            if (line.startsWith('data: ')) {
              final payload = line.substring(6).trim();

              // Check for the end of the stream
              if (payload == '[DONE]') {
                developer.log('Stream complete',
                    name: 'ClaudeAIStreamingExample');
                continue;
              }

              try {
                // Parse the JSON payload
                final map = jsonDecode(payload) as Map<String, dynamic>;

                // Check for content_block_delta type
                if (map['type'] == 'content_block_delta') {
                  final deltaText = map['delta']['text'] as String? ?? '';

                  setState(() {
                    _generatedText += deltaText;
                  });
                }
              } catch (e) {
                developer.log('Error parsing JSON payload: $e',
                    name: 'ClaudeAIStreamingExample', error: e);
              }
            }
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
          name: 'ClaudeAIStreamingExample', error: e);
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
      _currentStep = 3; // This uses the Step 3 approach
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
            name: 'ClaudeAIStreamingExample');

        // Parse SSE format (lines starting with "data: ")
        for (final line in LineSplitter.split(chunk)) {
          if (line.startsWith('data: ')) {
            final payload = line.substring(6).trim();

            // Check for the end of the stream
            if (payload == '[DONE]') {
              developer.log('Stream complete',
                  name: 'ClaudeAIStreamingExample');
              continue;
            }

            try {
              // Parse the JSON payload
              final map = jsonDecode(payload) as Map<String, dynamic>;

              // Check for content_block_delta type
              if (map['type'] == 'content_block_delta') {
                final deltaText = map['delta']['text'] as String? ?? '';

                setState(() {
                  _generatedText += deltaText;
                });
              }
            } catch (e) {
              developer.log('Error parsing JSON payload: $e',
                  name: 'ClaudeAIStreamingExample', error: e);
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
      developer.log('streamFromClaude error: $e',
          name: 'ClaudeAIStreamingExample', error: e);
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
        title: const Text('Claude AI Streaming Example'),
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
                    onPressed: _isLoading ? null : _testStep1,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentStep == 1 ? Colors.blue.shade200 : null,
                    ),
                    child: const Text('Step 1'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testStep2,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentStep == 2 ? Colors.blue.shade200 : null,
                    ),
                    child: const Text('Step 2'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testStep3,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _currentStep == 3 ? Colors.blue.shade200 : null,
                    ),
                    child: const Text('Step 3'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testStreamFromClaude,
              child: const Text('Use streamFromClaude'),
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
            Row(
              children: [
                const Text('Generated Text:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('Step $_currentStep',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
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

/// A simple main function to run the Claude AI Streaming example
void main() {
  runApp(const ClaudeAIStreamingExampleApp());
}

/// A simple app to run the Claude AI Streaming example
class ClaudeAIStreamingExampleApp extends StatelessWidget {
  const ClaudeAIStreamingExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claude AI Streaming Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ClaudeAIStreamingCompleteExample(),
    );
  }
}
