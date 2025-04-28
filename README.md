# TOMOFUDE - AI小説執筆アプリ

「共筆。」（TOMOFUDE）は、AIを活用した小説執筆支援アプリです。

## 主な機能

### AI小説執筆支援
- **文章生成**: Claude AIを活用した高品質な文章生成
- **続き提案**: 小説の続きを複数候補から選択
- **文章展開**: 選択した候補を自然な段落に展開
- **感情分析**: 小説の感情の流れを視覚化

### プロットブースター
プロットブースターは、物語の骨子を対話的に作り上げる8ステップの支援ツールです。
1. **ジャンル・作風**: 物語のジャンルと全体的な作風を決定
2. **ログライン**: 物語の核となる一文を作成
3. **テーマ**: 物語のテーマと伝えたいメッセージを設定
4. **世界観**: 物語の舞台となる世界の設定
5. **キー設定**: 物語の鍵となる要素を設定
6. **キャラクター**: 登場人物の設定と関係性を構築
7. **章構成**: 物語の構造と展開を計画
8. **出力**: 完成したプロットの確認と出力

### ポイント決済システム
- **ポイント管理**: 無料ポイントと有料ポイントの管理
- **紹介コード**: 友達紹介プログラムによるポイント獲得
- **ポイント履歴**: ポイントの獲得・消費履歴の表示
- **月次リセット**: 無料ポイントの月次リセット機能

### サブスクリプションプラン
- **梅プラン**: ¥500/月、500ポイント/月
- **竹プラン**: ¥980/月、1000ポイント/月
- **松プラン**: ¥1980/月、2000ポイント/月

## 技術スタック

- **フロントエンド**: Flutter
- **バックエンド**: Supabase
  - Supabase Authentication: ユーザー認証
  - Supabase Database: データベース
  - Supabase Edge Functions: サーバーサイドロジック
  - Supabase Storage: ファイルストレージ
- **AI**: Claude API (Anthropic)
- **決済**: Stripe

## アーキテクチャの改善

### サービス層
- **サービスロケーター**: `get_it`パッケージを使用した依存性注入の実装
- **インターフェース分離**: サービスクラスにインターフェースを導入し、テスト容易性を向上
- **エラーハンドリング**: 統一されたエラーハンドリングメカニズムの導入
- **コード構造**: サービス層の一貫性を確保し、責任の分離を明確化

### Web対応の改善
- **プラットフォーム分離**: Web版とネイティブ版の実装を明確に分離
- **モックサービス**: Web版での一貫したモックサービスの提供
- **互換性**: JavaScriptインターオペラビリティの改善

### セキュリティの強化
- **エラーログ**: 適切なエラーログ記録と表示の実装
- **例外処理**: すべてのサービスでの統一された例外処理
- **ユーザーフィードバック**: エラー発生時のユーザーフレンドリーなメッセージ表示

### 開発者エクスペリエンスの向上
- **ドキュメント**: コードコメントとREADMEの充実
- **テスト容易性**: インターフェースを活用したモック可能な設計
- **コード再利用**: 共通ロジックの抽出と再利用

## ディレクトリ構造

```
lib/
  ├── models/                    # データモデル
  │   ├── chapter.dart           # 章モデル
  │   ├── emotion.dart           # 感情分析モデル
  │   ├── novel.dart             # 小説モデル
  │   ├── plot_booster.dart      # プロットブースターモデル
  │   ├── point_history.dart     # ポイント履歴モデル
  │   ├── referral_code.dart     # 紹介コードモデル
  │   ├── subscription_plan.dart # サブスクリプションプランモデル
  │   ├── user_point.dart        # ユーザーポイントモデル
  │   ├── work.dart              # 作品モデル
  │   └── work_list.dart         # 作品リストモデル
  ├── providers/                 # 状態管理
  │   ├── payment_provider.dart  # 決済関連の状態管理
  │   ├── plot_booster_provider.dart # プロットブースター状態管理
  │   └── work_list_provider.dart # 作品リスト状態管理
  ├── screens/                   # 画面
  │   ├── auth_screen.dart       # 認証画面
  │   ├── chapter_editor_screen.dart # 章エディタ画面
  │   ├── editor_screen.dart     # エディタ画面
  │   ├── payment_screen.dart    # 決済画面
  │   ├── plot_booster_screen.dart # プロットブースター画面
  │   ├── point_history_screen.dart # ポイント履歴画面
  │   ├── referral_code_screen.dart # 紹介コード画面
  │   ├── subscription_screen.dart # サブスクリプション画面
  │   └── work_list_screen.dart  # 作品リスト画面
  ├── services/                  # サービス
  │   ├── ai_service_interface.dart # AI サービスインターフェース
  │   ├── ai_service.dart        # AI サービス実装
  │   ├── auth_service_interface.dart # 認証サービスインターフェース
  │   ├── auth_service.dart      # 認証サービス実装
  │   ├── claude_ai_service.dart # Claude AI サービス
  │   ├── export_service.dart    # エクスポートサービス
  │   ├── plot_booster_service.dart # プロットブースターサービス
  │   ├── point_service_interface.dart # ポイントサービスインターフェース
  │   ├── point_service.dart     # ポイントサービス実装
  │   ├── service_locator.dart   # サービスロケーター
  │   ├── stripe_service_interface.dart # Stripe サービスインターフェース
  │   ├── stripe_service.dart    # Stripe サービス実装
  │   ├── supabase_auth_service.dart # Supabase 認証サービス
  │   ├── supabase_database_service.dart # Supabase データベースサービス
  │   └── supabase_service.dart  # Supabase サービス
  ├── utils/                     # ユーティリティ
  │   ├── ai_helper.dart         # AI ヘルパー
  │   ├── constants.dart         # 定数
  │   └── error_handler.dart     # エラーハンドリング
  └── widgets/                   # ウィジェット
      ├── ai_panel.dart          # AI パネル
      ├── emotion_panel.dart     # 感情パネル
      ├── novel_editor.dart      # 小説エディタ
      ├── point_display_widget.dart # ポイント表示
      ├── ruby_text_widget.dart  # ルビテキスト
      └── steps/                 # プロットブースターステップ
          ├── genre_style_step.dart # ジャンル・作風ステップ
          ├── logline_step.dart  # ログラインステップ
          └── ...                # その他のステップ

supabase/
  ├── functions/                 # Edge Functions
  │   ├── claude-gateway/        # Claude API ゲートウェイ
  │   │   ├── index.ts           # メイン関数
  │   │   └── promptbuilders.ts  # プロンプトビルダー
  │   └── stripe-webhook/        # Stripe Webhook
  │       └── index.ts           # Webhook ハンドラー
  └── migrations/                # データベースマイグレーション
      └── 20250418_add_subscription_support.sql # サブスクリプション対応
```

