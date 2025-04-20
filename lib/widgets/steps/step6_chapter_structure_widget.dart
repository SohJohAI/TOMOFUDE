import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../models/plot_booster.dart';

/// STEP 6: 章構成
class Step6ChapterStructureWidget extends StatefulWidget {
  @override
  _Step6ChapterStructureWidgetState createState() =>
      _Step6ChapterStructureWidgetState();
}

class _Step6ChapterStructureWidgetState
    extends State<Step6ChapterStructureWidget> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;
  int _editingIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  void _addChapter() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isNotEmpty) {
      final chapter = ChapterOutline(
        title: title,
        content: content,
      );

      if (_editingIndex >= 0) {
        Provider.of<PlotBoosterProvider>(context, listen: false)
            .updateChapterOutline(_editingIndex, chapter);
      } else {
        Provider.of<PlotBoosterProvider>(context, listen: false)
            .addChapterOutline(chapter);
      }

      _titleController.clear();
      _contentController.clear();
      setState(() {
        _editingIndex = -1;
      });
    }
  }

  void _editChapter(int index, ChapterOutline chapter) {
    setState(() {
      _editingIndex = index;
      _titleController.text = chapter.title;
      _contentController.text = chapter.content;
    });
  }

  void _removeChapter(int index) {
    Provider.of<PlotBoosterProvider>(context, listen: false)
        .removeChapterOutline(index);
  }

  void _reorderChapters(int oldIndex, int newIndex) {
    Provider.of<PlotBoosterProvider>(context, listen: false)
        .reorderChapterOutlines(oldIndex, newIndex);
  }

  void _requestAIHelp() async {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    if (!provider.isAIAssistEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // モックレスポンス
      final aiResponse = '''
## 章構成のアイデア

### 3幕構成の例
1. **第1章: 日常の崩壊** - 主人公の平穏な日常が、突然の出来事によって崩れ去る。主人公は問題に直面し、行動を余儀なくされる。
2. **第2章: 試練の連続** - 主人公は問題解決のために行動するが、次々と障害に直面する。敵対者との初めての対決で敗北する。
3. **第3章: 内なる変化** - 敗北から学び、主人公は自分自身と向き合い、弱点を克服する方法を見つける。
4. **第4章: 再挑戦と勝利** - 成長した主人公が再び敵対者と対決し、最終的な勝利を収める。
5. **第5章: 新たな日常** - 冒険を経て変化した主人公が、新しい日常を迎える。

### 英雄の旅の例
1. **第1章: 平凡な世界** - 主人公の日常世界と、その中での不満や欠落を描く。
2. **第2章: 冒険への誘い** - 主人公が冒険へと誘われるが、最初は拒絶する。
3. **第3章: 冒険の世界へ** - 何らかのきっかけで主人公は冒険の世界に足を踏み入れる。
4. **第4章: 試練と仲間** - 様々な試練に直面し、仲間や導き手と出会う。
5. **第5章: 最大の試練** - 主人公が最大の敵と対決し、死と再生を経験する。
6. **第6章: 帰還** - 変化した主人公が元の世界に戻り、その世界に変化をもたらす。
      ''';

      // AIレスポンスをダイアログで表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('AIアシスト'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Markdown(
                data: aiResponse,
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AIアシストの取得に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);
    final chapters = provider.plotBooster.chapterOutlines;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 6：章構成',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            '物語の章構成を設定します。各章のタイトルと内容を入力してください。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // 章入力フォーム
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingIndex >= 0 ? '章を編集' : '章を追加',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '章タイトル',
                      hintText: '例：第1章「出会い」',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: '章の内容',
                      hintText: '例：主人公が謎の少女と出会い、彼女が持つ不思議な能力に驚く。',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_editingIndex >= 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editingIndex = -1;
                              _titleController.clear();
                              _contentController.clear();
                            });
                          },
                          child: Text('キャンセル'),
                        ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addChapter,
                        child: Text(_editingIndex >= 0 ? '更新' : '追加'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 追加された章のリスト
          if (chapters.isNotEmpty) ...[
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '章構成',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '※ドラッグ&ドロップで順序変更可能',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: chapters.length,
              onReorder: _reorderChapters,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return Card(
                  key: ValueKey(index),
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(chapter.title),
                    subtitle: Text(
                      chapter.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editChapter(index, chapter),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeChapter(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

          // AIアシスト
          SizedBox(height: 24),
          if (provider.isAIAssistEnabled) ...[
            ElevatedButton.icon(
              icon: Icon(Icons.lightbulb_outline),
              label: Text('AIに助けを求める'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
              ),
              onPressed: _isLoading ? null : _requestAIHelp,
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
