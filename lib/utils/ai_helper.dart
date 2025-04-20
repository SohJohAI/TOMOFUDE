import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// AIアシスト機能のヘルパークラス
/// AIレスポンスの表示とエラーハンドリングを共通化する
class AIHelper {
  /// AIレスポンスをダイアログで表示する
  /// 空レスポンスの場合は代替テキストを表示
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
  /// エラーの種類に応じて適切なメッセージを表示
  static void showAIError(BuildContext context, dynamic error) {
    String errorMessage = 'AIアシストの取得に失敗しました。';
    String detailMessage = '';

    // エラーの種類に応じてメッセージを変更
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('429') ||
        errorString.contains('too many requests')) {
      errorMessage = 'APIの無料利用上限を超えた可能性があります。';
      detailMessage = '明日以降に再試行するか、有料プランをご検討ください。';
    } else if (errorString.contains('timeout') ||
        errorString.contains('timed out')) {
      errorMessage = 'リクエストがタイムアウトしました。';
      detailMessage = 'ネットワーク接続を確認して、再度お試しください。';
    } else {
      detailMessage = 'エラー詳細: $error';
    }

    // エラーダイアログを表示
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('AIアシストに失敗しました'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(errorMessage),
            SizedBox(height: 8),
            Text(detailMessage),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('閉じる'),
          ),
        ],
      ),
    );
  }
}
