import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

// CORSヘッダーを設定する関数
function setCorsHeaders(response: Response): Response {
    const headers = new Headers(response.headers);
    headers.set("Access-Control-Allow-Origin", "*");
    headers.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    headers.set("Access-Control-Allow-Headers", "Content-Type");

    return new Response(response.body, {
        status: response.status,
        statusText: response.statusText,
        headers,
    });
}

serve(async (req) => {
    // OPTIONSリクエスト（プリフライトリクエスト）の処理
    if (req.method === "OPTIONS") {
        return setCorsHeaders(new Response(null, { status: 204 }));
    }

    try {
        const { type, ...payload } = await req.json();

        // プロンプトを構築
        let prompt = "";

        switch (type) {
            case "generateSettings":
                prompt = buildSettingsPrompt(payload);
                break;
            case "generatePlotAnalysis":
                prompt = buildPlotAnalysisPrompt(payload);
                break;
            case "generateReview":
                prompt = buildReviewPrompt(payload);
                break;
            case "generateContinuations":
                prompt = buildContinuationsPrompt(payload);
                break;
            case "expandSuggestion":
                prompt = buildExpandSuggestionPrompt(payload);
                break;
            case "analyzeEmotion":
                prompt = buildEmotionAnalysisPrompt(payload);
                break;
            case "generateAIDocs":
                prompt = buildAIDocsPrompt(payload);
                break;
            default:
                return setCorsHeaders(new Response(JSON.stringify({ error: "Unknown request type" }), {
                    status: 400,
                    headers: { "Content-Type": "application/json" }
                }));
        }

        // Claude APIにリクエスト
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
                max_tokens: 4096,
            }),
        });

        const claudeResponse = await response.json();

        // レスポンスを処理
        let result;

        switch (type) {
            case "generateSettings":
            case "generatePlotAnalysis":
                result = extractJsonFromResponse(claudeResponse);
                break;
            case "generateReview":
                result = extractJsonFromResponse(claudeResponse);
                break;
            case "generateContinuations":
                const suggestions = extractJsonFromResponse(claudeResponse);
                result = { suggestions: suggestions.suggestions || [] };
                break;
            case "expandSuggestion":
                result = { expanded: extractTextFromResponse(claudeResponse) };
                break;
            case "analyzeEmotion":
                result = extractJsonFromResponse(claudeResponse);
                break;
            case "generateAIDocs":
                result = { markdown: extractTextFromResponse(claudeResponse) };
                break;
            default:
                result = claudeResponse;
        }

        return setCorsHeaders(new Response(JSON.stringify(result), {
            headers: { "Content-Type": "application/json" }
        }));
    } catch (error) {
        console.error("Error processing request:", error);
        return setCorsHeaders(new Response(JSON.stringify({ error: error.message }), {
            status: 500,
            headers: { "Content-Type": "application/json" }
        }));
    }
});

// Claude APIのレスポンスからテキストを抽出
function extractTextFromResponse(response: any): string {
    try {
        if (response.content && Array.isArray(response.content)) {
            for (const item of response.content) {
                if (item.type === "text") {
                    return item.text;
                }
            }
        }
        return "";
    } catch (e) {
        console.error("Error extracting text from response:", e);
        return "";
    }
}

// Claude APIのレスポンスからJSONを抽出
function extractJsonFromResponse(response: any): any {
    try {
        const text = extractTextFromResponse(response);
        // JSONを抽出するための正規表現
        const jsonMatch = text.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
            return JSON.parse(jsonMatch[0]);
        }
        return {};
    } catch (e) {
        console.error("Error extracting JSON from response:", e);
        return {};
    }
}

// 設定情報生成プロンプト
function buildSettingsPrompt(payload: any): string {
    const { content, aiDocs, contentType } = payload;

    return `@Claude-3.7-Sonnet 登場人物、組織、舞台、ジャンル、専門用語の設定情報を抽出・蓄積してJSON形式で返してください。

登場人物については各キャラクターの名前だけでなく、性格や役割、背景なども継続的に更新して説明してください。
組織については組織名と、その目的や特徴、所属メンバーなどを説明してください。
舞台は場所や時代などの情報を、ジャンルはこの小説の種類を判断してください。
専門用語については作品内で使われる特殊な言葉や概念、固有名詞などを説明してください。

重要：あなたは小説の設定を管理するデータベース担当者です。文章から設定情報を蓄積してください。
登場人物、組織、舞台、専門用語などの説明を、新しい情報が出てくるたびに豊かにしていってください。
${aiDocs ? '\n\n小説情報:\n' + aiDocs : ''}
${!aiDocs && contentType ? '\n\n分析対象文章（' + contentType + '）:\n' + content.substring(0, Math.min(800, content.length)) : ''}

これまでに蓄積した設定情報がある場合は、それに新しい情報を追加・更新してください。
ない場合は、新規に作成してください。

Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
{
  "characters": [
    {
      "name": "キャラクター名1",
      "description": "性格や役割、背景などの詳細説明"
    },
    {
      "name": "キャラクター名2",
      "description": "性格や役割、背景などの詳細説明"
    }
  ],
  "organizations": [
    {
      "name": "組織名1",
      "description": "目的や特徴、所属メンバーなどの説明"
    },
    {
      "name": "組織名2",
      "description": "目的や特徴、所属メンバーなどの説明"
    }
  ],
  "terminology": [
    {
      "term": "専門用語1",
      "definition": "その用語の定義や説明"
    },
    {
      "term": "専門用語2",
      "definition": "その用語の定義や説明"
    }
  ],
  "setting": "舞台の詳細説明",
  "genre": "ジャンル"
}`;
}

