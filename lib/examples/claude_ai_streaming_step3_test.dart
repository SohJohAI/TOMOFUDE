import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/supabase_service_interface.dart';
import '../services/service_locator.dart';

/// A test widget to demonstrate Claude AI streaming functionality with SSE parsing
/// This implements Step 3 of the streaming implementation plan
class ClaudeAIStreamingStep3Test extends StatefulWidget {
  const ClaudeAIStreamingStep3Test({Key? key}) : super(key: key);

  @override
  State<ClaudeAIStreamingStep3Test> createState() =>
      _ClaudeAIStreamingStep3TestState();
}

class _ClaudeAIStreamingStep3TestState
    extends State<ClaudeAIStreamingStep3Test> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedText = '';
  bool _isLoading = false;
  bool _isStreaming = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  // Test the streaming functionality with SSE parsing (Step 3)
  Future<void> _testStreamingStep3() async {
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

      // Set body - Note: we're setting stream:true for Step 3
      // This assumes the Edge Function has been updated to support streaming
      final requestBody = {
        'model': 'claude-3-sonnet-20240229',
        'max_tokens': 1024,
        'stream': true, // Set to true for Step 3
        'system': 'You are a helpful AI assistant.',
        'content': _promptController.text,
      };

      request.body = jsonEncode(requestBody);

      developer.log('Sending streaming request: ${request.body}',
          name: 'ClaudeAIStreamingStep3Test');

      // Send the request and get the response stream
      final response = await client.send(request);

      if (response.statusCode == 200) {
        // Process the stream with SSE parsing
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          developer.log('Received chunk: $chunk',
              name: 'ClaudeAIStreamingStep3Test');

          // Parse SSE format (lines starting with "data: ")
          for (final line in LineSplitter.split(chunk)) {
            if (line.startsWith('data: ')) {
              final payload = line.substring(6).trim();

              // Check for the end of the stream
              if (payload == '[DONE]') {
                developer.log('Stream complete',
                    name: 'ClaudeAIStreamingStep3Test');
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
                    name: 'ClaudeAIStreamingStep3Test', error: e);
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
          name: 'ClaudeAIStreamingStep3Test', error: e);
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
        title: const Text('Claude AI Streaming (Step 3)'),
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
            ElevatedButton(
              onPressed: _isLoading ? null : _testStreamingStep3,
              child: const Text('Test Streaming with SSE Parsing'),
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

/// A simple main function to run the Claude AI Streaming Step 3 test
void main() {
  runApp(const ClaudeAIStreamingStep3TestApp());
}

/// A simple app to run the Claude AI Streaming Step 3 test
class ClaudeAIStreamingStep3TestApp extends StatelessWidget {
  const ClaudeAIStreamingStep3TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claude AI Streaming Step 3 Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ClaudeAIStreamingStep3Test(),
    );
  }
}
