import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A simple example demonstrating how to debug Claude API 400 errors
/// This example includes comprehensive logging and error handling
class ClaudeAPIDebugExample extends StatefulWidget {
  const ClaudeAPIDebugExample({Key? key}) : super(key: key);

  @override
  State<ClaudeAPIDebugExample> createState() => _ClaudeAPIDebugExampleState();
}

class _ClaudeAPIDebugExampleState extends State<ClaudeAPIDebugExample> {
  final TextEditingController _promptController = TextEditingController();
  String _response = '';
  String _errorDetails = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_promptController.text.isEmpty) {
      setState(() {
        _errorDetails = 'Please enter a prompt';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _response = '';
      _errorDetails = '';
    });

    try {
      // Step 1: Prepare the request
      final uri = Uri.parse(
          'https://awbrfvdyokwkpwrqmfwd.supabase.co/functions/v1/claude-gateway');
      final client = http.Client();
      final request = http.Request('POST', uri);

      // Step 2: Set headers - ensure correct case for 'apikey'
      request.headers.addAll({
        'Content-Type': 'application/json', // Ensure Content-Type is set
        'Authorization':
            'Bearer YOUR_ACCESS_TOKEN', // Replace with actual token
        'apikey': 'YOUR_ANON_KEY', // Replace with actual anon key - lowercase!
      });

      // Step 3: Build request body
      final messages = [
        {'role': 'user', 'content': _promptController.text}
      ];

      // Print message list length to debug empty messages array
      developer.log('Message list length: ${messages.length}',
          name: 'ClaudeAPIDebug');

      final requestBody = {
        'model': 'claude-3-sonnet-20240229',
        'max_tokens': 1024,
        'stream': false, // Ensure this is a boolean, not a string
        'messages': messages,
      };

      // Verify stream is a boolean
      assert(requestBody['stream'] is bool, 'stream must be a boolean');

      // Step 4: Log the request body
      request.body = jsonEncode(requestBody);
      developer.log('📤 REQUEST >>> ${request.body}', name: 'ClaudeAPIDebug');

      // Step 5: Send the request
      final response = await client.send(request);

      developer.log('Response status: ${response.statusCode}',
          name: 'ClaudeAPIDebug');

      // Step 6: Handle the response
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        developer.log('❌ ERROR BODY <<< $errorBody', name: 'ClaudeAPIDebug');

        // Try to parse the error body to extract details
        try {
          final errorJson = jsonDecode(errorBody) as Map<String, dynamic>;
          final errorMessage = errorJson['error'] ?? 'Unknown error';
          final forwardedBody = errorJson['forwardedBody'];

          setState(() {
            _errorDetails =
                'Error: $errorMessage\n\nForwarded Body: $forwardedBody';
          });
        } catch (e) {
          setState(() {
            _errorDetails = 'Error: $errorBody';
          });
        }
      } else {
        final responseBody = await response.stream.bytesToString();
        developer.log('Response body: $responseBody', name: 'ClaudeAPIDebug');

        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        setState(() {
          _response = data['content'] ?? responseBody;
        });
      }
    } catch (e) {
      developer.log('Exception: $e', name: 'ClaudeAPIDebug', error: e);
      setState(() {
        _errorDetails = 'Exception: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude API Debug Example'),
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
              onPressed: _isLoading ? null : _sendRequest,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Send Request'),
            ),
            const SizedBox(height: 16),
            const Text('Response:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  child: Text(_response),
                ),
              ),
            ),
            if (_errorDetails.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Error Details:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.red)),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.red.withOpacity(0.1),
                ),
                child: SingleChildScrollView(
                  child: Text(_errorDetails,
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A simple main function to run the Claude API Debug example
void main() {
  runApp(const ClaudeAPIDebugExampleApp());
}

/// A simple app to run the Claude API Debug example
class ClaudeAPIDebugExampleApp extends StatelessWidget {
  const ClaudeAPIDebugExampleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claude API Debug Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ClaudeAPIDebugExample(),
    );
  }
}
