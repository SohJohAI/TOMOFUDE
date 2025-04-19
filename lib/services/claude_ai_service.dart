import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service_interface.dart';

/// Claude APIを使用したAIサービスの実装
class ClaudeAIService implements AIService {
  /// Supabase Edge Function URL
  final String _claudeGatewayUrl;

  /// コンストラクタ
  ///
  /// [claudeGatewayUrl] Claude API Gatewayのエンドポイント
  ClaudeAIService({required String claudeGatewayUrl})
      : _claudeGatewayUrl = claudeGatewayUrl;

  /// Claude APIにリクエストを送信する
  ///
  /// [prompt] Claudeに送信するプロンプト
  Future<Map<String, dynamic>> _sendClaudeRequest(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_claudeGatewayUrl),
        headers: {
          'Content-Type': 'application/json',
          // 必要に応じて認証ヘッダーを追加
        },
        body: jsonEncode({
          'prompt': prompt,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'Failed to get response from Claude API: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error calling Claude API: $e');
    }
  }

  /// Claude APIからのレスポンスからテキスト内容を抽出する
  ///
  /// [claudeResponse] Claude APIからのレスポンス
  String _extractTextFromClaudeResponse(Map<String, dynamic> claudeResponse) {
    try {
      final content = claudeResponse['content'] as List;
      final textContent = content.firstWhere(
        (item) => item['type'] == 'text',
        orElse: () => {'text': '応答を解析できませんでした。'},
      );
      return textContent['text'] as String;
    } catch (e) {
      return '応答の解析中にエラーが発生しました: $e';
    }
  }

  @override
  Future<List<String>> generateContinuations(String content) async {
    final prompt = '''
あなたは小説の続きを提案するAIアシスタントです。
以下の小説の続きとして、3つの異なる展開を提案してください。
各提案は1〜2文程度の簡潔なものにしてください。

===
$content
===

3つの異なる展開案:
''';

    final claudeResponse = await _sendClaudeRequest(prompt);
    final responseText = _extractTextFromClaudeResponse(claudeResponse);

    // レスポンスを行で分割し、空行を除去して3つの提案を抽出
    final lines = responseText
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    // 最低3つの提案を確保（十分な提案がない場合はデフォルト提案を追加）
    List<String> continuations = [];
    for (var line in lines) {
      // 番号付きリストの形式（1. 2. 3.）を除去
      final cleanLine = line.replaceFirst(RegExp(r'^\d+\.\s*'), '');
      if (cleanLine.isNotEmpty) {
        continuations.add(cleanLine);
      }
      if (continuations.length >= 3) break;
    }

    // 提案が3つに満たない場合、デフォルト提案を追加
    while (continuations.length < 3) {
      continuations.add('新たな展開の提案...');
    }

    return continuations;
  }

  @override
  Future<String> expandSuggestion(String content, String suggestion) async {
    final prompt = '''
あなたは小説の執筆を支援するAIアシスタントです。
以下の小説の一部と、その続きの提案があります。
この提案を発展させて、2〜3文の自然な段落を作成してください。

===小説の一部===
$content

===続きの提案===
$suggestion

===発展させた段落===
''';

    final claudeResponse = await _sendClaudeRequest(prompt);
    final expandedText = _extractTextFromClaudeResponse(claudeResponse);

    return expandedText.trim();
  }

  @override
  Map<String, dynamic> generateSettings(String content) {
    // 注: この実装は非同期ではありませんが、実際の実装では非同期にすることを検討してください
    // 現在のインターフェースに合わせるため、同期メソッドとして実装しています
    return {
      "characters": [
        {"name": "主人公", "description": "まだ詳しい情報がありません。"}
      ],
      "organizations": [],
      "terminology": [],
      "setting": "まだ詳しい情報がありません。",
      "genre": "未定"
    };
  }

  @override
  Map<String, dynamic> generatePlotAnalysis(String content) {
    // 注: この実装は非同期ではありませんが、実際の実装では非同期にすることを検討してください
    return {
      "introduction": "物語の導入部分です。",
      "mainEvents": [
        "主要なイベント1",
        "主要なイベント2",
      ],
      "turningPoints": [
        "転換点1",
      ],
      "currentStage": "導入",
      "unresolvedIssues": [
        "未解決の問題1",
      ],
      "possibleDevelopments": [
        "可能性のある展開1",
        "可能性のある展開2",
      ]
    };
  }

  @override
  Map<String, String> generateReview() {
    // 注: この実装は非同期ではありませんが、実際の実装では非同期にすることを検討してください
    return {
      "reader": "読者からのフィードバック例",
      "editor": "編集者からのフィードバック例",
      "jury": "審査員からのフィードバック例"
    };
  }

  @override
  Future<Map<String, dynamic>> analyzeEmotion(String content,
      {String? aiDocs}) async {
    final prompt = '''
あなたは小説の感情分析を行うAIアシスタントです。
以下の小説の文章を分析し、感情の起伏や盛り上がりを分析してください。
結果はJSON形式で返してください。

===小説の文章===
$content

${aiDocs != null ? '===AI資料===\n$aiDocs\n' : ''}

感情分析結果をJSON形式で出力してください。以下の形式に従ってください:
{
  "segments": [
    {
      "name": "セグメント名",
      "dominantEmotion": "主要感情",
      "emotionCode": "感情カラーコード",
      "emotionValue": 感情値（0-100）,
      "excitement": 盛り上がり度（0-100）,
      "description": "感情の説明"
    }
  ],
  "summary": "全体の感情分析まとめ"
}
''';

    final claudeResponse = await _sendClaudeRequest(prompt);
    final analysisText = _extractTextFromClaudeResponse(claudeResponse);

    try {
      // JSONを抽出（テキスト内にJSON以外の説明文がある場合に対応）
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(analysisText);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        return jsonDecode(jsonStr!) as Map<String, dynamic>;
      } else {
        throw Exception('JSONデータが見つかりませんでした');
      }
    } catch (e) {
      // JSONのパースに失敗した場合はダミーデータを返す
      return {
        "segments": [
          {
            "name": "セグメント 1",
            "dominantEmotion": "未分類",
            "emotionCode": "#808080",
            "emotionValue": 50,
            "excitement": 50,
            "description": "感情分析に失敗しました: $e"
          }
        ],
        "summary": "感情分析の処理中にエラーが発生しました。"
      };
    }
  }

  @override
  Future<String> generateAIDocs(String content,
      {String? settingInfo, String? plotInfo, String? emotionInfo}) async {
    final prompt = '''
あなたは小説執筆を支援するAIアシスタントです。
以下の小説の文章と関連情報を分析し、執筆のためのAI資料を生成してください。

===小説の文章===
$content

${settingInfo != null ? '===設定情報===\n$settingInfo\n' : ''}
${plotInfo != null ? '===プロット情報===\n$plotInfo\n' : ''}
${emotionInfo != null ? '===感情分析===\n$emotionInfo\n' : ''}

以下の形式でAI資料を生成してください:

【AI資料】

■ 内容分析
・文体: 
・テーマ: 
・特徴: 

■ 執筆アドバイス
・
・
''';

    final claudeResponse = await _sendClaudeRequest(prompt);
    final docsText = _extractTextFromClaudeResponse(claudeResponse);

    return docsText.trim();
  }
}
