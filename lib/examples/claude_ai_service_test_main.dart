import 'package:flutter/material.dart';
import 'claude_ai_service_test.dart';

/// A simple main function to run the Claude AI Service test
void main() {
  runApp(const ClaudeAIServiceTestApp());
}

/// A simple app to run the Claude AI Service test
class ClaudeAIServiceTestApp extends StatelessWidget {
  const ClaudeAIServiceTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Claude AI Service Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ClaudeAIServiceTest(),
    );
  }
}
