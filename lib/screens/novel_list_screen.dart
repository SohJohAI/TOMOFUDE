import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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

    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('共筆。', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              '（TOMOFUDE）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
            SizedBox(width: 8),
            Text(
              '小説一覧',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // FAQボタン
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.question_circle),
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const FAQScreen()),
                );
              },
            ),
            // テーマ切り替えボタン
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                Provider.of<NovelAppState>(context).isDarkMode
                    ? CupertinoIcons.sun_max
                    : CupertinoIcons.moon,
              ),
              onPressed:
                  () =>
                      Provider.of<NovelAppState>(
                        context,
                        listen: false,
                      ).toggleTheme(),
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          // メインコンテンツ
          novels.isEmpty
              ? _buildEmptyState(context)
              : _buildNovelList(context, novels),

          // 新規作成ボタン（FloatingActionButtonの代わり）
          Positioned(
            right: 16,
            bottom: 16,
            child: CupertinoButton(
              padding: const EdgeInsets.all(16),
              color: CupertinoTheme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(30),
              child: const Icon(
                CupertinoIcons.add,
                color: CupertinoColors.white,
              ),
              onPressed: () => _createNewNovel(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.book,
            size: 80,
            color:
                isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          Text(
            '小説がありません',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('右下のボタンから新しい小説を作成してください'),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.add, color: CupertinoColors.white),
                SizedBox(width: 8),
                Text('新しい小説を作成'),
              ],
            ),
            onPressed: () => _createNewNovel(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNovelList(BuildContext context, List<Novel> novels) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: novels.length,
      itemBuilder: (context, index) {
        final novel = novels[index];
        final updatedAt = novel.updatedAt;
        final formattedDate =
            '${updatedAt.year}/${updatedAt.month}/${updatedAt.day} ${updatedAt.hour}:${updatedAt.minute}';

        // テキストの先頭部分を抜粋（概要として表示）
        final excerpt =
            novel.content.length > 100
                ? '${novel.content.substring(0, 100)}...'
                : novel.content;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isDark
                      ? CupertinoColors.systemGrey.darkColor
                      : CupertinoColors.systemGrey4,
              width: 0.5,
            ),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openNovel(context, novel),
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? CupertinoColors.systemGrey
                                  : CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    excerpt.isEmpty ? '内容なし' : excerpt,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Icon(
                          CupertinoIcons.pencil,
                          size: 20,
                          color: CupertinoTheme.of(context).primaryColor,
                        ),
                        onPressed: () => _openNovel(context, novel),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.delete,
                          size: 20,
                          color: CupertinoColors.destructiveRed,
                        ),
                        onPressed: () => _confirmDelete(context, novel),
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
      CupertinoPageRoute(builder: (context) => NovelEditorScreen(novel: novel)),
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
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: const Text('小説の削除'),
            content: Text(
              '「${novel.title.isEmpty ? "無題の小説" : novel.title}」を削除してもよろしいですか？\nこの操作は元に戻せません。',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () {
                  Provider.of<NovelListProvider>(
                    context,
                    listen: false,
                  ).removeNovel(novel.id);
                  Navigator.pop(context);
                },
                child: const Text('削除'),
              ),
            ],
          ),
    );
  }
}