// プロット分析プロンプト
function buildPlotAnalysisPrompt(payload: any): string {
    const { content, aiDocs, newContent } = payload;

    return `@Claude-3.7-Sonnet 物語全体のプロット構造を分析して、ストーリーの各要素をJSON形式で整理してください。

主要要素の特定:
- 導入部: 物語の設定やキャラクターが紹介される部分
- 主な出来事: 物語の中心となる重要なイベント
- 転換点: 物語の流れが変わるような重要な転機
- 現在の展開状況: 物語が現在どの段階にあるか（導入、展開、クライマックスなど）
- 未解決の問題: まだ解決していない問題やミステリー
- 予想される展開: 今後どのように物語が進む可能性があるか
${aiDocs ? '\n\n小説情報:\n' + aiDocs : ''}
${!aiDocs && newContent ? '\n\n小説の最近の部分:\n' + newContent.substring(0, Math.min(800, newContent.length)) : ''}

Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
{
  "introduction": "物語の導入部の説明",
  "mainEvents": ["出来事1", "出来事2", "出来事3"],
  "turningPoints": ["転換点1", "転換点2"],
  "currentStage": "現在の物語段階（導入/展開/クライマックス/結末など）",
  "unresolvedIssues": ["未解決の問題1", "未解決の問題2"],
  "possibleDevelopments": ["今後の展開予測1", "今後の展開予測2"]
}`;
}

// レビュー生成プロンプト
function buildReviewPrompt(payload: any): string {
    const { analysisContent } = payload;

    return `@Claude-3.7-Sonnet 以下の小説を異なる3つの視点からレビューを生成してください。それぞれのレビューは100字程度で簡潔に作成してください。

1. 読者視点: 一般読者としての感想。特に物語の面白さ、感情移入のしやすさ、没入感などを評価。
2. 編集者視点: 文章の構成、ストーリー展開、キャラクター設定などの技術的な側面を評価。
3. 審査員視点: 文学としての価値、テーマ性、作品の独自性などを評価。

小説:
${analysisContent}

Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
{
  "reader": "読者視点からのレビュー文",
  "editor": "編集者視点からのレビュー文",
  "jury": "審査員視点からのレビュー文"
}`;
}

// 続き候補生成プロンプト
function buildContinuationsPrompt(payload: any): string {
    const { content, aiDocs, newContent, settingInfo } = payload;

    return `@Claude-3.7-Sonnet 小説の次に展開しそうな内容を3つ、簡潔に提案してください。各提案は一文で、具体的かつ魅力的なものにしてください。

特に重要：小説の最近の部分に焦点を当てて、次の展開を考えてください。
本文の続きとしてふさわしい、自然な展開を提案してください。
一貫性のある展開を提案してください。
${aiDocs ? '\n\n小説情報（これを元に展開候補を提案してください）:\n' + aiDocs : ''}
${!aiDocs && newContent ? '\n\n最近追加された部分（または末尾部分）:\n' + newContent.substring(0, Math.min(500, newContent.length)) : ''}
${settingInfo ? '\n\n設定情報:\n' + settingInfo : ''}

Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
{
  "suggestions": [
    "提案1",
    "提案2",
    "提案3"
  ]
}`;
}

// 展開候補拡張プロンプト
function buildExpandSuggestionPrompt(payload: any): string {
    const { content, suggestion, aiDocs, recentContent } = payload;

    return `@Claude-3.7-Sonnet あなたは小説執筆アシスタントです。選択された展開に沿った続きを書いてください。続きは200〜300字程度にしてください。文体や雰囲気を一致させてください。追加説明は不要です、純粋に小説の続きのみを提供してください。

選択された展開:
${suggestion}
${aiDocs ? '\n\n小説情報（これを元に続きを書いてください）:\n' + aiDocs : ''}
${recentContent ? '\n\n小説の最近の部分:\n' + recentContent.substring(0, Math.min(500, recentContent.length)) : '\n\n小説の一部:\n' + content.substring(Math.max(0, content.length - 500), content.length)}`;
}

