import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// AIアシスト機能のヘルパークラス
/// AIレスポンスの表示やエラーハンドリングを共通化する
class AIHelper {
  /// AIレスポンスをダイアログで表示する
  ///
  /// [context] ビルドコンテキスト
  /// [aiResponse] AIからのレスポンス
  static void showAIResponse(BuildContext context, String aiResponse) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AIアシスト'),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Markdown(
              data: aiResponse.isNotEmpty
                  ? aiResponse
                  : '⚠️ AIの応答がありませんでした。ネットワークやAPI制限をご確認ください。',
              shrinkWrap: true,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// AIエラーをダイアログで表示する
  ///
  /// [context] ビルドコンテキスト
  /// [e] 発生した例外
  static void showAIError(BuildContext context, dynamic e) {
    String errorMessage = e.toString();
    String userMessage = '⚠️ AIアシストに失敗しました。';

    if (errorMessage.contains('429') ||
        errorMessage.contains('Too Many Requests')) {
      userMessage += '\n\nAPIの無料利用上限を超えた可能性があります。明日以降に再試行するか、有料プランをご検討ください。';
    } else if (errorMessage.contains('timeout') ||
        errorMessage.contains('timed out')) {
      userMessage += '\n\nサーバーの応答がタイムアウトしました。後ほど再試行してください。';
    } else {
      userMessage += '\n\nネットワークやAPI制限をご確認ください。\n\n詳細: $e';
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('AIアシストに失敗しました'),
        content: Text(userMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('閉じる'))
        ],
      ),
    );
  }
}
