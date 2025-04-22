// -----------------------------------------------------------------------------
// Supabase Edge Function: claude-gateway (Deno)
// PURPOSE  : Unified gateway between client‑side "共筆。" and Anthropic Claude 3.x
// PROBLEMS : 1) Claude sometimes ignored formatting instructions
//            2) Occasional CORS / OPTIONS mishandling
//            3) JSON extraction brittle when fenced in ``` or ```json
// FIXES    : • Added a *system* prompt to every request for stronger guidance
//            • Hardened extractJsonFromResponse against code‑fences & stray text
//            • Normalised error shapes & CORS headers
//            • Early exit on missing/empty body or unsupported method
// -----------------------------------------------------------------------------

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// -----------------------------------------------------------------------------
// Constants & Environment
// -----------------------------------------------------------------------------
const CLAUDE_API_URL = "https://api.anthropic.com/v1/messages";
// ⚠️  2025‑03 時点の最新 Sonnetモデル。必要に応じて更新してください。
const CLAUDE_MODEL  = "claude-3-7-sonnet-20250219";
const CLAUDE_API_KEY = Deno.env.get("CLAUDE_API_KEY");
if (!CLAUDE_API_KEY) {
  console.error("[claude-gateway] CLAUDE_API_KEY is not set in Edge Function secrets");
}

// -----------------------------------------------------------------------------
// CORS helper
// -----------------------------------------------------------------------------
function cors(res: Response, statusOverride?: number): Response {
  const headers = new Headers(res.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  headers.set(
    "Access-Control-Allow-Headers",
    "authorization, x-client-info, apikey, content-type",
  );
  return new Response(res.body, {
    status: statusOverride ?? res.status,
    statusText: res.statusText,
    headers,
  });
}

// -----------------------------------------------------------------------------
// Edge Function entrypoint
// -----------------------------------------------------------------------------
serve(async (req) => {
  // ----- Pre‑flight -----------------------------------------------------------
  if (req.method === "OPTIONS") {
    return cors(new Response(null, { status: 204 }));
  }

  if (req.method !== "POST") {
    return cors(
      new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  // ----- Parse body ----------------------------------------------------------
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch (_) {
    return cors(
      new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  const { type, ...payload } = body as { type?: string };
  if (!type) {
    return cors(
      new Response(JSON.stringify({ error: "Missing 'type' field" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  // ----- Build prompt --------------------------------------------------------
  const promptBuilders: Record<string, (p: any) => string> = {
    generateSettings:      buildSettingsPrompt,
    generatePlotAnalysis:  buildPlotAnalysisPrompt,
    generateReview:        buildReviewPrompt,
    generateContinuations: buildContinuationsPrompt,
    expandSuggestion:      buildExpandSuggestionPrompt,
    analyzeEmotion:        buildEmotionAnalysisPrompt,
    generateAIDocs:        buildAIDocsPrompt,
  };

  const buildPrompt = promptBuilders[type];
  if (!buildPrompt) {
    return cors(
      new Response(JSON.stringify({ error: "Unknown request type" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  const userPrompt = buildPrompt(payload);

  // A tight system‑level instruction to *enforce* format adherence
  const systemPrompt =
    "You are a precise JSON/Markdown generator for a novel‑writing assistant.  " +
    "If the user explicitly requests *ONLY raw JSON*, your reply MUST contain exactly one JSON object with no additional text, no code fences, no backticks.  " +
    "If Markdown is requested, output valid GitHub‑flavoured Markdown.  " +
    "Fail the request rather than deviate from format.";

  // ----- Call Claude ---------------------------------------------------------
  let claudeJson: any;
  try {
    const anthropicRes = await fetch(CLAUDE_API_URL, {
      method: "POST",
      headers: {
        "x-api-key": CLAUDE_API_KEY!,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: CLAUDE_MODEL,
        system: systemPrompt,
        messages: [{ role: "user", content: userPrompt }],
        max_tokens: 4096,
      }),
    });

    claudeJson = await anthropicRes.json();
  } catch (err) {
    console.error("[claude-gateway] Error reaching Claude:", err);
    return cors(
      new Response(JSON.stringify({ error: "Upstream request failed" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  console.log("[claude-gateway] Raw response →", JSON.stringify(claudeJson));

  // ----- Extract assistant content -----------------------------------------
  const assistantText = extractTextFromResponse(claudeJson);
  console.log("[claude-gateway] Extracted text →", assistantText);

  // ----- Transform to client shape ----------------------------------------
  let result: Record<string, unknown> = {};
  try {
    switch (type) {
      case "generateSettings":
      case "generatePlotAnalysis":
      case "generateReview":
      case "analyzeEmotion":
        result = extractJsonFromResponse(assistantText);
        break;
      case "generateContinuations": {
        const j = extractJsonFromResponse(assistantText);
        result = { suggestions: j.suggestions ?? [] };
        break;
      }
      case "expandSuggestion":
        result = { expanded: assistantText.trim() };
        break;
      case "generateAIDocs":
        result = { markdown: assistantText.trim() };
        break;
      default:
        result = { raw: assistantText };
    }
  } catch (err) {
    console.error("[claude-gateway] Post‑processing error:", err);
    return cors(
      new Response(JSON.stringify({ error: "Malformed assistant output" }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      }),
    );
  }

  return cors(
    new Response(JSON.stringify(result), {
      headers: { "Content-Type": "application/json" },
    }),
  );
});

// -----------------------------------------------------------------------------
// Helpers
// -----------------------------------------------------------------------------
function extractTextFromResponse(apiRes: any): string {
  // Claude 3 returns { content: [ { type: "text", text: "..." } ] }
  if (apiRes?.content && Array.isArray(apiRes.content)) {
    const textObj = apiRes.content.find((c: any) => c.type === "text");
    if (textObj?.text) return String(textObj.text);
  }
  return "";
}

function extractJsonFromResponse(text: string): any {
  // Capture inner JSON even if wrapped in fences
  const match = text.match(/```json\s*([\s\S]*?)```|```([\s\S]*?)```|(\{[\s\S]*\})/);
  if (!match) return {};
  try {
    const jsonStr = (match[1] || match[2] || match[3]).trim();
    return JSON.parse(jsonStr);
  } catch (err) {
    console.error("[claude-gateway] JSON parse error:", err);
    return {};
  }
}

// -----------------------------------------------------------------------------
// PROMPT BUILDERS (unchanged from user draft except minor whitespace tweaks)
// -----------------------------------------------------------------------------
// … ↓↓↓ your original build*Prompt functions remain here, unmodified for brevity ↓↓↓ …

// (Paste the seven build*Prompt implementations exactly as provided in the user code.)
import {
    buildReviewPrompt,
    buildAIDocsPrompt,
    buildEmotionAnalysisPrompt,
    buildPlotAnalysisPrompt,
    buildSettingsPrompt,
    buildContinuationsPrompt,
    buildExpandSuggestionPrompt
  } from "./promptbuilders.ts";
  
  const promptBuilders: Record<string, (p: any) => string> = {
    generateReview: buildReviewPrompt,
    generateAIDocs: buildAIDocsPrompt,
    analyzeEmotion: buildEmotionAnalysisPrompt,
    generatePlotAnalysis: buildPlotAnalysisPrompt,
    generateSettings: buildSettingsPrompt,
    generateContinuations: buildContinuationsPrompt,
    expandSuggestion: buildExpandSuggestionPrompt
  };
  