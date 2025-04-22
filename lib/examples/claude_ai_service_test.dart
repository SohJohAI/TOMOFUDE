import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../services/claude_ai_service.dart';
import '../services/ai_service_interface.dart';

/// A simple test widget to verify Claude AI Service connectivity
class ClaudeAIServiceTest extends StatefulWidget {
  const ClaudeAIServiceTest({Key? key}) : super(key: key);

  @override
  State<ClaudeAIServiceTest> createState() => _ClaudeAIServiceTestState();
}

class _ClaudeAIServiceTestState extends State<ClaudeAIServiceTest> {
  bool _isLoading = false;
  String _result = '';
  String _error = '';

  // Claude AI Service instance
  late final AIService _aiService;

  @override
  void initState() {
    super.initState();

    // Initialize Claude AI Service with default endpoint
    _aiService = ClaudeAIService();

    // Alternatively, you can specify a custom endpoint:
    // _aiService = ClaudeAIService(
    //   claudeGatewayUrl: 'https://tomofudeserver-production.up.railway.app/claude',
    // );
  }

  // Test the connection to Claude AI Service
  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      // Make a simple request to test connectivity
      final result = await _aiService.generateSettings(
        'テスト文章です。接続テスト用。',
        contentType: 'テスト',
      );

      setState(() {
        _result = 'Success! Response: ${result.toString()}';
        _isLoading = false;
      });

      developer.log('Test successful: $result', name: 'ClaudeAIServiceTest');
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });

      developer.log('Test failed: $e', name: 'ClaudeAIServiceTest', error: e);
    }
  }

  // Test with alternative endpoint
  Future<void> _testWithAlternativeEndpoint() async {
    setState(() {
      _isLoading = true;
      _result = '';
      _error = '';
    });

    try {
      // Create a new instance with a different endpoint
      // Try without port specification
      final alternativeService = ClaudeAIService(
        claudeGatewayUrl:
            'https://tomofudeserver-production.up.railway.app/claude',
      );

      final result = await alternativeService.generateSettings(
        'テスト文章です。代替エンドポイント接続テスト用。',
        contentType: 'テスト',
      );

      setState(() {
        _result =
            'Success with alternative endpoint! Response: ${result.toString()}';
        _isLoading = false;
      });

      developer.log('Alternative endpoint test successful: $result',
          name: 'ClaudeAIServiceTest');
    } catch (e) {
      setState(() {
        _error = 'Error with alternative endpoint: $e';
        _isLoading = false;
      });

      developer.log('Alternative endpoint test failed: $e',
          name: 'ClaudeAIServiceTest', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude AI Service Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: const Text('Test Connection'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testWithAlternativeEndpoint,
              child: const Text('Test Alternative Endpoint'),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_result.isNotEmpty) ...[
                const Text('Result:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.green.withOpacity(0.1),
                  child: Text(_result),
                ),
              ],
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Error:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Text(_error),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// A simple function to run the test from anywhere in the app
void runClaudeAIServiceTest(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ClaudeAIServiceTest()),
  );
}
