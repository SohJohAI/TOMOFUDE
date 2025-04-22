// supabase/functions/claude-gateway/index.ts
//
// Claude 3 Messages API を叩く Supabase Edge Function
// -----------------------------------------------
// 期待する POST ボディ:
// {
//   "content": "ユーザーが送るプロンプト文字列",
//   "model"?: "claude-3-sonnet-20240229", // 省略時は sonnet
//   "system"?: "システムプロンプト文字列",          // 任意
//   "max_tokens"?: number,                         // 任意
//   "stream"?: boolean                             // true なら SSE ストリーム
// }
//
// ❗️ANTHROPIC_API_KEY は `supabase secrets set` で注入しておくこと ❗️
//

import { serve } from "https://deno.land/std@0.193.0/http/server.ts";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

/** Utility: JSON → string with pretty error */
async function safeJson<T>(req: Request): Promise<T | Response> {
  try {
    return (await req.json()) as T;
  } catch (_) {
    return new Response(
      JSON.stringify({ error: "Invalid JSON payload" }),
      { status: 400, headers: { ...cors, "content-type": "application/json" } },
    );
  }
}

interface GatewayBody {
  content: string;
  model?: string;
  system?: string;
  max_tokens?: number;
  stream?: boolean;
}

serve(async (req) => {
  // ─────────── OPTIONS (CORS プリフライト) ───────────
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }

  // ─────────── バリデーション ───────────
  if (req.method !== "POST") {
    return new Response(
      JSON.stringify({ error: "Method Not Allowed" }),
      { status: 405, headers: { ...cors, "content-type": "application/json" } },
    );
  }

  const parsed = await safeJson<GatewayBody>(req);
  if (parsed instanceof Response) return parsed; // JSON parse error

  const {
    content,
    model = "claude-3-7-sonnet-20250219",
    system,
    max_tokens,
    stream = true,
  } = parsed;

  if (!content) {
    return new Response(
      JSON.stringify({ error: "`content` is required" }),
      { status: 400, headers: { ...cors, "content-type": "application/json" } },
    );
  }

  // ─────────── Claude API 呼び出し ───────────
  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    console.error("ANTHROPIC_API_KEY is not set");
    return new Response(
      JSON.stringify({ error: "Server mis‑configuration" }),
      { status: 500, headers: { ...cors, "content-type": "application/json" } },
    );
  }

  const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "anthropic-version": "2023-06-01",
      "x-api-key": apiKey,
    },
    body: JSON.stringify({
      model,
      max_tokens: max_tokens ?? 1024,
      stream,
      system,
      messages: [{ role: "user", content }],
    }),
  });

  if (!anthropicRes.ok) {
    const errText = await anthropicRes.text();
    return new Response(errText, {
      status: anthropicRes.status,
      headers: { ...cors, "content-type": "application/json" },
    });
  }

  // ─────────── クライアントへ転送 ───────────
  // stream = true なら SSE, false なら普通の JSON
  return new Response(anthropicRes.body, {
    status: anthropicRes.status,
    headers: {
      ...cors,
      "content-type": stream ? "text/event-stream" : "application/json",
      "cache-control": "no-cache",
    },
  });
});
