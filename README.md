# TOMOFUDE - AI小説執筆アプリ

「共筆。」（TOMOFUDE）は、AIを活用した小説執筆支援アプリです。

## ポイント決済システム

このアプリには、ポイント決済システムが実装されています。ユーザーはポイントを使用して、AIによる小説執筆支援やプロットブースターの高度な機能などを利用できます。

### 主な機能

- **ポイント管理**: 無料ポイントと有料ポイントの管理
- **紹介コード**: 友達紹介プログラムによるポイント獲得
- **ポイント履歴**: ポイントの獲得・消費履歴の表示
- **月次リセット**: 無料ポイントの月次リセット機能

### 技術スタック

- **フロントエンド**: Flutter
- **バックエンド**: Firebase
  - Firebase Authentication: ユーザー認証
  - Cloud Firestore: データベース
  - Cloud Functions: サーバーサイドロジック

### ディレクトリ構造

```
lib/
  ├── models/
  │   ├── user_point.dart        # ユーザーポイントモデル
  │   ├── point_history.dart     # ポイント履歴モデル
  │   └── referral_code.dart     # 紹介コードモデル
  ├── providers/
  │   └── payment_provider.dart  # ポイント関連の状態管理
  ├── screens/
  │   ├── payment_screen.dart    # ポイント画面
  │   ├── point_history_screen.dart  # ポイント履歴画面
  │   └── referral_code_screen.dart  # 紹介コード入力画面
  ├── services/
  │   ├── auth_service.dart      # 認証サービス
  │   └── point_service.dart     # ポイントサービス
  └── widgets/
      └── point_display_widget.dart  # ポイント表示ウィジェット

functions/
  ├── index.js                   # Cloud Functions
  └── utils.js                   # ユーティリティ関数
```

### ポイントシステムの仕組み

1. **ポイントの種類**:
   - 無料ポイント: 毎月リセットされる無料ポイント
   - 有料ポイント: 購入したポイント（有効期限なし）

2. **ポイントの獲得方法**:
   - 新規登録ボーナス: 1000ポイント
   - 紹介コード使用: 500ポイント
   - 友達を紹介: 1500ポイント

3. **ポイントの消費**:
   - AIによる小説執筆支援
   - プロットブースターの高度な機能
   - 感情分析ツール
   - その他の有料機能

4. **ポイントの有効期限**:
   - 無料ポイント: 毎月1日にリセット
   - 有料ポイント: 無期限
   - ボーナスポイント: 獲得から3ヶ月

### Firebase設定

Firebase Consoleでプロジェクトを作成し、以下の設定を行ってください：

1. **Authentication**: メール/パスワード認証とGoogleログインを有効化
2. **Firestore**: データベースを作成し、セキュリティルールを設定
3. **Cloud Functions**: デプロイして、サーバーサイドロジックを実装

### セットアップ手順

1. Firebase CLIをインストール:
   ```
   npm install -g firebase-tools
   ```

2. Firebaseにログイン:
   ```
   firebase login
   ```

3. プロジェクトを初期化:
   ```
   firebase init
   ```

4. Cloud Functionsをデプロイ:
   ```
   firebase deploy --only functions
   ```

5. FlutterFireを設定:
   ```
   flutterfire configure
   ```

### 注意事項

- 実際の決済機能を実装する場合は、Apple App StoreやGoogle Play Storeの規約に従ってください。
- ポイントの購入機能を実装する場合は、In-App Purchaseを使用してください。
- 本番環境では、Firebase Authenticationの認証方法を適切に設定してください。
