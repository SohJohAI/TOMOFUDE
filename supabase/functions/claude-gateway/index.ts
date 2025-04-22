// supabase/functions/claude-gateway/index.ts  ※Deno 1.40+
import { serve } from "https://deno.land/std@0.204.0/http/server.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // OPTIONS プリフライト
  if (req.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });

  try {
    const { messages, system = "", max_tokens = 1024 } = await req.json();

    const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!,
        "anthropic-version": "2023-06-01", // 必須ヘッダー :contentReference[oaicite:0]{index=0}
      },
      body: JSON.stringify({
        model: "claude-3.7-sonnet-20250219",
        stream: true, // ← これ追加
        system,
        messages,
        max_tokens,
      }),
    });

    if (!anthropicRes.ok) {
      return new Response(await anthropicRes.text(), {
        status: anthropicRes.status,
        statusText: anthropicRes.statusText,
        headers: cors,
      });
    }

    return new Response(anthropicRes.body, {
      status: anthropicRes.status,
      headers: {
        ...cors,
        "content-type": "text/event-stream", // ← ここ重要
        "cache-control": "no-cache",
      },
    });
      
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: "Edge Function error", detail: String(e) }), { 
      status: 500, 
      headers: cors 
    });
  }
});
