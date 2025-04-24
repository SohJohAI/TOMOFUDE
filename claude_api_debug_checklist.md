# Claude API 400 Error Debugging Checklist

This document provides a systematic approach to debug 400 errors when using the Claude API through Supabase Edge Functions.

## Step 0: Capture the Actual Error Message

The first step is to ensure you have comprehensive logging in place to capture the exact error:

1. **Flutter side (pre-request)**: 
   ```dart
   developer.log('📤 REQUEST >>> ${jsonEncode(requestBody)}', name: 'ClaudeAIService');
   ```

2. **Edge Function (request receipt)**:
   ```typescript
   const reqBody = await req.json();
   console.log("📥 GATEWAY RECEIVED >>>", JSON.stringify(reqBody, null, 2));
   ```

3. **Edge Function (before forwarding to Claude)**:
   ```typescript
   const claudePayload = {
     model,
     max_tokens: max_tokens ?? 1024,
     stream,
     system,
     messages,
   };
   console.log("🚀 FORWARD TO CLAUDE >>>", JSON.stringify(claudePayload, null, 2));
   ```

4. **Edge Function (error handling)**:
   ```typescript
   if (!anthropicRes.ok) {
     const errText = await anthropicRes.text();
     return new Response(
       JSON.stringify({ error: errText, forwardedBody: claudePayload }),
       { status: anthropicRes.status, headers: { ...cors, "content-type": "application/json" } },
     );
   }
   ```

5. **Flutter side (error response)**:
   ```dart
   if (response.statusCode != 200) {
     final errorBody = await response.stream.bytesToString();
     developer.log('❌ ERROR BODY <<< $errorBody', name: 'ClaudeAIService');
     throw Exception('Claude streaming error ${response.statusCode}: $errorBody');
   }
   ```

## Step 1: Verify JSON Format with Curl

Use the provided `claude_test.sh` script to test the API directly:

```bash
./claude_test.sh [your_anon_key]
```

If this works but the Flutter app fails, the issue is in the Flutter app's request format.

## Step 2: Common Issues Checklist

| Issue | Symptoms | How to Fix |
|-------|----------|------------|
| **Empty messages array** | `messages` is `[]` or `null` | Check `buildMessageList()` function, add `print(list.length)` before returning |
| **Stream as string** | `stream` is `"true"` instead of `true` | Add `assert(stream is bool)` before encoding JSON |
| **Missing Content-Type header** | Headers don't include Content-Type | Ensure `request.headers['Content-Type'] = 'application/json'` |
| **Apikey case sensitivity** | Header uses wrong case | Use lowercase `apikey` (not `ApiKey` or other variants) |
| **JSON double-wrapping** | JSON structure has nested objects | Check Edge Function's request forwarding logic |

## Step 3: Debugging Process

1. Deploy the updated Edge Function with enhanced logging
2. Run a test from the Flutter app
3. Examine logs to compare:
   - What Flutter is sending (`📤 REQUEST >>>`)
   - What the Edge Function receives (`📥 GATEWAY RECEIVED >>>`)
   - What the Edge Function forwards to Claude (`🚀 FORWARD TO CLAUDE >>>`)
   - Any error responses (`❌ ERROR BODY <<<`)

4. If the Flutter test fails, run the curl test to verify if the Edge Function works with a properly formatted request

## Step 4: Specific Error Messages and Solutions

| Error Message | Likely Cause | Solution |
|---------------|--------------|----------|
| `"messages" is required` | Missing or empty messages array | Check message construction in Flutter |
| `Invalid value for enum` | Incorrect role value | Ensure roles are only "user" or "assistant" |
| `"content" is required` | Missing content in message | Verify message format has content field |
| `stream must be a boolean` | Stream parameter is a string | Ensure stream is a boolean value |
| `model is not supported` | Incorrect model name | Use a valid model name like "claude-3-sonnet-20240229" |

## Conclusion

By following this systematic approach and using the enhanced logging, you should be able to quickly identify and fix the cause of 400 errors when using the Claude API.
