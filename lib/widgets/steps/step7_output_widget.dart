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
  const Step7OutputWidget({super.key});

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
        const SnackBar(content: Text('クリップボードにコピーしました')),
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
      // 実際のAIサービスを使用する場合は、以下のようにPlotBoosterServiceを呼び出す
      // final aiResponse = await _service.generateSupportMaterial(provider.plotBooster);

      // モックレスポンス - 実際の実装ではClaudeのプロンプトを使用
      final aiResponse = '''
# 執筆支援資料

## 1. 作品概要
- **ジャンル**: ${provider.plotBooster.genre}
- **テーマ**: ${provider.plotBooster.themes.isNotEmpty ? provider.plotBooster.themes.join(', ') : '未設定'}
- **全体的な雰囲気**: ${provider.plotBooster.style}
- **主要な筋書き**: ${provider.plotBooster.logline}

## 2. 登場人物
### 主人公: ${provider.plotBooster.protagonist.name}
- **人物像**: ${provider.plotBooster.protagonist.description}
- **動機**: ${provider.plotBooster.protagonist.motivation}
- **内的葛藤**: ${provider.plotBooster.protagonist.conflict}

### 敵対者/障害: ${provider.plotBooster.antagonist.name}
- **人物像**: ${provider.plotBooster.antagonist.description}
- **動機**: ${provider.plotBooster.antagonist.motivation}
- **主人公との対立点**: ${provider.plotBooster.antagonist.conflict}

## 3. 世界設定
${provider.plotBooster.worldSetting}

## 4. 物語構造
- **現在までのプロット展開**: 物語は導入部から始まり、主人公の日常と内的葛藤が描かれる
- **重要な出来事**: 主人公が冒険に踏み出す決断、最初の障害との遭遇
- **物語のペース**: 序盤はゆっくりと世界観を描写し、中盤から徐々にテンポを上げる

## 5. 文体と語り口
- **視点**: 主人公視点の三人称限定視点が適している
- **時制**: 過去形での語りが基本
- **特徴**: 内面描写と情景描写のバランスを取り、読者が世界に没入できるよう工夫する

## 6. 重要な伏線と未解決の謎
- 主人公の過去に関する謎
- 敵対者の真の目的
- キー設定の隠された力や制限

## 7. 今後の展開に向けた注意点
- キャラクターの動機に一貫性を持たせる
- 世界観の法則性を守る
- 伏線の回収を計画的に行う
- テーマを各章で異なる角度から探求する
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 7：出力',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'プロットの概要をマークダウン形式で出力します。コピーボタンでクリップボードにコピーできます。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // アクションボタン
          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('クリップボードにコピー'),
                onPressed: _copyToClipboard,
              ),
              const SizedBox(width: 16),
              if (provider.isAIAssistEnabled) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('執筆支援資料を生成'),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),

          // プロットカード
          const SizedBox(height: 24),
          const Text(
            'プロットカード',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          PlotCardWidget(plotBooster: provider.plotBooster),

          // マークダウンプレビュー
          const SizedBox(height: 24),
          const Text(
            'マークダウンプレビュー',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            height: 400,
            child: Markdown(
              data: _markdownOutput,
              padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 8),
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
            const SizedBox(height: 16),

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
              const SizedBox(height: 16),
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
              const SizedBox(height: 4),
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
              const SizedBox(height: 16),
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
                        const SizedBox(height: 4),
                        Text(
                          plotBooster.protagonist.name,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(width: 16),

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
                        const SizedBox(height: 4),
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
