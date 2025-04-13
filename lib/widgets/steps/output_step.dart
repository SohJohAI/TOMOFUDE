import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';

class OutputStep extends StatefulWidget {
  @override
  _OutputStepState createState() => _OutputStepState();
}

class _OutputStepState extends State<OutputStep> {
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;
  String _supportMaterial = '';

  @override
  void initState() {
    super.initState();
    _generateSupportMaterial();
  }

  Future<void> _generateSupportMaterial() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        _supportMaterial =
            await _service.generateSupportMaterial(provider.plotBooster);
        provider.updateAISupportMaterial(_supportMaterial);
      } else {
        _supportMaterial = _generateBasicSupportMaterial(provider.plotBooster);
        provider.updateAISupportMaterial(_supportMaterial);
      }
    } catch (e) {
      print('支援資料生成エラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateBasicSupportMaterial(plotBooster) {
    final buffer = StringBuffer();

    buffer.writeln('# 執筆支援資料');
    buffer.writeln();

    // 基本情報
    buffer.writeln('## 物語の核');
    buffer.writeln(
        plotBooster.logline.isNotEmpty ? plotBooster.logline : '（未設定）');
    buffer.writeln();

    // ジャンルと作風
    buffer.writeln('## ジャンルと作風');
    buffer.writeln(
        '- ジャンル: ${plotBooster.genre.isNotEmpty ? plotBooster.genre : '（未設定）'}');
    buffer.writeln(
        '- 作風: ${plotBooster.style.isNotEmpty ? plotBooster.style : '（未設定）'}');
    buffer.writeln();

    // テーマ
    if (plotBooster.themes.isNotEmpty) {
      buffer.writeln('## テーマ');
      for (var theme in plotBooster.themes) {
        buffer.writeln('- $theme');
      }
      buffer.writeln();
    }

    // 世界観
    if (plotBooster.worldSetting.isNotEmpty) {
      buffer.writeln('## 世界観');
      buffer.writeln(plotBooster.worldSetting);
      buffer.writeln();
    }

    // キー設定
    if (plotBooster.keySettings.isNotEmpty) {
      buffer.writeln('## キー設定');
      for (var setting in plotBooster.keySettings) {
        buffer.writeln('### ${setting.name}');
        buffer.writeln('- 効果: ${setting.effect}');
        if (setting.limitation.isNotEmpty) {
          buffer.writeln('- 制約: ${setting.limitation}');
        }
        buffer.writeln();
      }
    }

    // キャラクター
    buffer.writeln('## 主要キャラクター');

    // 主人公
    buffer.writeln(
        '### 主人公: ${plotBooster.protagonist.name.isNotEmpty ? plotBooster.protagonist.name : '（名前未設定）'}');
    if (plotBooster.protagonist.description.isNotEmpty) {
      buffer.writeln(plotBooster.protagonist.description);
    }
    if (plotBooster.protagonist.motivation.isNotEmpty) {
      buffer.writeln('- 動機: ${plotBooster.protagonist.motivation}');
    }
    if (plotBooster.protagonist.conflict.isNotEmpty) {
      buffer.writeln('- 内的葛藤: ${plotBooster.protagonist.conflict}');
    }
    buffer.writeln();

    // 敵対者
    buffer.writeln(
        '### 敵対者: ${plotBooster.antagonist.name.isNotEmpty ? plotBooster.antagonist.name : '（名前未設定）'}');
    if (plotBooster.antagonist.description.isNotEmpty) {
      buffer.writeln(plotBooster.antagonist.description);
    }
    if (plotBooster.antagonist.motivation.isNotEmpty) {
      buffer.writeln('- 動機: ${plotBooster.antagonist.motivation}');
    }
    if (plotBooster.antagonist.conflict.isNotEmpty) {
      buffer.writeln('- 内的葛藤: ${plotBooster.antagonist.conflict}');
    }
    buffer.writeln();

    // 章構成
    if (plotBooster.chapterOutlines.isNotEmpty) {
      buffer.writeln('## 章構成');
      for (var i = 0; i < plotBooster.chapterOutlines.length; i++) {
        final chapter = plotBooster.chapterOutlines[i];
        buffer.writeln('### ${chapter.title}');
        buffer
            .writeln(chapter.content.isNotEmpty ? chapter.content : '（内容未設定）');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  void _copyToClipboard() {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    Clipboard.setData(
        ClipboardData(text: provider.plotBooster.aiSupportMaterial));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('執筆支援資料をクリップボードにコピーしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);
    final supportMaterial = provider.plotBooster.aiSupportMaterial;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'プロットの完成',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'プロットが完成しました。以下の執筆支援資料を参考に、小説を書き始めましょう。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // アクションボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('再生成'),
                onPressed: _isLoading ? null : _generateSupportMaterial,
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.copy),
                label: Text('コピー'),
                onPressed: supportMaterial.isEmpty ? null : _copyToClipboard,
              ),
            ],
          ),
          SizedBox(height: 16),

          // 執筆支援資料
          if (_isLoading)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('執筆支援資料を生成中...'),
                  ],
                ),
              ),
            )
          else if (supportMaterial.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('執筆支援資料がありません。「再生成」ボタンをクリックしてください。'),
              ),
            )
          else
            Card(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                child: Markdown(
                  data: supportMaterial,
                  selectable: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
