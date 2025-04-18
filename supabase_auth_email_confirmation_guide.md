# Supabase認証のメール確認対応ガイド

このガイドでは、Supabaseの認証機能でメール確認（Email Confirmation）が有効になっている場合の対応方法について説明します。

## 問題の概要

Supabaseの認証設定で「Email Confirmations」が有効になっている場合、ユーザーがサインアップした直後は`auth.currentUser`が`null`になります。これは、ユーザーがメールで確認するまで完全に認証されていないためです。

この状態で以下のようなコードを実行すると、Null check operator used on a null valueエラーが発生します：

```dart
final userId = Supabase.instance.client.auth.currentUser!.id; // エラー発生！
```

## 解決策

### 1. 開発環境でのメール確認無効化

開発中は迅速なテストのために、Supabaseダッシュボードでメール確認を無効化することができます：

1. Supabaseダッシュボードにログイン
2. 左メニューから「Auth → Settings」を開く
3. 「Email Confirmations」の項目のチェックを外す
4. 変更を保存

これにより、開発中は`auth.currentUser`がサインアップ直後から利用可能になります。

### 2. コードの安全化

本番環境ではメール確認を有効にすることが望ましいため、コードを安全に修正する必要があります：

#### 2.1 サインアップ処理の修正

`SupabaseAuthService`の`signUpWithEmail`メソッドを修正しました：

```dart
Future<UserCredential?> signUpWithEmail(String email, String password) async {
  return errorHandler.handleAsync<UserCredential?>(
    () async {
      final response = await _supabaseService.signUpWithEmailAndPassword(
        email,
        password,
      );

      final user = response.user;
      if (user == null) {
        // ユーザーがnullの場合はメール確認待ちの可能性がある
        print('ユーザー登録済みだがメール確認待ち状態。');
        // ここでUIに案内を表示する処理を追加できる
      } else {
        // ユーザーが取得できた場合のみデータを登録
        try {
          // response.userから直接IDを取得して使用
          await _supabaseService.client.from('users').insert({
            'id': user.id,
            'email': email,
            'plan': 'free',
            'points': 300,
          });
        } catch (e) {
          print('Error creating user record: $e');
        }
      }

      return UserCredential.fromAuthResponse(response);
    },
    'SupabaseAuthService.signUpWithEmail',
    'アカウント登録中にエラーが発生しました',
  );
}
```

#### 2.2 UI側の対応

`AuthScreen`の`_signUp`メソッドを修正して、メール確認が必要な場合にユーザーに適切なメッセージを表示するようにしました：

```dart
Future<void> _signUp() async {
  // ...省略...

  try {
    final result = await _authService.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (result != null) {
      if (result.user == null) {
        // ユーザーがnullの場合はメール確認が必要
        _showMessage('登録が完了しました。確認メールをご確認ください。');
      } else {
        // Successfully signed up and user is available
        _showMessage('登録が完了しました: ${result.user?.email}');
      }
    } else {
      // Sign up failed
      setState(() {
        _errorMessage = '登録に失敗しました';
      });
    }
  } catch (e) {
    // ...省略...
  }
}
```

### 3. 一般的なnullセーフティのベストプラクティス

1. **非nullアサーション演算子（`!`）の使用を避ける**：
   - `currentUser!.id`のような書き方は避け、`currentUser?.id ?? ''`のようにnull安全な書き方を使用する

2. **早期リターン**：
   - nullチェックを行い、nullの場合は早期にリターンする

   ```dart
   final user = Supabase.instance.client.auth.currentUser;
   if (user == null) {
     // エラーハンドリングまたは早期リターン
     return;
   }
   
   // ここからは user が non-null であることが保証されている
   final userId = user.id;
   ```

3. **オプショナルチェイニング**：
   - `?.`演算子を使用して、nullの場合は安全に処理する

   ```dart
   final email = Supabase.instance.client.auth.currentUser?.email ?? '未設定';
   ```

## 本番環境での対応

本番環境ではメール確認を有効にすることが推奨されます。その場合は以下の点に注意してください：

1. **ユーザーへの明確なガイダンス**：
   - メール確認が必要な場合、ユーザーに明確なメッセージを表示する
   - 「確認メールを送信しました。メールを確認してログインしてください」などのガイダンスを提供する

2. **メール確認後の処理**：
   - メール確認後にユーザーがログインした際に、必要なデータベースレコードを作成する処理を追加する

3. **環境による設定の切り替え**：
   - 開発環境と本番環境で設定を切り替えられるよう`.env`ファイルや環境変数を使用する
   - 例：`const bool EMAIL_CONFIRMATION_REQUIRED = kReleaseMode;`

## まとめ

Supabaseの認証機能を使用する際は、メール確認の有無によって`currentUser`の挙動が変わることを理解し、適切にnullチェックを行うことが重要です。開発中はメール確認を無効化して効率的に開発を進め、本番環境では適切なエラーハンドリングとユーザーガイダンスを提供することで、安全で使いやすい認証フローを実現できます。
