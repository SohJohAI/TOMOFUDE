import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/service_locator.dart';
import '../services/supabase_service.dart';
import '../services/supabase_service_interface.dart';
import 'claude_ai_streaming_complete_example.dart';

/// A simple entry point to run the Claude AI Streaming example
///
/// This file can be run directly to test the streaming functionality
/// without modifying the main app.
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://awbrfvdyokwkpwrqmfwd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF3YnJmdmR5b2t3a3B3cnFtZndkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3MTcwODQsImV4cCI6MjA2MDI5MzA4NH0.e57mIz0nhuZpm-scH6k60w4ugzMNinaSthQTaeTZ2SQ',
  );

  // テスト用セッションの注入
  await injectTestSession();

  // Initialize service locator
  setupServices();

  // Run the app
  runApp(const ClaudeAIStreamingExampleApp());
}

/// テスト用のセッションを注入する
///
/// このメソッドは、テスト目的でSupabaseに認証済みセッションを作成します。
/// 実際のアプリケーションでは、ユーザーは通常のログインフローを経由します。
Future<void> injectTestSession() async {
  try {
    // テスト用のメールアドレスとパスワードでログイン
    // 注意: これは開発/テスト環境専用です
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: 'yuhki0oe@gmail.com',
      password: 'seel20031219',
    );

    print('テストユーザーでログイン成功: ${response.user?.email ?? "不明"}');
    print('セッション: ${response.session != null ? "有効" : "無効"}');

    // セッションの有効期限を確認
    if (response.session != null) {
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          response.session!.expiresAt! * 1000);
      print('セッション有効期限: $expiresAt');
    }
  } catch (e) {
    print('テストユーザーログインエラー: $e');
    print('エラーが発生しましたが、アプリの実行を継続します');

    // 代替手段: 匿名ログイン
    try {
      final response = await Supabase.instance.client.auth.signInAnonymously();
      print('匿名ログイン成功: ${response.session != null ? "セッション有効" : "セッション無効"}');
    } catch (e) {
      print('匿名ログインも失敗: $e');
    }
  }

  // 現在のセッション状態を確認
  final session = Supabase.instance.client.auth.currentSession;
  print('認証状態: ${session != null ? "認証済み" : "未認証"}');

  // セッションが無い場合は、セッションの更新を試みる
  if (session == null) {
    try {
      print('セッションの更新を試みます...');
      await Supabase.instance.client.auth.refreshSession();
      final refreshedSession = Supabase.instance.client.auth.currentSession;
      print('セッション更新後の状態: ${refreshedSession != null ? "認証済み" : "未認証"}');
    } catch (e) {
      print('セッション更新エラー: $e');
    }
  }
}

/// Setup the service locator with required services
void setupServices() {
  // Register Supabase service
  serviceLocator.registerSingleton<SupabaseServiceInterface>(
    SupabaseService(),
  );
}
