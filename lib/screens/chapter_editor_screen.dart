import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/chapter.dart';
import '../providers/work_list_provider.dart';
import '../widgets/novel_editor.dart';

class ChapterEditorScreen extends StatefulWidget {
  final String workId;
  final Chapter chapter;

  const ChapterEditorScreen({
    Key? key,
    required this.workId,
    required this.chapter,
  }) : super(key: key);

  @override
  State<ChapterEditorScreen> createState() => _ChapterEditorScreenState();
}

class _ChapterEditorScreenState extends State<ChapterEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.chapter.title);
    _contentController = TextEditingController(text: widget.chapter.content);

    _titleController.addListener(_updateChapter);
    _contentController.addListener(_updateChapter);
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateChapter);
    _contentController.removeListener(_updateChapter);

    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateChapter() {
    final workListProvider =
        Provider.of<WorkListProvider>(context, listen: false);

    // 内容を更新
    widget.chapter.title = _titleController.text;
    widget.chapter.content = _contentController.text;
    widget.chapter.updateWordCount();
    widget.chapter.updatedAt = DateTime.now();

    // プロバイダーを通して更新
    workListProvider.updateChapter(widget.workId, widget.chapter);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _titleController,
                placeholder: '章のタイトルを入力',
                decoration: null,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${widget.chapter.wordCount}文字',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.check_mark),
          onPressed: () async {
            _updateChapter();
            Navigator.pop(context);
          },
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: NovelEditor(
            contentController: _contentController,
            onContentChanged: (content) {
              _updateChapter();
            },
          ),
        ),
      ),
    );
  }
}
