# Claude API Gateway 実装ガイド

このガイドでは、Supabase Edge Functionを使用してClaude APIへのゲートウェイを実装する方法について説明します。

## 概要

Claude APIを直接フロントエンドから呼び出すのではなく、Supabase Edge Functionを経由することで、以下のメリットがあります：

1. **セキュリティの向上**: API キーをフロントエンドコードに埋め込む必要がなくなります
2. **柔軟性**: バックエンド側でリクエストの前処理や後処理を行うことができます
3. **コスト管理**: APIの使用状況を一元管理できます

## 実装済みのコンポーネント

このプロジェクトでは、以下のコンポーネントが実装されています：

1. **Claude API Gateway Edge Function**: `supabase/functions/claude-gateway/index.ts`
   - Claude APIへのリクエストを中継するEdge Function

2. **ClaudeAIService**: `lib/services/claude_ai_service.dart`
   - AIServiceインターフェースを実装したClaude APIクライアント
   - アプリケーションからClaude APIを利用するためのサービスクラス

3. **使用例**: `lib/examples/claude_ai_service_example.dart`
   - ClaudeAIServiceの使用方法を示すサンプルコード

## デプロイ手順

### 1. Edge Functionのデプロイ

Supabase CLIを使用して、Edge Functionをデプロイします：

```bash
# 環境変数（API キー）の設定
supabase secrets set CLAUDE_API_KEY=sk-xxx

# Edge Functionのデプロイ
supabase functions deploy claude-gateway
```

デプロイが成功すると、以下のようなURLが表示されます：

```txt
https://[project-id].functions.supabase.co/claude-gateway
```

このURLをメモしておいてください。アプリケーションからのリクエスト時に使用します。

### 2. アプリケーションでの設定

#### ClaudeAIServiceの初期化

`ClaudeAIService`クラスを初期化する際に、Edge FunctionのURLを指定します：

```dart
final aiService = ClaudeAIService(
  claudeGatewayUrl: 'https://[project-id].functions.supabase.co/claude-gateway',
);
```

#### サービスロケーターを使用する場合

アプリケーションでサービスロケーターを使用している場合は、以下のように登録します：

```dart
serviceLocator.registerSingleton<AIService>(
  ClaudeAIService(
    claudeGatewayUrl: 'https://[project-id].functions.supabase.co/claude-gateway',
  ),
);
```

その後、以下のようにサービスを取得して使用できます：

```dart
final aiService = serviceLocator<AIService>();
```

## 使用方法

### 小説の続きの候補を生成

```dart
// 小説の続きの候補を生成
List<String> continuations = await aiService.generateContinuations(novelText);

// 結果の例
// [
//   "彼女は深く息を吸い込み、決意を固めた。これが最後のチャンスだと分かっていた。",
//   "遠くから聞こえてくる足音。彼は身を隠し、状況を見極めることにした。",
//   "「もうこれ以上逃げられない」彼はついに向き合う時が来たことを悟った。"
// ]
```

### 選択した候補を展開

```dart
// 選択した候補を展開して段落にする
String expandedText = await aiService.expandSuggestion(
  novelText,
  "彼女は深く息を吸い込み、決意を固めた。これが最後のチャンスだと分かっていた。"
);

// 結果の例
// "彼女は深く息を吸い込み、決意を固めた。これが最後のチャンスだと分かっていた。
// 指先が震えるのを感じながらも、ドアノブに手をかけた。向こう側で待っているものが
// 何であれ、もう後戻りはできない。運命の歯車は既に回り始めていた。"
```

### 感情分析

```dart
// 小説の感情分析を行う
Map<String, dynamic> emotionAnalysis = await aiService.analyzeEmotion(novelText);

// 結果の例（JSONオブジェクト）
// {
//   "segments": [
//     {
//       "name": "セグメント 1",
//       "dominantEmotion": "期待",
//       "emotionCode": "#FF69B4",
//       "emotionValue": 75,
//       "excitement": 60,
//       "description": "新たな可能性への期待感が中心です。"
//     },
//     ...
//   ],
//   "summary": "物語全体を通して期待と不安の感情が主流となっており..."
// }
```

### AI資料の生成

```dart
// 執筆支援のためのAI資料を生成
String aiDocs = await aiService.generateAIDocs(
  novelText,
  settingInfo: settingInfo,
  plotInfo: plotInfo,
  emotionInfo: emotionInfo
);

// 結果の例
// 【AI資料】
//
// ■ 内容分析
// ・文体: 叙述的
// ・テーマ: 成長
// ・特徴: 心理描写が繊細
//
// ■ 執筆アドバイス
// ・登場人物の動機をより明確にすると良いでしょう
// ・五感を使った描写を増やすと臨場感が増します
```

## トラブルシューティング

### Edge Functionのデプロイに失敗する場合

- Supabase CLIが最新バージョンであることを確認してください
- プロジェクトのルートディレクトリで実行しているか確認してください
- Supabaseプロジェクトが正しく設定されているか確認してください

### APIリクエストが失敗する場合

- Edge FunctionのURLが正しいか確認してください
- Claude API キーが正しく設定されているか確認してください
- ネットワーク接続に問題がないか確認してください

### レスポンスの解析に失敗する場合

- Claude APIのレスポンス形式が変更された可能性があります
- `_extractTextFromClaudeResponse`メソッドを確認し、必要に応じて更新してください

## 拡張案

このゲートウェイは基本的な実装ですが、以下のような拡張が考えられます：

1. **認証の追加**: Edge Functionにアクセス制限を設けて、認証されたユーザーのみがアクセスできるようにする
2. **レート制限**: ユーザーごとにAPIの使用回数を制限する
3. **キャッシュ機能**: 同じプロンプトに対する応答をキャッシュして、APIコールを削減する
4. **プロンプトテンプレート**: サーバー側で定義したプロンプトテンプレートを使用して、一貫性のある応答を得る
5. **エラーハンドリングの強化**: より詳細なエラーメッセージとリトライ機能の追加

## 参考リンク

- [Supabase Edge Functions ドキュメント](https://supabase.com/docs/guides/functions)
- [Claude API ドキュメント](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [Flutter HTTP パッケージ](https://pub.dev/packages/http)
