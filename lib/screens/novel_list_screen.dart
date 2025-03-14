import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/novel.dart';
import '../providers/novel_list_provider.dart';
import 'editor_screen.dart';
import 'faq_screen.dart'; // FAQページのインポートを追加

class NovelListScreen extends StatelessWidget {
  const NovelListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final novelListProvider = Provider.of<NovelListProvider>(context);
    final novels = novelListProvider.novels;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('共筆。', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('（TOMOFUDE）',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
            SizedBox(width: 8),
            Text('小説一覧',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal)),
          ],
        ),
        actions: [
          // FAQボタンを追加
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'よくある質問',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Provider.of<NovelAppState>(context).isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => Provider.of<NovelAppState>(context, listen: false)
                .toggleTheme(),
          ),
        ],
      ),
      body: novels.isEmpty
          ? _buildEmptyState(context)
          : _buildNovelList(context, novels),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewNovel(context),
        child: const Icon(Icons.add),
        tooltip: '新しい小説を作成',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '小説がありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text('右下のボタンから新しい小説を作成してください'),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewNovel(context),
            icon: const Icon(Icons.add),
            label: const Text('新しい小説を作成'),
          ),
        ],
      ),
    );
  }

  Widget _buildNovelList(BuildContext context, List<Novel> novels) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];
        final updatedAt = novel.updatedAt;
        final formattedDate =
            '${updatedAt.year}/${updatedAt.month}/${updatedAt.day} ${updatedAt.hour}:${updatedAt.minute}';

        // テキストの先頭部分を抜粋（概要として表示）
        final excerpt = novel.content.length > 100
            ? '${novel.content.substring(0, 100)}...'
            : novel.content;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _openNovel(context, novel),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          novel.title.isEmpty ? '無題の小説' : novel.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    excerpt.isEmpty ? '内容なし' : excerpt,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _openNovel(context, novel),
                        tooltip: '編集',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () => _confirmDelete(context, novel),
                        tooltip: '削除',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openNovel(BuildContext context, Novel novel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NovelEditorScreen(novel: novel),
      ),
    );
  }

  void _createNewNovel(BuildContext context) {
    final provider = Provider.of<NovelListProvider>(context, listen: false);
    final newNovel = Novel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    provider.addNovel(newNovel);

    _openNovel(context, newNovel);
  }

  void _confirmDelete(BuildContext context, Novel novel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('小説の削除'),
        content: Text(
            '「${novel.title.isEmpty ? "無題の小説" : novel.title}」を削除してもよろしいですか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<NovelListProvider>(context, listen: false)
                  .removeNovel(novel.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
