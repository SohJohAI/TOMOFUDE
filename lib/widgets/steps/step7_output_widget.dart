import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../models/plot_booster.dart';
import '../../utils/ai_helper.dart';

/// STEP 7: 出力
class Step7OutputWidget extends StatefulWidget {
  @override
  _Step7OutputWidgetState createState() => _Step7OutputWidgetState();
}

class _Step7OutputWidgetState extends State<Step7OutputWidget> {
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;
  String _markdownOutput = '';

  @override
  void initState() {
    super.initState();
    _generateMarkdown();
  }

  void _generateMarkdown() {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final plotBooster = provider.plotBooster;

    // マークダウン形式で出力を生成
    final buffer = StringBuffer();

    // タイトル
    buffer.writeln('# プロット概要');
    buffer.writeln();

    // ジャンルと作風
    buffer.writeln('## ジャンルと作風');
    buffer.writeln('- **ジャンル**: ${plotBooster.genre}');
    buffer.writeln('- **作風**: ${plotBooster.style}');
    buffer.writeln();

    // ログライン
    buffer.writeln('## ログライン');
    buffer.writeln(plotBooster.logline);
    buffer.writeln();

    // テーマ
    if (plotBooster.themes.isNotEmpty) {
      buffer.writeln('## テーマ・モチーフ');
      for (final theme in plotBooster.themes) {
        buffer.writeln('- $theme');
      }
      buffer.writeln();
    }

    // 世界観
    if (plotBooster.worldSetting.isNotEmpty) {
      buffer.writeln('## 世界観設定');
      buffer.writeln(plotBooster.worldSetting);
      buffer.writeln();
    }

    // キー設定
    if (plotBooster.keySettings.isNotEmpty) {
      buffer.writeln('## キー設定');
      for (final setting in plotBooster.keySettings) {
        buffer.writeln('### ${setting.name}');
        if (setting.effect.isNotEmpty) {
          buffer.writeln('- **効果・役割**: ${setting.effect}');
        }
        if (setting.limitation.isNotEmpty) {
          buffer.writeln('- **制限・代償**: ${setting.limitation}');
        }
        buffer.writeln();
      }
    }

    // キャラクター
    buffer.writeln('## キャラクター');

    // 主人公
    final protagonist = plotBooster.protagonist;
    if (protagonist.name.isNotEmpty) {
      buffer.writeln('### 主人公: ${protagonist.name}');
      if (protagonist.description.isNotEmpty) {
        buffer.writeln('- **人物像・特徴**: ${protagonist.description}');
      }
      if (protagonist.motivation.isNotEmpty) {
        buffer.writeln('- **動機・目標**: ${protagonist.motivation}');
      }
      if (protagonist.conflict.isNotEmpty) {
        buffer.writeln('- **内的葛藤・弱点**: ${protagonist.conflict}');
      }
      buffer.writeln();
    }

    // 敵対者
    final antagonist = plotBooster.antagonist;
    if (antagonist.name.isNotEmpty) {
      buffer.writeln('### 敵対者/障害: ${antagonist.name}');
      if (antagonist.description.isNotEmpty) {
        buffer.writeln('- **人物像・特徴**: ${antagonist.description}');
      }
      if (antagonist.motivation.isNotEmpty) {
        buffer.writeln('- **動機・目標**: ${antagonist.motivation}');
      }
      if (antagonist.conflict.isNotEmpty) {
        buffer.writeln('- **主人公との対立点**: ${antagonist.conflict}');
      }
      buffer.writeln();
    }

    // 章構成
    if (plotBooster.chapterOutlines.isNotEmpty) {
      buffer.writeln('## 章構成');
      for (int i = 0; i < plotBooster.chapterOutlines.length; i++) {
        final chapter = plotBooster.chapterOutlines[i];
        buffer.writeln('### ${chapter.title}');
        buffer.writeln(chapter.content);
        buffer.writeln();
      }
    }

    // AI支援資料
    if (plotBooster.aiSupportMaterial.isNotEmpty) {
      buffer.writeln('## AI支援資料');
      buffer.writeln(plotBooster.aiSupportMaterial);
    }

    setState(() {
      _markdownOutput = buffer.toString();
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _markdownOutput)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('クリップボードにコピーしました')),
      );
    });
  }

  void _generateAISupportMaterial() async {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    if (!provider.isAIAssistEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // モックレスポンス
      final aiResponse = '''
# 執筆支援資料

## 物語の骨格分析
- **構造**: 3幕構成の冒険譚
- **ペース**: 序盤はゆっくりと世界観を描写し、中盤から徐々にテンポを上げる
- **視点**: 主人公視点の三人称限定視点が適している

## 執筆アドバイス
- 主人公の内面描写を丁寧に行い、読者が感情移入しやすくする
- 世界観の独自性を小さなディテールで表現する
- 敵対者の動機を複雑に描くことで、単純な善悪二元論を避ける
- 伏線は物語の前半に自然な形で埋め込み、後半で回収する
- 各章の終わりに小さなクリフハンガーを設けることで、読者の興味を持続させる

## 潜在的な課題と解決策
- **課題**: 設定が複雑すぎて読者が混乱する可能性
  **解決策**: 重要な設定は繰り返し言及し、徐々に深掘りする
- **課題**: キャラクターの動機が不明確
  **解決策**: 過去のトラウマや価値観を具体的なエピソードで示す
- **課題**: 物語のテーマが埋もれる
  **解決策**: 重要な場面でテーマに関連する象徴やメタファーを使用する

## 参考作品
この物語のテーマや構造に類似した作品:
1. 「○○の物語」 - 世界観構築の参考に
2. 「△△」 - キャラクター造形の参考に
3. 「□□」 - 伏線の張り方の参考に
      ''';

      // AI支援資料を更新
      provider.updateAISupportMaterial(aiResponse);

      // マークダウンを再生成
      _generateMarkdown();
    } catch (e) {
      // エラーダイアログを表示
      AIHelper.showAIError(context, e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 7：出力',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'プロットの概要をマークダウン形式で出力します。コピーボタンでクリップボードにコピーできます。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // アクションボタン
          Row(
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.copy),
                label: Text('クリップボードにコピー'),
                onPressed: _copyToClipboard,
              ),
              SizedBox(width: 16),
              if (provider.isAIAssistEnabled) ...[
                ElevatedButton.icon(
                  icon: Icon(Icons.lightbulb_outline),
                  label: Text('執筆支援資料を生成'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: _isLoading ? null : _generateAISupportMaterial,
                ),
              ],
            ],
          ),

          // ローディングインジケーター
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),

          // プロットカード
          SizedBox(height: 24),
          Text(
            'プロットカード',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          PlotCardWidget(plotBooster: provider.plotBooster),

          // マークダウンプレビュー
          SizedBox(height: 24),
          Text(
            'マークダウンプレビュー',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            height: 400,
            child: Markdown(
              data: _markdownOutput,
              padding: EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }
}

/// プロットカードウィジェット
class PlotCardWidget extends StatelessWidget {
  final PlotBooster plotBooster;

  const PlotCardWidget({
    Key? key,
    required this.plotBooster,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final accentColor = isDark ? Colors.amber : Colors.blue;

    return Card(
      elevation: 4,
      color: cardColor,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ジャンルと作風
            Row(
              children: [
                if (plotBooster.genre.isNotEmpty)
                  Chip(
                    label: Text(
                      plotBooster.genre,
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    backgroundColor: accentColor,
                  ),
                SizedBox(width: 8),
                if (plotBooster.style.isNotEmpty)
                  Chip(
                    label: Text(
                      plotBooster.style,
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    backgroundColor: accentColor.withOpacity(0.7),
                  ),
              ],
            ),
            SizedBox(height: 16),

            // ログライン
            if (plotBooster.logline.isNotEmpty) ...[
              Text(
                plotBooster.logline,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 16),
            ],

            // テーマ
            if (plotBooster.themes.isNotEmpty) ...[
              Text(
                'テーマ:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plotBooster.themes.map((theme) {
                  return Chip(
                    label: Text(theme),
                    backgroundColor:
                        isDark ? Colors.grey[700] : Colors.grey[200],
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],

            // キャラクター
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主人公
                if (plotBooster.protagonist.name.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '主人公:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          plotBooster.protagonist.name,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),

                SizedBox(width: 16),

                // 敵対者
                if (plotBooster.antagonist.name.isNotEmpty)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '敵対者/障害:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          plotBooster.antagonist.name,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
