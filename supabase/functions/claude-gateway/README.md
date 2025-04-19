# Claude API Gateway

This Edge Function serves as a middleware between the frontend and Claude API, providing a secure way to make requests to Claude without exposing the API key in the frontend code.

## Functionality

The function:
1. Accepts a POST request with a JSON body containing a `prompt` field
2. Forwards the request to Claude API with proper authentication
3. Returns Claude's response back to the client

## Deployment

### Prerequisites

- Supabase CLI installed
- Claude API key (from Anthropic)

### Setting Environment Variables

Before deploying, you need to set the Claude API key as a secret:

```bash
supabase secrets set CLAUDE_API_KEY=sk-xxx
```

Replace `sk-xxx` with your actual Claude API key.

### Deploy the Function

Deploy the function using the Supabase CLI:

```bash
supabase functions deploy claude-gateway
```

## Usage

Once deployed, you can call the function from your frontend code:

```typescript
const response = await fetch('https://[project-id].functions.supabase.co/claude-gateway', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    // Include authentication headers if needed
  },
  body: JSON.stringify({
    prompt: 'こんにちは、Claude',
  }),
});

const data = await response.json();
console.log(data);
```

## Testing

You can test the function using curl:

```bash
curl -X POST https://[project-id].functions.supabase.co/claude-gateway \
  -H "Content-Type: application/json" \
  -d '{"prompt": "こんにちは、Claude"}'
```

## Response Format

The function returns the raw response from Claude API, which includes:

```json
{
  "id": "msg_...",
  "type": "message",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "こんにちは！お手伝いできることがあれば、お気軽にお尋ねください。"
    }
  ],
  "model": "claude-3-sonnet-20240229",
  "stop_reason": "end_turn",
  "stop_sequence": null,
  "usage": {
    "input_tokens": 10,
    "output_tokens": 37
  }
}
```

Your frontend code will need to parse this response to extract the content.
