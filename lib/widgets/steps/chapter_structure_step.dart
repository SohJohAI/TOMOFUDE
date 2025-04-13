import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../models/plot_booster.dart';

class ChapterStructureStep extends StatefulWidget {
  @override
  _ChapterStructureStepState createState() => _ChapterStructureStepState();
}

class _ChapterStructureStepState extends State<ChapterStructureStep> {
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadChapterSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        final suggestions = await _service.suggestChapterOutlines(
          provider.plotBooster.logline,
          provider.plotBooster.protagonist,
          provider.plotBooster.antagonist,
        );

        // 既存の章構成をクリアして提案を追加
        provider.plotBooster.chapterOutlines.clear();
        for (var outline in suggestions) {
          provider.addChapterOutline(outline);
        }

        setState(() {});
      }
    } catch (e) {
      print('提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addNewChapter() {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final chapterNumber = provider.plotBooster.chapterOutlines.length + 1;

    provider.addChapterOutline(
      ChapterOutline(
        title: '第${chapterNumber}章',
        content: '',
      ),
    );

    setState(() {});
  }

  void _updateChapter(int index, String title, String content) {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    provider.updateChapterOutline(
      index,
      ChapterOutline(
        title: title,
        content: content,
      ),
    );
  }

  void _removeChapter(int index) {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    provider.removeChapterOutline(index);
    setState(() {});
  }

  void _reorderChapters(int oldIndex, int newIndex) {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    provider.reorderChapterOutlines(oldIndex, newIndex);
    setState(() {});
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
            '章構成を生成しましょう',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            '物語の流れを章ごとに設計します。章のタイトルと内容を入力してください。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // 章の追加ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('新しい章を追加'),
                onPressed: _addNewChapter,
              ),
              if (provider.isAIAssistEnabled)
                ElevatedButton.icon(
                  icon: Icon(Icons.auto_awesome),
                  label: Text('章構成を提案してもらう'),
                  onPressed: _isLoading ? null : _loadChapterSuggestions,
                ),
            ],
          ),

          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),

          SizedBox(height: 16),

          // 章リスト
          if (chapters.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '章がまだありません。「新しい章を追加」ボタンをクリックするか、「章構成を提案してもらう」を試してください。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: chapters.length,
              onReorder: _reorderChapters,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return _buildChapterCard(index, chapter);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChapterCard(int index, ChapterOutline chapter) {
    final titleController = TextEditingController(text: chapter.title);
    final contentController = TextEditingController(text: chapter.content);

    // コントローラーの変更を監視
    titleController.addListener(() {
      _updateChapter(index, titleController.text, contentController.text);
    });

    contentController.addListener(() {
      _updateChapter(index, titleController.text, contentController.text);
    });

    return Card(
      key: ValueKey('chapter_$index'),
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.drag_handle),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: '章タイトル',
                      hintText: '例: 第1章: 始まりの予兆',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _removeChapter(index),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                labelText: '章の内容',
                hintText: '例: 主人公の日常と、不思議な出来事との遭遇。',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
