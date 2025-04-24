# Claude AI Streaming Implementation Guide

This guide explains how to implement streaming responses from Claude AI in a Flutter application using Supabase Edge Functions.

## Implementation Steps

The implementation is divided into three steps:

### Step 1: Flutter-side Streaming with Edge Function Unchanged

In this step, we keep the Edge Function as is (with `stream: false`), but implement streaming on the Flutter side using `http.Client().send()` to get a stream of the response.

**Key points:**
- Edge Function returns a complete JSON response
- Flutter uses `http.Client().send()` to get a stream
- The stream contains the complete JSON response as a single chunk
- This step establishes the basic streaming infrastructure on the Flutter side

### Step 2: Enable Streaming in Edge Function

In this step, we modify the Edge Function to enable streaming from Claude API and pass the streaming response directly to the client.

**Key points:**
- Edge Function sets `stream: true` when calling Claude API
- Edge Function passes the streaming response body directly to the client
- Flutter receives raw SSE (Server-Sent Events) chunks
- This step enables true streaming from Claude API to the client

### Step 3: Parse SSE Format in Flutter

In this step, we implement parsing of the SSE format in Flutter to extract and process the streaming content.

**Key points:**
- Flutter parses lines starting with `data: `
- Flutter extracts JSON payloads from these lines
- Flutter processes content deltas to build the complete response
- This step completes the streaming implementation

## Example Files

The following example files demonstrate the implementation:

1. `lib/examples/claude_ai_streaming_test.dart` - Demonstrates Step 1
2. `lib/examples/claude_ai_streaming_step3_test.dart` - Demonstrates Step 3
3. `lib/examples/claude_ai_streaming_complete_example.dart` - Comprehensive example demonstrating all steps

## Edge Function Changes

The Edge Function (`supabase/functions/claude-gateway/index.ts`) was modified to:

1. Use the `stream` parameter from the request when calling Claude API
2. Set appropriate headers for streaming responses
3. Pass the streaming response body directly to the client

## How to Use

### Running the Examples

To run any of the example files:

```dart
import 'package:flutter/material.dart';
import 'examples/claude_ai_streaming_complete_example.dart';

void main() {
  runApp(const ClaudeAIStreamingExampleApp());
}
```

### Using in Your Own Code

To implement streaming in your own code:

1. Use `http.Client().send()` to get a stream of the response
2. Transform the stream with `utf8.decoder`
3. Parse the SSE format (lines starting with `data: `)
4. Extract and process JSON payloads from these lines

Example:

```dart
final request = http.Request('POST', uri);
// Set headers and body...

final response = await client.send(request);

if (response.statusCode == 200) {
  await for (final chunk in response.stream.transform(utf8.decoder)) {
    for (final line in LineSplitter.split(chunk)) {
      if (line.startsWith('data: ')) {
        final payload = line.substring(6).trim();
        
        if (payload == '[DONE]') continue;
        
        final map = jsonDecode(payload) as Map<String, dynamic>;
        if (map['type'] == 'content_block_delta') {
          final deltaText = map['delta']['text'] as String? ?? '';
          // Process deltaText...
        }
      }
    }
  }
}
```

### Using the streamFromClaude Method

The `ClaudeAIService` class includes a `streamFromClaude` method that handles the streaming for you:

```dart
final stream = claudeAIService.streamFromClaude(
  userInput,
  (input) => [{'role': 'user', 'content': input}],
  buildSystemPrompt: () => 'You are a helpful AI assistant.',
);

await for (final chunk in stream) {
  // Parse SSE format and process...
}
```

## Benefits of Streaming

Implementing streaming provides several benefits:

1. **Faster Perceived Response Time**: Users see content appearing incrementally rather than waiting for the entire response
2. **Better User Experience**: Users can start reading the response while it's still being generated
3. **Cancellation**: Requests can be cancelled mid-stream if the user decides they don't need the full response
4. **Progress Indication**: The application can show real-time progress of the response generation

## Troubleshooting

- **CORS Issues**: Ensure the Edge Function has appropriate CORS headers
- **Authentication**: Make sure the authentication token is valid
- **Parsing Errors**: Check the format of the SSE chunks and ensure proper parsing
- **Connection Timeouts**: Increase timeout values for long-running requests