## セットアップ手順

### 1. Supabaseセットアップ

1. [Supabase](https://supabase.com)でアカウントを作成し、新しいプロジェクトを作成します。
2. プロジェクトのURLとAPIキーを取得します。
3. `lib/services/supabase_service.dart`を編集して、Supabaseの認証情報を設定します。

```dart
/// Supabase URL - Replace with your Supabase URL
static const String _supabaseUrl = 'YOUR_SUPABASE_URL';

/// Supabase API Key - Replace with your Supabase API Key
static const String _supabaseKey = 'YOUR_SUPABASE_API_KEY';
```

4. Supabase CLIをインストールし、Edge Functionsをデプロイします。

```bash
# Supabase CLIのインストール
npm install -g supabase

# ログイン
supabase login

# プロジェクトの初期化
supabase init
```

### 2. Claude API Gatewayの設定

1. Claude APIキーを取得します。
2. Supabase Edge Functionsに環境変数を設定します。

```bash
# 環境変数（API キー）の設定
supabase secrets set CLAUDE_API_KEY=sk_xxx

# Edge Functionのデプロイ
supabase functions deploy claude-gateway
```

3. `lib/services/claude_ai_service.dart`を編集して、Edge FunctionのURLを設定します。

```dart
final aiService = ClaudeAIService(
  claudeGatewayUrl: 'https://[project-id].functions.supabase.co/claude-gateway',
);
```

### 3. Stripe決済システムの設定

1. [Stripe Dashboard](https://dashboard.stripe.com/)でアカウントを作成し、APIキーを取得します。
2. Webhookを設定します。
   - Webhookエンドポイント: `https://[YOUR_SUPABASE_PROJECT_ID].functions.supabase.co/stripe-webhook`
   - イベント: `checkout.session.completed`, `invoice.payment_succeeded`, `customer.subscription.deleted`
3. Supabase Edge Functionsに環境変数を設定します。

```bash
supabase secrets set STRIPE_SECRET_KEY=sk_xxx --project-ref [YOUR_SUPABASE_PROJECT_ID]
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxx --project-ref [YOUR_SUPABASE_PROJECT_ID]
```

4. Edge Functionをデプロイします。

```bash
supabase functions deploy stripe-webhook --project-ref [YOUR_SUPABASE_PROJECT_ID]
```

5. `lib/services/stripe_service.dart`を編集して、Stripeの公開可能キーを設定します。

```dart
Stripe.publishableKey = kReleaseMode
    ? 'pk_live_your_publishable_key' // 本番環境用キー
    : 'pk_test_your_test_publishable_key'; // テスト環境用キー
```

## 開発者ガイド

詳細な開発者ガイドは以下のファイルを参照してください：

- [Supabaseセットアップガイド](supabase_setup.md)
- [Supabase認証ガイド](supabase_auth_guide.md)
- [Supabaseデータベースガイド](supabase_database_guide.md)
- [Claude API Gatewayガイド](claude_api_gateway_guide.md)
- [Stripe決済システムガイド](stripe_payment_guide.md)

## ポイントシステムの仕組み

1. **ポイントの種類**:
   - 無料ポイント: 毎月リセットされる無料ポイント
   - 有料ポイント: 購入したポイント（有効期限なし）

2. **ポイントの獲得方法**:
   - 新規登録ボーナス: 1000ポイント
   - 紹介コード使用: 500ポイント
   - 友達を紹介: 1500ポイント
   - サブスクリプション: プランに応じた月額ポイント

3. **ポイントの消費**:
   - AIによる小説執筆支援
   - プロットブースターの高度な機能
   - 感情分析ツール
   - その他の有料機能

4. **ポイントの有効期限**:
   - 無料ポイント: 毎月1日にリセット
   - 有料ポイント: 無期限
   - ボーナスポイント: 獲得から3ヶ月

## 注意事項

- 実際の決済機能を実装する場合は、Apple App StoreやGoogle Play Storeの規約に従ってください。
- ポイントの購入機能を実装する場合は、In-App Purchaseを使用してください。
- 本番環境では、Supabase Authenticationの認証方法を適切に設定してください。
