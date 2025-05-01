# Claude API Debugging Guide

This guide provides tools and strategies for debugging 400 errors when using the Claude AI API through Supabase Edge Functions.

## Overview

When working with the Claude AI API through Supabase Edge Functions, you might encounter 400 errors that can be difficult to diagnose. This debugging toolkit provides:

1. Enhanced logging for both the Edge Function and Flutter client
2. A systematic approach to identify and fix common issues
3. Tools for testing and verification
4. Example code demonstrating best practices

## Files in this Toolkit

- **claude_api_debug_checklist.md**: A comprehensive checklist for debugging 400 errors
- **claude_test.sh**: A shell script for testing the Claude API gateway directly
- **claude_api_debug_example.dart**: A Flutter example demonstrating proper error handling and logging
- **claude_api_debugging_guide.md**: This guide

## Step-by-Step Debugging Process

### 1. Add Enhanced Logging

#### Edge Function (supabase/functions/claude-gateway/index.ts)

The Edge Function has been updated with comprehensive logging at key points:

- When the request is received
- Before forwarding to Claude API
- When handling errors

These logs will help identify exactly where the issue is occurring.

#### Flutter Client (lib/services/claude_ai_service.dart)

The Flutter client has been updated to:

- Log the request body before sending
- Log detailed error responses
- Include proper error handling

### 2. Deploy and Test

1. Deploy the updated Edge Function to Supabase
2. Run a test from your Flutter app
3. Check the logs to identify where the issue is occurring

### 3. Use the Testing Script

The `claude_test.sh` script provides a quick way to test the Claude API gateway directly:

```bash
# Make the script executable
chmod +x claude_test.sh

# Run with your anon key
./claude_test.sh YOUR_ANON_KEY

# Or set the environment variable and run
export SUPA_ANON_KEY=your_anon_key
./claude_test.sh
```

If the script works but your Flutter app doesn't, the issue is in your Flutter code.

### 4. Check Common Issues

Refer to the checklist in `claude_api_debug_checklist.md` for common issues and their solutions:

- Empty messages array
- Stream parameter as string instead of boolean
- Missing Content-Type header
- Apikey case sensitivity
- JSON double-wrapping

### 5. Implement the Example

The `claude_api_debug_example.dart` file provides a complete example of:

- Proper request formatting
- Comprehensive error handling
- Detailed logging
- User-friendly error display

You can use this as a reference for implementing proper error handling in your own code.

## Deployment Instructions

### Edge Function

1. Update your Edge Function with the enhanced logging:

   ```bash
   cd supabase/functions/claude-gateway
   supabase functions deploy claude-gateway
   ```

### Flutter Client

1. Update your Claude AI service with the enhanced error handling
2. Ensure you're using the proper headers and request format
3. Add assertions to catch common issues early

## Conclusion

By following this systematic approach and using the provided tools, you should be able to quickly identify and fix the cause of 400 errors when using the Claude API.

Remember that most 400 errors are due to:

1. Incorrect request format
2. Authentication issues
3. Parameter type mismatches

The enhanced logging will help you pinpoint exactly where the issue is occurring, making debugging much easier.
