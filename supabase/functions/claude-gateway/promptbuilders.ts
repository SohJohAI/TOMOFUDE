function buildReviewPrompt(p: any): string {
    return `@Claude-3.7-Sonnet 以下の小説を異なる3つの視点からレビューを生成してください。それぞれのレビューは100字程度で簡潔に作成してください。
  
  1. 読者視点: 一般読者としての感想。特に物語の面白さ、感情移入のしやすさ、没入感などを評価。
  2. 編集者視点: 文章の構成、ストーリー展開、キャラクター設定などの技術的な側面を評価。
  3. 審査員視点: 文学としての価値、テーマ性、作品の独自性などを評価。
  
  小説:
  ${p.analysisContent}
  
  Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
  {
    "reader": "読者視点からのレビュー文",
    "editor": "編集者視点からのレビュー文",
    "jury": "審査員視点からのレビュー文"
  }`;
  }
  
  function buildAIDocsPrompt(p: any): string {
    return `@Claude-3.7-Sonnet あなたは小説の執筆支援AIです。以下の小説から、AIが執筆支援をする際に役立つ包括的な資料を作成してください。
  
  小説の本文:
  ${p.content}
  
  設定情報:
  ${p.settingInfo}
  
  プロット情報:
  ${p.plotInfo}
  
  感情分析:
  ${p.emotionInfo}
  
  以下の項目を含む、構造化された資料を作成してください:
  
  1. 作品概要
  2. 登場人物
  3. 世界設定
  4. 物語構造
  5. 文体と語り口
  6. 重要な伏線と未解決の謎
  7. 今後の展開に向けた注意点
  
  この資料はAIが物語の続きを書く際や、小説に関する質問に答える際に参照する資料となります。情報は具体的かつ詳細に、しかし簡潔にまとめてください。`;
  }
  
  function buildEmotionAnalysisPrompt(p: any): string {
    const body = p.aiDocs
      ? `\n\n小説情報:\n${p.aiDocs}`
      : `\n\n小説の一部:\n${p.analysisContent.substring(0, Math.min(1000, p.analysisContent.length))}`;
  
    return `@Claude-3.7-Sonnet あなたは小説の感情分析AIです。提供された小説情報を元に、読者が感じるであろう感情を特定してください。
  
  ## 分析手順
  1. 小説を5つの主要セクションに分割してください：導入、展開、転機/決断、クライマックス、結末
  2. 各セクションで最も強く表れている感情を以下のカテゴリから選択：
     - 悲しみ（#3498db）
     - 不安（#9b59b6）
     - 緊張（#e74c3c）
     - 期待（#f1c40f）
     - 喜び（#2ecc71）
  3. 各セクションの盛り上がり度を1〜100で評価
  4. 感情と盛り上がりの理由を説明${body}
  
  Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
  {
    "segments": [ ... ],
    "summary": "..."
  }`;
  }
  
  function buildPlotAnalysisPrompt(p: any): string {
    const body = p.aiDocs
      ? `\n\n小説情報:\n${p.aiDocs}`
      : `\n\n小説の最近の部分:\n${p.newContent.substring(0, Math.min(800, p.newContent.length))}`;
  
    return `@Claude-3.7-Sonnet 物語全体のプロット構造を分析して、ストーリーの各要素をJSON形式で整理してください。
  
  主要要素の特定:
  - 導入部
  - 主な出来事
  - 転換点
  - 現在の展開状況
  - 未解決の問題
  - 予想される展開${body}
  
  Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
  {
    "introduction": "...",
    "mainEvents": ["...", "..."],
    "turningPoints": ["..."],
    "currentStage": "...",
    "unresolvedIssues": ["..."],
    "possibleDevelopments": ["..."]
  }`;
  }
  
  function buildSettingsPrompt(p: any): string {
    const body = p.aiDocs
      ? `\n\n小説情報:\n${p.aiDocs}`
      : `\n\n分析対象文章（${p.contentType}）:\n${p.analysisContent.substring(0, Math.min(800, p.analysisContent.length))}`;
  
    return `@Claude-3.7-Sonnet 登場人物、組織、舞台、ジャンル、専門用語の設定情報を抽出・蓄積してJSON形式で返してください。
  
  ${body}
  
  これまでに蓄積した設定情報がある場合は、それに新しい情報を追加・更新してください。ない場合は、新規に作成してください。
  
  Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
  {
    "characters": [...],
    "organizations": [...],
    "terminology": [...],
    "setting": "...",
    "genre": "..."
  }`;
  }
  
  function buildContinuationsPrompt(p: any): string {
    const body = p.aiDocs
      ? `\n\n小説情報（これを元に展開候補を提案してください）:\n${p.aiDocs}`
      : `\n\n最近追加された部分:\n${p.newContent.substring(0, Math.min(500, p.newContent.length))}\n\n設定情報:\n${p.settingInfo}`;
  
    return `@Claude-3.7-Sonnet 小説の次に展開しそうな内容を3つ、簡潔に提案してください。各提案は一文で、具体的かつ魅力的なものにしてください。
  
  ${body}
  
  Provide ONLY raw JSON in your response with no explanations, additional text, or code block formatting (no \`\`\`). JSON format:
  {
    "suggestions": [
      "提案1",
      "提案2",
      "提案3"
    ]
  }`;
  }
  
  function buildExpandSuggestionPrompt(p: any): string {
    const body = p.aiDocs
      ? `\n\n小説情報:\n${p.aiDocs}`
      : `\n\n小説の最近の部分:\n${p.recentContent.substring(0, Math.min(500, p.recentContent.length))}`;
  
    return `@Claude-3.7-Sonnet あなたは小説執筆アシスタントです。選択された展開に沿った続きを書いてください。続きは200〜300字程度にしてください。文体や雰囲気を一致させてください。追加説明は不要です、純粋に小説の続きのみを提供してください。
  
  選択された展開:
  ${p.suggestion}${body}`;
  }
  