// 感情分析プロンプト
function buildEmotionAnalysisPrompt(payload: any): string {
    const { content, aiDocs } = payload;

    return `@Claude-3.7-Sonnet あなたは小説の感情分析AIです。提供された小説情報を元に、読者が感じるであろう感情を特定してください。

## 分析手順
1. 小説を5つの主要セクションに分割してください：導入、展開、転機/決断、クライマックス、結末
2. 各セクションで最も強く表れている感情を以下のカテゴリから選択してください：
   - 悲しみ（青: #3498db）
   - 不安（紫: #9b59b6）
   - 緊張（赤: #e74c3c）
   - 期待（黄: #f1c40f）
   - 喜び（緑: #2ecc71）
3. 各セクションの盛り上がり度（読者の興奮度や没入度）を1〜100の数値で評価してください
4. 各セクションの感情状態と盛り上がりの理由を簡潔に説明してください

## 分析の観点
- 登場人物の感情表現（言葉、行動、描写）
- 場面設定と雰囲気
- 比喩やイメージの使用
- ストーリーの展開速度と予測可能性
- 対話と内的独白のバランス
- 感情の対比と変化
${aiDocs ? '\n\n小説情報:\n' + aiDocs : ''}
${!aiDocs ? '\n\n小説の一部:\n' + content.substring(0, Math.min(1000, content.length)) : ''}

Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
{
  "segments": [
    {
      "name": "導入",
      "dominant_emotion": "悲しみ",
      "emotion_code": "#3498db", 
      "emotion_value": 80,
      "excitement": 30,
      "description": "失恋の痛みと孤独感が読者に伝わる。雨と涙のイメージが重なり、悲哀感が強調されている。"
    },
    {
      "name": "展開",
      "dominant_emotion": "不安",
      "emotion_code": "#9b59b6",
      "emotion_value": 70,
      "excitement": 40,
      "description": "突然の電話による不安と期待が入り混じり、緊張感が高まる。"
    },
    {
      "name": "転機/決断",
      "dominant_emotion": "緊張",
      "emotion_code": "#e74c3c",
      "emotion_value": 85,
      "excitement": 65,
      "description": "会うことを決意した主人公の葛藤と選択の瞬間の緊張感が伝わる。"
    },
    {
      "name": "クライマックス",
      "dominant_emotion": "期待",
      "emotion_code": "#f1c40f",
      "emotion_value": 90,
      "excitement": 85,
      "description": "再会シーンでの高揚感と期待、結末への予感が読者を引き込む。"
    },
    {
      "name": "結末",
      "dominant_emotion": "喜び",
      "emotion_code": "#2ecc71",
      "emotion_value": 95,
      "excitement": 90,
      "description": "告白による歓喜と喜びの涙が読者に感情的なカタルシスをもたらす。"
    }
  ],
  "summary": "悲しみから始まり、不安と緊張を経て、期待から喜びへと転換する感情の流れ。盛り上がり度も徐々に高まり、読者に強い感動を与える構成になっている。"
}`;
}

// AI資料生成プロンプト
function buildAIDocsPrompt(payload: any): string {
    const { content, settingInfo, plotInfo, emotionInfo } = payload;

    return `@Claude-3.7-Sonnet

# 指示
あなたは小説の執筆支援AIです。提供された小説本文と関連情報から、AIが執筆支援をする際に役立つ包括的な資料を作成してください。

# 入力情報
## 小説本文
${content}

${settingInfo ? '## 設定情報\n' + settingInfo + '\n' : ''}
${plotInfo ? '## プロット情報\n' + plotInfo + '\n' : ''}
${emotionInfo ? '## 感情分析\n' + emotionInfo + '\n' : ''}

# 出力形式
以下の項目を含む、Markdown形式で構造化された資料を作成してください。各セクションは見出しを使って明確に区分し、箇条書きやリストを適切に活用してください。

1. **作品概要**: ジャンル、テーマ、全体的な雰囲気、主要な筋書きを簡潔に説明
2. **登場人物**: 各キャラクターの詳細な人物像、動機、関係性、成長の軌跡
3. **世界設定**: 物語の舞台となる世界の詳細情報（地理、歴史、文化、魔法/技術システムなど）
4. **物語構造**: 現在までのプロット展開、重要な出来事のタイムライン、物語のペース
5. **文体と語り口**: 既存の文体の特徴（一人称/三人称、時制、語り口の特徴など）
6. **重要な伏線と未解決の謎**: 物語中に設置されている伏線や謎、その解決の可能性
7. **今後の展開に向けた注意点**: 一貫性を保ちながら物語を進めるための留意事項

# 重要事項
- この資料はAIが物語の続きを書く際や、小説に関する質問に答える際に参照する資料となります
- 情報は具体的かつ詳細に、しかし簡潔にまとめてください
- 小説本文から読み取れる情報を最大限に活用してください
- 情報が不足している場合は、「情報不足」と明記せず、現時点で判断できる範囲で最も妥当な推測を行ってください
- 出力はMarkdown形式で、見出し(#, ##, ###)、箇条書き(-, *)、強調(**太字**)などを適切に使用してください`;
}
