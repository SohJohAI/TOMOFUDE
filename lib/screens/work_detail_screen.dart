import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/work.dart';
import '../models/chapter.dart';
import '../providers/work_list_provider.dart';
import '../services/export_service.dart';
import 'chapter_editor_screen.dart';

class WorkDetailScreen extends StatefulWidget {
  final Work work;

  const WorkDetailScreen({Key? key, required this.work}) : super(key: key);

  @override
  State<WorkDetailScreen> createState() => _WorkDetailScreenState();
}

class _WorkDetailScreenState extends State<WorkDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.work.title);
    _authorController = TextEditingController(text: widget.work.author);
    _descriptionController =
        TextEditingController(text: widget.work.description);

    _titleController.addListener(_updateWork);
    _authorController.addListener(_updateWork);
    _descriptionController.addListener(_updateWork);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateWork);
    _authorController.removeListener(_updateWork);
    _descriptionController.removeListener(_updateWork);

    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateWork() {
    final workListProvider =
        Provider.of<WorkListProvider>(context, listen: false);

    // 内容を更新
    widget.work.title = _titleController.text;
    widget.work.author = _authorController.text;
    widget.work.description = _descriptionController.text;
    widget.work.updatedAt = DateTime.now();

    // プロバイダーを通して更新
    workListProvider.updateWork(widget.work);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final chapters = widget.work.chapters;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('作品詳細'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.folder),
              onPressed: () => _showFolderMenu(context),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.cloud_download),
              onPressed: () => _showExportMenu(context),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // 作品情報入力部分
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // タイトル入力
                  const Text('タイトル',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: _titleController,
                    placeholder: '作品のタイトルを入力',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 著者入力
                  const Text('著者',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: _authorController,
                    placeholder: '著者名を入力',
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 説明入力
                  const Text('説明',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  CupertinoTextField(
                    controller: _descriptionController,
                    placeholder: '作品の説明を入力',
                    padding: const EdgeInsets.all(12),
                    maxLines: 3,
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),

            // 統計情報
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2C2C2E)
                      : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      icon: CupertinoIcons.book,
                      label: '章数',
                      value: widget.work.getChapterCount().toString(),
                    ),
                    _buildStatItem(
                      icon: CupertinoIcons.text_alignleft,
                      label: '総文字数',
                      value: widget.work.getTotalWordCount().toString(),
                    ),
                    _buildStatItem(
                      icon: CupertinoIcons.time,
                      label: '更新日',
                      value:
                          '${widget.work.updatedAt.month}/${widget.work.updatedAt.day}',
                    ),
                  ],
                ),
              ),
            ),

            // 章一覧のヘッダー
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '章一覧',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.add),
                        const SizedBox(width: 4),
                        Text(
                          '新規章を追加',
                          style: TextStyle(
                            color: CupertinoTheme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    onPressed: () => _createNewChapter(context),
                  ),
                ],
              ),
            ),

            // 章一覧
            Expanded(
              child: chapters.isEmpty
                  ? _buildEmptyChapterList()
                  : _buildChapterList(chapters),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: CupertinoColors.activeBlue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyChapterList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          const Text(
            '章がありません',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text('「新規章を追加」ボタンから章を作成してください'),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            child: const Text('新規章を追加'),
            onPressed: () => _createNewChapter(context),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterList(List<Chapter> chapters) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return ReorderableListView.builder(
      itemCount: chapters.length,
      onReorder: (oldIndex, newIndex) {
        final provider = Provider.of<WorkListProvider>(context, listen: false);
        provider.reorderChapters(widget.work.id, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final chapter = chapters[index];
        return Container(
          key: Key(chapter.id),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? CupertinoColors.systemGrey.darkColor
                  : CupertinoColors.systemGrey4,
            ),
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _openChapter(context, chapter),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // 章番号
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 章情報
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title.isEmpty ? '無題の章' : chapter.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${chapter.wordCount}文字',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? CupertinoColors.systemGrey
                                : CupertinoColors.systemGrey2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 操作ボタン
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.delete,
                      color: CupertinoColors.destructiveRed,
                    ),
                    onPressed: () => _confirmDeleteChapter(context, chapter),
                  ),
                  const Icon(CupertinoIcons.chevron_right),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _createNewChapter(BuildContext context) {
    final provider = Provider.of<WorkListProvider>(context, listen: false);
    final newChapter = Chapter(
      title: '',
      content: '',
    );

    provider.addChapter(widget.work.id, newChapter);
    _openChapter(context, newChapter);
  }

  void _openChapter(BuildContext context, Chapter chapter) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ChapterEditorScreen(
          workId: widget.work.id,
          chapter: chapter,
        ),
      ),
    );
  }

  void _confirmDeleteChapter(BuildContext context, Chapter chapter) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('章の削除'),
        content: Text(
          '「${chapter.title.isEmpty ? "無題の章" : chapter.title}」を削除してもよろしいですか？\nこの操作は元に戻せません。',
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
              ).removeChapter(widget.work.id, chapter.id);
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  void _showExportMenu(BuildContext context) {
    final exportService = ExportService();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('エクスポートオプション'),
        message: const Text('作品をエクスポートする形式を選択してください'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              exportService.exportWorkAsText(widget.work);
              _showExportSuccessAlert('テキストファイルをエクスポートしました');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_text,
                    color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('テキストファイル (.txt)'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              exportService.exportWorkAsHtml(widget.work);
              _showExportSuccessAlert('HTMLファイルをエクスポートしました');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_richtext,
                    color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('HTMLファイル (.html)'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              exportService.exportWorkAsJson(widget.work);
              _showExportSuccessAlert('JSONファイルをエクスポートしました');
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_doc,
                    color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('JSONファイル (.json)'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  void _showExportSuccessAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('エクスポート完了'),
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

  void _showFolderMenu(BuildContext context) {
    final workListProvider =
        Provider.of<WorkListProvider>(context, listen: false);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('フォルダ操作'),
        message: const Text('作品のフォルダ操作を選択してください'),
        actions: [
          // フォルダにエクスポート
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final folderPath =
                    await workListProvider.saveWorkToFolder(widget.work.id);
                _showFolderOperationSuccessAlert(
                  '作品をフォルダにエクスポートしました',
                  '保存先: $folderPath',
                );
              } catch (e) {
                _showFolderOperationErrorAlert(
                    'フォルダへのエクスポートに失敗しました', e.toString());
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder_badge_plus,
                    color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('フォルダにエクスポート'),
              ],
            ),
          ),

          // 保存先を指定してエクスポート
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final customPath =
                    await workListProvider.fileSystemService.pickSaveFolder();
                if (customPath != null) {
                  final folderPath = await workListProvider.saveWorkToFolder(
                    widget.work.id,
                    customPath: customPath,
                  );
                  _showFolderOperationSuccessAlert(
                    '作品をフォルダにエクスポートしました',
                    '保存先: $folderPath',
                  );
                }
              } catch (e) {
                _showFolderOperationErrorAlert(
                    'フォルダへのエクスポートに失敗しました', e.toString());
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.folder_open,
                    color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('保存先を指定してエクスポート'),
              ],
            ),
          ),

          // GitHubにエクスポート
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final result =
                    await workListProvider.exportWorkToGitHub(widget.work.id);
                _showFolderOperationSuccessAlert('GitHub連携', result);
              } catch (e) {
                _showFolderOperationErrorAlert(
                    'GitHubエクスポートに失敗しました', e.toString());
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.cloud_upload,
                    color: CupertinoColors.activeBlue),
                const SizedBox(width: 10),
                const Text('GitHubにエクスポート'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ),
    );
  }

  void _showFolderOperationSuccessAlert(String title, String message) {
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

  void _showFolderOperationErrorAlert(String title, String errorMessage) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(errorMessage),
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
