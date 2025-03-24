import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/novel_list_provider.dart';
import '../models/novel.dart';
import '../services/export_service.dart';
import '../services/ai_service.dart';
import '../widgets/novel_editor.dart';

enum SettingType { text, character, organization, terminology }

class NovelEditorScreen extends StatefulWidget {
  final Novel novel;

  const NovelEditorScreen({Key? key, required this.novel}) : super(key: key);

  @override
  State<NovelEditorScreen> createState() => _NovelEditorScreenState();
}

class _NovelEditorScreenState extends State<NovelEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isLoading = false;
  final ExportService _exportService = ExportService();
  final DummyAIService _aiService = DummyAIService();
  List<String> _aiSuggestions = [];
  bool _showingSuggestions = false;

  // 設定情報関連
  Map<String, dynamic> _settingsData = {};
  Map<String, dynamic> _plotData = {};
  Map<String, String> _reviewData = {"reader": "", "editor": "", "jury": ""};
  bool _isAnalyzingSettings = false;
  bool _isAnalyzingPlot = false;
  bool _isGeneratingReview = false;
  String _lastAnalyzedContent = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.novel.title);
    _contentController = TextEditingController(text: widget.novel.content);

    _titleController.addListener(_updateNovel);
    _contentController.addListener(_updateNovel);

    // 初期データの生成
    _initializeAnalysisData();
  }

  // 分析データの初期化
  void _initializeAnalysisData() {
    final content = widget.novel.content;
    if (content.length > 100) {
      _generateInitialData();
    }
  }

  // 初期データを生成
  Future<void> _generateInitialData() async {
    setState(() {
      _isAnalyzingSettings = true;
      _isAnalyzingPlot = true;
      _isGeneratingReview = true;
    });

    // 並列で各種データを生成
    await Future.wait([
      Future(() async {
        await Future.delayed(const Duration(milliseconds: 800));
        _settingsData = _aiService.generateSettings(_contentController.text);
        setState(() {
          _isAnalyzingSettings = false;
        });
      }),
      Future(() async {
        await Future.delayed(const Duration(seconds: 1));
        _plotData = _aiService.generatePlotAnalysis(_contentController.text);
        setState(() {
          _isAnalyzingPlot = false;
        });
      }),
      Future(() async {
        await Future.delayed(const Duration(milliseconds: 500));
        _reviewData = _aiService.generateReview();
        setState(() {
          _isGeneratingReview = false;
        });
      }),
    ]);

    _lastAnalyzedContent = _contentController.text;
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateNovel);
    _contentController.removeListener(_updateNovel);

    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateNovel() {
    final novelListProvider =
        Provider.of<NovelListProvider>(context, listen: false);
    final appState = Provider.of<NovelAppState>(context, listen: false);

    // 内容を更新
    widget.novel.title = _titleController.text;
    widget.novel.content = _contentController.text;
    widget.novel.updatedAt = DateTime.now();

    // プロバイダーを通して更新
    novelListProvider.updateNovel(widget.novel);
    appState.updateNovelContent(_contentController.text);
  }

  Future<bool> _saveNovel() async {
    _updateNovel();
    return true;
  }

  // エクスポートメニューを表示
  void _showExportMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('ダウンロードオプション'),
        message: const Text('小説をエクスポートする形式を選択してください'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showCustomExportDialog(ExportFormat.text);
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
              _showCustomExportDialog(ExportFormat.html);
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
              _exportService.exportAsJson(widget.novel);
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

  // エクスポート成功アラートを表示
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

  // カスタムエクスポートダイアログ（タイトルと著者名を指定可能）
  void _showCustomExportDialog(ExportFormat format) {
    final titleController = TextEditingController(
        text: _titleController.text.isEmpty ? '無題の小説' : _titleController.text);
    final authorController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title:
            Text('${format == ExportFormat.text ? 'テキスト' : 'HTML'}としてエクスポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: titleController,
              placeholder: 'タイトル',
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: authorController,
              placeholder: '著者名（未入力の場合は「匿名」になります）',
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemGrey4),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);

              final title = titleController.text.trim();
              final author = authorController.text.trim();

              if (format == ExportFormat.text) {
                _exportService.exportAsText(
                  widget.novel,
                  customTitle: title.isEmpty ? '無題の小説' : title,
                  author: author.isEmpty ? '匿名' : author,
                );
              } else {
                _exportService.exportAsHtml(
                  widget.novel,
                  customTitle: title.isEmpty ? '無題の小説' : title,
                  author: author.isEmpty ? '匿名' : author,
                );
              }

              _showExportSuccessAlert(
                  '${format == ExportFormat.text ? 'テキスト' : 'HTML'}ファイルをエクスポートしました');
            },
            child: const Text('エクスポート'),
          ),
        ],
      ),
    );
  }

  // 設定情報を分析
  Future<void> _analyzeSettings() async {
    setState(() {
      _isAnalyzingSettings = true;
    });

    // 分析処理
    await Future.delayed(const Duration(seconds: 1));

    _settingsData = _aiService.generateSettings(_contentController.text);
    _lastAnalyzedContent = _contentController.text;

    setState(() {
      _isAnalyzingSettings = false;
    });

    // 更新を通知
    _showExportSuccessAlert('設定情報を更新しました');
  }

  // プロット情報を分析
  Future<void> _analyzePlot() async {
    setState(() {
      _isAnalyzingPlot = true;
    });

    // 分析処理
    await Future.delayed(const Duration(milliseconds: 1500));

    _plotData = _aiService.generatePlotAnalysis(_contentController.text);

    setState(() {
      _isAnalyzingPlot = false;
    });

    // 更新を通知
    _showExportSuccessAlert('プロット情報を更新しました');
  }

  // レビューを生成
  Future<void> _generateReview() async {
    setState(() {
      _isGeneratingReview = true;
    });

    // レビュー生成処理
    await Future.delayed(const Duration(milliseconds: 800));

    _reviewData = _aiService.generateReview();

    setState(() {
      _isGeneratingReview = false;
    });

    // 更新を通知
    _showExportSuccessAlert('レビューを更新しました');
  }

  // AIに次の展開を提案してもらう
  Future<void> _getAISuggestions() async {
    if (_showingSuggestions) return; // 既に表示中なら何もしない

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions =
          await _aiService.generateContinuations(_contentController.text);

      setState(() {
        _aiSuggestions = suggestions;
        _showingSuggestions = true;
        _isLoading = false;
      });

      _showAISuggestionsDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showExportSuccessAlert('エラーが発生しました: $e');
    }
  }

  // AI提案ダイアログを表示
  void _showAISuggestionsDialog() {
    if (_aiSuggestions.isEmpty) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.sparkles, color: CupertinoColors.activeBlue),
            const SizedBox(width: 8),
            const Text('AIからの提案'),
          ],
        ),
        content: SizedBox(
          height: 300,
          child: CupertinoScrollbar(
            child: SingleChildScrollView(
              child: Column(
                children: _aiSuggestions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final suggestion = entry.value;

                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _applySuggestion(suggestion),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: CupertinoColors.activeBlue
                                    .withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '提案 ${index + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.activeBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(suggestion),
                            ],
                          ),
                        ),
                      ),
                      if (index < _aiSuggestions.length - 1)
                        const Divider(height: 20),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              _showingSuggestions = false;
              Navigator.pop(context);
            },
            child: const Text('閉じる'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              _showingSuggestions = false;
              Navigator.pop(context);
              _getAISuggestions(); // 新しい提案を取得
            },
            child: const Text('他の提案を見る'),
          ),
        ],
      ),
    ).then((_) {
      _showingSuggestions = false;
    });
  }

  // 選択した提案を適用するが、拡張版
  Future<void> _applySuggestion(String suggestion) async {
    Navigator.pop(context); // ダイアログを閉じる

    setState(() {
      _isLoading = true;
    });

    try {
      // 提案を元に拡張テキストを生成
      final expandedText = await _aiService.expandSuggestion(
          _contentController.text, suggestion);

      final currentText = _contentController.text;
      final updatedText =
          currentText.isEmpty ? expandedText : '$currentText\n\n$expandedText';

      _contentController.text = updatedText;
      _updateNovel();

      setState(() {
        _isLoading = false;
      });

      // 情報を更新
      _analyzeSettings();
      _generateReview();

      _showExportSuccessAlert('AIの提案を追加しました');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showExportSuccessAlert('エラーが発生しました: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<NovelAppState>(context);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    // ローディング中の表示
    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('共筆。（TOMOFUDE）'),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('AIが文章を分析しています...'),
            ],
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          children: [
            Expanded(
              child: CupertinoTextField(
                controller: _titleController,
                placeholder: 'タイトルを入力',
                decoration: null,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'ver 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey2,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.cloud_download,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              onPressed: _showExportMenu,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                appState.isDarkMode
                    ? CupertinoIcons.sun_max
                    : CupertinoIcons.moon,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
              onPressed: appState.toggleTheme,
            ),
          ],
        ),
      ),
      child: isSmallScreen
          ? _buildMobileLayout(isDark)
          : _buildDesktopLayout(isDark),
    );
  }

  // モバイル向けレイアウト（縦画面最適化）
  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        // エディタ部分（拡大）
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: NovelEditor(
              contentController: _contentController,
              onContentChanged: (content) {
                _updateNovel();
              },
            ),
          ),
        ),

        // ボタンエリア（アイコンのみ）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  CupertinoIcons.floppy_disk,
                  size: 24,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                onPressed: () async {
                  final bool success = await _saveNovel();
                  if (success) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 32),
              CupertinoButton(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  CupertinoIcons.sparkles,
                  size: 24,
                  color: CupertinoColors.activeBlue,
                ),
                onPressed: _getAISuggestions,
              ),
            ],
          ),
        ),

        // 機能パネル（スクロール可能な領域に縦に配置）
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCollapsiblePanel("AIレビュー", _buildReviewPanel()),
                  const SizedBox(height: 8),
                  _buildCollapsiblePanel("設定情報", _buildSettingsPanel()),
                  const SizedBox(height: 8),
                  _buildCollapsiblePanel("プロット分析", _buildPlotPanel()),
                  const SizedBox(height: 8),
                  _buildCollapsiblePanel("展開候補", _buildSuggestionsPanel()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // デスクトップ向けレイアウト（現在のレイアウトを最適化）
  Widget _buildDesktopLayout(bool isDark) {
    return Column(
      children: [
        // メインエディタ部分（エディタと設定パネル）
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // エディタ部分
                Expanded(
                  flex: 3,
                  child: NovelEditor(
                    contentController: _contentController,
                    onContentChanged: (content) {
                      _updateNovel();
                    },
                  ),
                ),

                // レビューパネル
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildReviewPanel(),
                ),
              ],
            ),
          ),
        ),

        // 下部ボタンエリア（アイコンのみ）
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  CupertinoIcons.floppy_disk,
                  size: 24,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                onPressed: () async {
                  final bool success = await _saveNovel();
                  if (success) {
                    Navigator.pop(context);
                  }
                },
              ),
              const SizedBox(width: 32),
              CupertinoButton(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  CupertinoIcons.sparkles,
                  size: 24,
                  color: CupertinoColors.activeBlue,
                ),
                onPressed: _getAISuggestions,
              ),
            ],
          ),
        ),

        // 下部のパネル（設定・プロット・次の展開候補）
        SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 設定情報パネル
                Expanded(
                  child: _buildSettingsPanel(),
                ),
                const SizedBox(width: 16),

                // プロットパネル
                Expanded(
                  child: _buildPlotPanel(),
                ),
                const SizedBox(width: 16),

                // 次の展開候補パネル
                Expanded(
                  child: _buildSuggestionsPanel(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 折りたたみ可能なパネルを構築
  Widget _buildCollapsiblePanel(String title, Widget content) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
        ),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              height: 200,
              child: content,
            ),
          ),
        ],
      ),
    );
  }

  // レビューパネルを構築
  Widget _buildReviewPanel() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.text_bubble,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AIレビュー',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  onPressed: _generateReview,
                ),
              ],
            ),
          ),

          Container(
            height: 0.5,
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey4,
          ),

          // レビュー内容
          Expanded(
            child: _isGeneratingReview
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReviewSection(
                          icon: CupertinoIcons.book,
                          title: '読者視点',
                          content: _reviewData['reader'] ?? '',
                          iconColor: CupertinoColors.systemPurple,
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(
                          icon: CupertinoIcons.pencil,
                          title: '編集者視点',
                          content: _reviewData['editor'] ?? '',
                          iconColor: CupertinoColors.systemBlue,
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(
                          icon: CupertinoIcons.star,
                          title: '審査員視点',
                          content: _reviewData['jury'] ?? '',
                          iconColor: CupertinoColors.systemYellow,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // レビューセクションを構築
  Widget _buildReviewSection({
    required IconData icon,
    required String title,
    required String content,
    required Color iconColor,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content.isEmpty ? '分析中...' : content,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
      ],
    );
  }

  // 設定情報パネルを構築
  Widget _buildSettingsPanel() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.gear,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '設定情報',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  onPressed: _analyzeSettings,
                ),
              ],
            ),
          ),

          Container(
            height: 0.5,
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey4,
          ),

          // 設定内容
          Expanded(
            child: _isAnalyzingSettings
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingSection(
                          title: '登場人物',
                          content: _settingsData['characters'] ?? [],
                          type: SettingType.character,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: '組織',
                          content: _settingsData['organizations'] ?? [],
                          type: SettingType.organization,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: '舞台',
                          content: _settingsData['setting'] ?? '',
                          type: SettingType.text,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: 'ジャンル',
                          content: _settingsData['genre'] ?? '',
                          type: SettingType.text,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: '専門用語',
                          content: _settingsData['terminology'] ?? [],
                          type: SettingType.terminology,
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 設定セクションを構築
  Widget _buildSettingSection({
    required String title,
    required dynamic content,
    required SettingType type,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
        const SizedBox(height: 4),
        if (type == SettingType.text)
          Text(
            content.toString().isEmpty ? '-' : content.toString(),
            style: const TextStyle(fontSize: 13),
          )
        else if (type == SettingType.character ||
            type == SettingType.organization ||
            type == SettingType.terminology)
          _buildCollapsibleList(content, type),
      ],
    );
  }

  // 折りたたみ可能なリストを構築
  Widget _buildCollapsibleList(dynamic items, SettingType type) {
    if (items is! List || items.isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map<Widget>((item) {
        if (type == SettingType.character || type == SettingType.organization) {
          final name = item['name'] ?? '';
          final description = item['description'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• $name',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 2, bottom: 4),
                    child: Text(
                      description,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        } else if (type == SettingType.terminology) {
          final term = item['term'] ?? '';
          final definition = item['definition'] ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '• $term',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (definition.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 10, top: 2, bottom: 4),
                    child: Text(
                      definition,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• ${item.toString()}',
              style: const TextStyle(fontSize: 13),
            ),
          );
        }
      }).toList(),
    );
  }

  // プロットパネルを構築
  Widget _buildPlotPanel() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.chart_bar,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'プロット分析',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    CupertinoIcons.refresh,
                    size: 18,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  onPressed: _analyzePlot,
                ),
              ],
            ),
          ),

          Container(
            height: 0.5,
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey4,
          ),

          // プロット内容
          Expanded(
            child: _isAnalyzingPlot
                ? const Center(child: CupertinoActivityIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlotSection(
                          title: '現在の段階',
                          content: _plotData['currentStage'] ?? '',
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '主要イベント',
                          content: _plotData['mainEvents'] ?? [],
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '転換点',
                          content: _plotData['turningPoints'] ?? [],
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '未解決の問題',
                          content: _plotData['unresolvedIssues'] ?? [],
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // プロットセクションを構築
  Widget _buildPlotSection({
    required String title,
    required dynamic content,
  }) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
        const SizedBox(height: 4),
        if (content is String)
          Text(
            content.isEmpty ? '-' : content,
            style: const TextStyle(fontSize: 13),
          )
        else if (content is List)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  // 次の展開候補パネルを構築
  Widget _buildSuggestionsPanel() {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.lightbulb,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '展開候補',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            height: 0.5,
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey4,
          ),

          // 展開候補内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '可能性のある展開',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.systemGrey2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_plotData.containsKey('possibleDevelopments') &&
                      _plotData['possibleDevelopments'] is List &&
                      (_plotData['possibleDevelopments'] as List).isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (_plotData['possibleDevelopments'] as List)
                          .map<Widget>((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF2C2C2E)
                                  : CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    CupertinoColors.activeBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              item.toString(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        );
                      }).toList(),
                    )
                  else
                    Text(
                      'AIに続きを提案してもらうボタンを押すと、ここに展開候補が表示されます。',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? CupertinoColors.systemGrey
                            : CupertinoColors.systemGrey2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
