// supabase/functions/claude-gateway/index.ts  ※Deno 1.40+
import { serve } from "https://deno.land/std@0.204.0/http/server.ts";

function withCors(r: Response) {
  return new Response(r.body, {
    ...r,
    headers: {
      ...r.headers,
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST,OPTIONS",
      "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") return withCors(new Response(null, { status: 204 }));

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
        model: "claude-3.7-sonnet-2025-04-09",
        system,
        messages,
        max_tokens,
      }),
    });

    if (!anthropicRes.ok) {
      return withCors(new Response(await anthropicRes.text(), {
        status: anthropicRes.status,
        statusText: anthropicRes.statusText,
      }));
    }

    return withCors(anthropicRes);
  } catch (e) {
    console.error(e);
    return withCors(new Response(JSON.stringify({ error: "Edge Function error", detail: String(e) }), { status: 500 }));
  }
});
