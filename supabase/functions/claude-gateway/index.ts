// supabase/functions/claude-gateway/index.ts
//
// Claude 3 Messages API を叩く Supabase Edge Function
// -----------------------------------------------
// 期待する POST ボディ:
// {
//   "messages": [{"role": "user", "content": "ユーザーが送るプロンプト文字列"}],
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
  messages: Array<{role: string, content: string}>;
  model?: string;
  system?: string;
  max_tokens?: number;
  stream?: boolean;
}

serve(async (req) => {
  try {
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

  // ① 受信直後。body を丸ごと吐く
  const reqBody = await req.json();
  console.log("📥 GATEWAY RECEIVED >>>", JSON.stringify(reqBody, null, 2));

  const {
    messages,
    model = "claude-3-7-sonnet-20250219",
    system,
    max_tokens,
    stream = true,
  } = reqBody;

  if (!messages || messages.length === 0) {
    return new Response(
      JSON.stringify({ error: "`messages` is required" }),
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

  // ② Claude に投げる直前で中身を確認
  const claudePayload = {
    model,
    max_tokens: max_tokens ?? 1024,
    stream,
    system,
    messages,
  };
  console.log("🚀 FORWARD TO CLAUDE >>>", JSON.stringify(claudePayload, null, 2));

  const anthropicRes = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "anthropic-version": "2023-06-01",
      "x-api-key": apiKey,
    },
    body: JSON.stringify(claudePayload),
  });

  // ③ 失敗時のレスポンスに body も同梱
  if (!anthropicRes.ok) {
    const errText = await anthropicRes.text();
    return new Response(
      JSON.stringify({ error: errText, forwardedBody: claudePayload }),
      { status: anthropicRes.status, headers: { ...cors, "content-type": "application/json" } },
    );
  }

  // ─────────── クライアントへ転送 ───────────
  // stream = true なら SSE, false なら普通の JSON
  const responseHeaders = {
    ...cors,
    "content-type": stream ? "text/event-stream" : "application/json",
    "cache-control": "no-cache",
  };

  // ストリーミングの場合、接続維持とチャンク転送を明示的にヘッダーに追加
  // Deno は通常自動で処理するが、明示することで安定性が増す場合がある
  if (stream) {
    responseHeaders["connection"] = "keep-alive";
    responseHeaders["transfer-encoding"] = "chunked";
  }

    return new Response(anthropicRes.body, {
      status: anthropicRes.status,
      headers: responseHeaders,
    });
  } catch (err) {
    console.error("❌ EDGE EXCEPTION", err);
    return new Response(
      JSON.stringify({ error: String(err), body: reqBody }),
      { status: 400, headers: { ...cors, "content-type": "application/json" } },
    );
  }
});
