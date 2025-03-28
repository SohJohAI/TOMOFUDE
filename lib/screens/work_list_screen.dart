import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../models/work.dart';
import '../providers/work_list_provider.dart';
import 'work_detail_screen.dart';
import 'faq_screen.dart';

class WorkListScreen extends StatelessWidget {
  const WorkListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workListProvider = Provider.of<WorkListProvider>(context);
    final works = workListProvider.works;

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
              '作品一覧',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.book),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                Provider.of<NovelAppState>(context).isDarkMode
                    ? CupertinoIcons.sun_max
                    : CupertinoIcons.moon,
              ),
              onPressed: () => Provider.of<NovelAppState>(
                context,
                listen: false,
              ).toggleTheme(),
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          works.isEmpty
              ? _buildEmptyState(context)
              : _buildWorkList(context, works),
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // フォルダからインポートボタン
                CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  color:
                      CupertinoTheme.of(context).primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(30),
                  child: const Icon(
                    CupertinoIcons.folder_badge_plus,
                    color: CupertinoColors.white,
                  ),
                  onPressed: () => _importWorkFromFolder(context),
                ),
                const SizedBox(height: 8),
                // 新規作品作成ボタン
                CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  color: CupertinoTheme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(30),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                  ),
                  onPressed: () => _createNewWork(context),
                ),
              ],
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
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          const Text(
            '作品がありません',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('右下のボタンから新しい作品を作成してください'),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.add, color: CupertinoColors.white),
                SizedBox(width: 8),
                Text('新しい作品を作成'),
              ],
            ),
            onPressed: () => _createNewWork(context),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkList(BuildContext context, List<Work> works) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: works.length,
      itemBuilder: (context, index) {
        final work = works[index];
        final updatedAt = work.updatedAt;
        final formattedDate =
            '${updatedAt.year}/${updatedAt.month}/${updatedAt.day} ${updatedAt.hour}:${updatedAt.minute}';

        // 最初の章の内容を抜粋（概要として表示）
        final excerpt =
            work.chapters.isNotEmpty && work.chapters[0].content.isNotEmpty
                ? (work.chapters[0].content.length > 100
                    ? '${work.chapters[0].content.substring(0, 100)}...'
                    : work.chapters[0].content)
                : (work.description.isNotEmpty ? work.description : '内容なし');

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey4,
              width: 0.5,
            ),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openWork(context, work),
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
                          work.title.isEmpty ? '無題の作品' : work.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
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
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${work.getChapterCount()}章',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${work.getTotalWordCount()}文字',
                        style: TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    excerpt,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
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
                        onPressed: () => _openWork(context, work),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.delete,
                          size: 20,
                          color: CupertinoColors.destructiveRed,
                        ),
                        onPressed: () => _confirmDelete(context, work),
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

  void _openWork(BuildContext context, Work work) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => WorkDetailScreen(work: work)),
    );
  }

  void _createNewWork(BuildContext context) {
    final provider = Provider.of<WorkListProvider>(context, listen: false);
    final newWork = Work(
      title: '',
      author: '',
      description: '',
    );

    provider.addWork(newWork);
    _openWork(context, newWork);
  }

  void _confirmDelete(BuildContext context, Work work) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('作品の削除'),
        content: Text(
          '「${work.title.isEmpty ? "無題の作品" : work.title}」を削除してもよろしいですか？\nこの操作は元に戻せません。',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Provider.of<WorkListProvider>(
                context,
                listen: false,
              ).removeWork(work.id);
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  /// フォルダから作品をインポート
  void _importWorkFromFolder(BuildContext context) async {
    final workListProvider =
        Provider.of<WorkListProvider>(context, listen: false);

    try {
      final work = await workListProvider.pickAndLoadWorkFolder();

      if (work != null) {
        _showImportSuccessAlert(
          context,
          '作品のインポートが完了しました',
          '「${work.title.isEmpty ? "無題の作品" : work.title}」を正常にインポートしました。',
          () {
            // インポート成功後に作品詳細画面に遷移
            _openWork(context, work);
          },
        );
      }
    } catch (e) {
      _showImportErrorAlert(
        context,
        'インポートエラー',
        'フォルダからの作品インポートに失敗しました: ${e.toString()}',
      );
    }
  }

  /// インポート成功アラート
  void _showImportSuccessAlert(
    BuildContext context,
    String title,
    String message,
    VoidCallback onOk,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              onOk();
            },
          ),
        ],
      ),
    );
  }

  /// インポートエラーアラート
  void _showImportErrorAlert(
    BuildContext context,
    String title,
    String message,
  ) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
