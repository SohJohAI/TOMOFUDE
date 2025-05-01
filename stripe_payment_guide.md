# Stripe決済システム導入ガイド

このガイドでは、TOMOFUDEアプリケーションにStripe決済システムを導入する方法について説明します。

## 概要

Stripeを使用して月額サブスクリプションプラン（梅・竹・松）を提供し、ユーザーがプランを購入すると、Supabaseのデータベースが更新され、ユーザーのプランとポイントが更新されます。

## 1. 実装済みの機能

以下の機能が実装されています：

1. **サブスクリプションプラン**
   - 梅プラン（¥500/月、500ポイント/月）
   - 竹プラン（¥980/月、1000ポイント/月）
   - 松プラン（¥1980/月、2000ポイント/月）

2. **Stripe決済フロー**
   - ユーザーがプランを選択
   - Stripe決済シートが表示される
   - 支払い完了後、Webhookでデータベースが更新される

3. **Supabaseとの連携**
   - ユーザーのプランとポイントがSupabaseに保存される
   - 支払い完了時にポイント履歴が記録される

## 2. セットアップ手順

### 2.1 Stripeアカウントの設定

1. [Stripe Dashboard](https://dashboard.stripe.com/)にログイン
2. APIキーを取得
   - 公開可能キー（Publishable Key）
   - シークレットキー（Secret Key）
3. Webhookの設定
   - Webhookエンドポイントを追加: `https://[YOUR_SUPABASE_PROJECT_ID].functions.supabase.co/stripe-webhook`
   - イベントを選択:
     - `checkout.session.completed`
     - `invoice.payment_succeeded`
     - `customer.subscription.deleted`
   - Webhookシークレットを取得

### 2.2 Supabase Functionsの設定

1. Supabase CLIをインストール（まだの場合）

   ```bash
   npm install -g supabase
   ```

2. ローカル開発環境を設定

   ```bash
   supabase login
   supabase init
   ```

3. Edge Functionをデプロイ

   ```bash
   supabase functions deploy stripe-webhook --project-ref [YOUR_SUPABASE_PROJECT_ID]
   ```

4. 環境変数を設定

   ```bash
   supabase secrets set STRIPE_SECRET_KEY=sk_xxx --project-ref [YOUR_SUPABASE_PROJECT_ID]
   supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_xxx --project-ref [YOUR_SUPABASE_PROJECT_ID]
   ```

### 2.3 アプリケーションの設定

1. `lib/services/stripe_service.dart`を編集して、Stripeの公開可能キーを設定

   ```dart
   Stripe.publishableKey = kReleaseMode
       ? 'pk_live_your_publishable_key' // 本番環境用キー
       : 'pk_test_your_test_publishable_key'; // テスト環境用キー
   ```

2. バックエンドAPIのURLを設定

   ```dart
   _apiUrl = kReleaseMode
       ? 'https://your-production-api.com' // 本番環境用API URL
       : 'http://localhost:3000'; // 開発環境用API URL
   ```

## 3. 使用方法

### 3.1 サブスクリプション画面へのアクセス

ポイント管理画面から「月額プランに加入する」ボタンをタップすると、サブスクリプション画面が表示されます。

### 3.2 プランの購入

1. サブスクリプション画面でプランを選択
2. 「購入する」ボタンをタップ
3. Stripe決済シートが表示される
4. カード情報を入力して支払いを完了
5. 支払いが完了すると、プランとポイントが更新される

### 3.3 サブスクリプションのキャンセル

1. サブスクリプション画面で現在のプランの「サブスクリプションをキャンセル」ボタンをタップ
2. 確認ダイアログで「キャンセルする」をタップ
3. 次回の更新日以降は課金されなくなる

## 4. 技術的な詳細

### 4.1 ファイル構成

- `lib/models/subscription_plan.dart` - サブスクリプションプランのモデル
- `lib/services/stripe_service_interface.dart` - Stripeサービスのインターフェース
- `lib/services/stripe_service.dart` - Stripeサービスの実装
- `lib/screens/subscription_screen.dart` - サブスクリプション画面
- `supabase/functions/stripe-webhook/index.ts` - Stripe Webhook処理用のEdge Function

### 4.2 決済フロー

1. ユーザーがプランを選択して「購入する」ボタンをタップ
2. `StripeService.startPayment()`が呼び出される
3. バックエンドAPIで`PaymentIntent`が作成される
4. Stripe決済シートが表示される
5. ユーザーが支払いを完了
6. Stripe WebhookがSupabase Edge Functionを呼び出す
7. Edge Functionがユーザーのプランとポイントを更新

### 4.3 Webhookの処理

Stripe Webhookは以下のイベントを処理します：

1. `checkout.session.completed` - 初回支払い完了時
2. `invoice.payment_succeeded` - 定期支払い完了時
3. `customer.subscription.deleted` - サブスクリプションキャンセル時

## 5. テスト方法

### 5.1 テストモードでの支払いテスト

Stripeのテストモードでは、以下のテストカード情報を使用できます：

- カード番号: `4242 4242 4242 4242`
- 有効期限: 任意の将来の日付
- CVC: 任意の3桁の数字
- 郵便番号: 任意の5桁の数字

### 5.2 Webhookのテスト

1. [Stripe CLIをインストール](https://stripe.com/docs/stripe-cli)
2. ローカル環境でWebhookをリッスン

   ```bash
   stripe listen --forward-to http://localhost:54321/functions/v1/stripe-webhook
   ```

3. イベントをトリガー

   ```bash
   stripe trigger checkout.session.completed
   ```

## 6. 注意点

1. 本番環境では、必ずStripeの本番環境用APIキーを使用してください。
2. Webhookシークレットは厳重に管理し、公開しないでください。
3. 決済に関するエラーは適切に処理し、ユーザーにフィードバックを提供してください。
4. サブスクリプションの更新日やキャンセルポリシーをユーザーに明示してください。

## 7. 参考リンク

- [Stripe API Documentation](https://stripe.com/docs/api)
- [Flutter Stripe Package](https://pub.dev/packages/flutter_stripe)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
