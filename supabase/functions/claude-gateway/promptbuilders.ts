// ───────────────────────────
// 1. レビュー生成
function buildReviewPrompt(p: any): string {
  return `小説を3視点で各100字レビューせよ。
1. 読者
2. 編集者
3. 審査員
本文:
${p.analysisContent}

レスポンスはJSONのみ:
{"reader":"", "editor":"", "jury":""}`;
}

// ───────────────────────────
// 2. AI 執筆支援資料
function buildAIDocsPrompt(p: any): string {
  return `以下の小説情報を基に執筆支援資料を作成。
本文:${p.content}
設定:${p.settingInfo}
プロット:${p.plotInfo}
感情:${p.emotionInfo}

求める項目:
1. 概要 2. 登場人物 3. 世界観 4. 構造 5. 文体 6. 伏線 7. 今後の注意点
簡潔だが具体的に。`;
}

// ───────────────────────────
// 3. 感情分析
function buildEmotionAnalysisPrompt(p: any): string {
  const body = p.aiDocs
    ? `\n資料:\n${p.aiDocs}`
    : `\n抜粋:\n${p.analysisContent.slice(0,1000)}`;

  return `小説を導入/展開/転機/山場/結末の5区分で感情分析。
感情: 悲しみ, 不安, 緊張, 期待, 喜び
各区分に (感情, 盛り上がり1‑100, 理由) を付けよ。${body}

JSONのみ:
{"segments":[…], "summary":""}`;
}

// ───────────────────────────
// 4. プロット分析
function buildPlotAnalysisPrompt(p: any): string {
  const body = p.aiDocs
    ? `\n資料:\n${p.aiDocs}`
    : `\n抜粋:\n${p.newContent.slice(0,800)}`;

  return `物語構造を分析しJSON化。
- 導入
- 主イベント
- 転換点
- 現状
- 未解決
- 予想展開${body}

JSONのみ:
{"introduction":"", "mainEvents":[], "turningPoints":[],
 "currentStage":"", "unresolvedIssues":[], "possibleDevelopments":[]}`;
}

// ───────────────────────────
// 5. 設定抽出
function buildSettingsPrompt(p: any): string {
  const body = p.aiDocs
    ? `\n資料:\n${p.aiDocs}`
    : `\n対象(${p.contentType}):\n${p.analysisContent.slice(0,800)}`;

  return `登場人物・組織・用語・舞台・ジャンルを抽出し更新。
${body}

JSONのみ:
{"characters":[], "organizations":[], "terminology":[],
 "setting":"", "genre":""}`;
}

// ───────────────────────────
// 6. 展開候補
function buildContinuationsPrompt(p: any): string {
  const body = p.aiDocs
    ? `\n資料:\n${p.aiDocs}`
    : `\n最新:\n${p.newContent.slice(0,500)}\n設定:\n${p.settingInfo}`;

  return `物語の次の展開を一文×3提案せよ。${body}

JSONのみ: {"suggestions":["","",""]}`;
}

// ───────────────────────────
// 7. 続き生成
function buildExpandSuggestionPrompt(p: any): string {
  const body = p.aiDocs
    ? `\n資料:\n${p.aiDocs}`
    : `\n抜粋:\n${p.recentContent.slice(0,500)}`;

  return `選択展開に沿って200‑300字で続きを執筆。説明不要。文体維持。
展開:${p.suggestion}${body}`;
}
