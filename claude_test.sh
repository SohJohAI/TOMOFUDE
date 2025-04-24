#!/bin/bash

# Claude API Gateway Test Script
# Usage: ./claude_test.sh [anon_key]
# If anon_key is not provided, it will use the SUPA_ANON_KEY environment variable

# Get the anon key from the command line argument or environment variable
ANON_KEY=${1:-$SUPA_ANON_KEY}

if [ -z "$ANON_KEY" ]; then
  echo "Error: No anon key provided. Either pass it as an argument or set the SUPA_ANON_KEY environment variable."
  echo "Usage: ./claude_test.sh [anon_key]"
  exit 1
fi

echo "Testing Claude API Gateway..."

curl -sS \
  -H "Content-Type: application/json" \
  -H "apikey: $ANON_KEY" \
  -d '{
    "model": "claude-3-sonnet-20240229",
    "max_tokens": 32,
    "stream": false,
    "messages":[{"role":"user","content":"hello"}]
  }' \
  https://awbrfvdyokwkpwrqmfwd.supabase.co/functions/v1/claude-gateway | jq .

echo ""
echo "Test complete."
