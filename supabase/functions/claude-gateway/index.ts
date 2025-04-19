import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

serve(async (req) => {
    const { prompt } = await req.json();

    const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
            "x-api-key": Deno.env.get("CLAUDE_API_KEY"), // ← キーはsupabase secretsで注入
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        body: JSON.stringify({
            model: "claude-3-sonnet-20240229",
            messages: [
                { role: "user", content: prompt },
            ],
            max_tokens: 1024,
        }),
    });

    const data = await response.json();
    return new Response(JSON.stringify(data));
});
