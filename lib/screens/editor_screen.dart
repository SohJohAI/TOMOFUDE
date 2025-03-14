import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../providers/novel_list_provider.dart';
import '../models/novel.dart';
import '../services/export_service.dart';
import '../services/ai_service.dart';
import '../widgets/novel_editor.dart';

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
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // タイトル部分
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.file_download, color: Color(0xFF5D5CDE)),
                  const SizedBox(width: 16),
                  const Text(
                    'ダウンロードオプション',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // メインオプション
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.text_format),
                      title: const Text('テキストファイル (.txt)'),
                      subtitle: const Text('プレーンテキストとして保存'),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomExportDialog(ExportFormat.text);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.code),
                      title: const Text('HTMLファイル (.html)'),
                      subtitle: const Text('整形されたWebページとして保存'),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomExportDialog(ExportFormat.html);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.data_object),
                      title: const Text('JSONファイル (.json)'),
                      subtitle: const Text('アプリ互換形式で保存'),
                      onTap: () {
                        Navigator.pop(context);
                        _exportService.exportAsJson(widget.novel);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSONファイルをエクスポートしました')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // カスタムエクスポートダイアログ（タイトルと著者名を指定可能）
  void _showCustomExportDialog(ExportFormat format) {
    final titleController = TextEditingController(
        text: _titleController.text.isEmpty ? '無題の小説' : _titleController.text);
    final authorController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('${format == ExportFormat.text ? 'テキスト' : 'HTML'}としてエクスポート'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: authorController,
              decoration: const InputDecoration(
                labelText: '著者名（任意）',
                border: OutlineInputBorder(),
                hintText: '未入力の場合は「匿名」になります',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          FilledButton(
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

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        '${format == ExportFormat.text ? 'テキスト' : 'HTML'}ファイルをエクスポートしました')),
              );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('設定情報を更新しました')),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('プロット情報を更新しました')),
    );
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('レビューを更新しました')),
    );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  // AI提案ダイアログを表示
  void _showAISuggestionsDialog() {
    if (_aiSuggestions.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('AIからの提案'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _aiSuggestions.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              return InkWell(
                onTap: () => _applySuggestion(_aiSuggestions[index]),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '提案 ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_aiSuggestions[index]),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _showingSuggestions = false;
              Navigator.pop(context);
            },
            child: const Text('閉じる'),
          ),
          TextButton(
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AIの提案を追加しました')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<NovelAppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ローディング中の表示
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('共筆。（TOMOFUDE）')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('AIが文章を分析しています...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'タイトルを入力',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey[700] // ライトモードではダークグレー
                        : Colors.white70, // ダークモードでは薄い白
                  ),
                ),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black // ライトモードでは黒
                      : Colors.white, // ダークモードでは白
                ),
              ),
            ),
            Text(
              'ver 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white70 // ダークモードでは薄い白色
                    : Colors.black54, // ライトモードでは薄い黒色
              ),
            ),
          ],
        ),
        actions: [
          // エクスポートボタン
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'エクスポート',
            onPressed: _showExportMenu,
          ),
          IconButton(
            icon: Icon(
              appState.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: appState.toggleTheme,
          ),
        ],
      ),
      body: Column(
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

          // 下部ボタンエリア
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final bool success = await _saveNovel();
                    if (success) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('保存して戻る'),
                ),
                ElevatedButton.icon(
                  onPressed: _getAISuggestions,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('AIに続きを提案してもらう'),
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
      ),
    );
  }

  // レビューパネルを構築
  Widget _buildReviewPanel() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
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
                      Icons.rate_review,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
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
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'レビューを更新',
                  onPressed: _generateReview,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // レビュー内容
          Expanded(
            child: _isGeneratingReview
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReviewSection(
                          icon: Icons.menu_book,
                          title: '読者視点',
                          content: _reviewData['reader'] ?? '',
                          iconColor: Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(
                          icon: Icons.edit_note,
                          title: '編集者視点',
                          content: _reviewData['editor'] ?? '',
                          iconColor: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(
                          icon: Icons.emoji_events,
                          title: '審査員視点',
                          content: _reviewData['jury'] ?? '',
                          iconColor: Colors.amber,
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[300]
                : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  // 設定情報パネルを構築
  Widget _buildSettingsPanel() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
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
                      Icons.settings,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
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
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: '設定情報を更新',
                  onPressed: _analyzeSettings,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 設定内容
          Expanded(
            child: _isAnalyzingSettings
                ? const Center(child: CircularProgressIndicator())
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
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

  // 折りたたみ可能なリスト
  Widget _buildCollapsibleList(List items, SettingType type) {
    if (items.isEmpty) {
      return const Text('-', style: TextStyle(fontSize: 13));
    }

    return Column(
      children: items.map<Widget>((item) {
        // アイテムが文字列かオブジェクトか判定
        String name = '';
        String description = '';

        if (item is String) {
          name = item;
          description = '';
        } else if (item is Map) {
          if (type == SettingType.character ||
              type == SettingType.organization) {
            name = item['name'] ?? '';
            description = item['description'] ?? '';
          } else if (type == SettingType.terminology) {
            name = item['term'] ?? '';
            description = item['definition'] ?? '';
          }
        }

        if (name.isEmpty) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade800
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 8),
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            title: Text(
              name,
              style: const TextStyle(fontSize: 13),
            ),
            children: [
              if (description.isNotEmpty)
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[300]
                        : Colors.grey[700],
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // プロットパネルを構築
  Widget _buildPlotPanel() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
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
                      Icons.map,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'プロット',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'プロットを更新',
                  onPressed: _analyzePlot,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // プロット内容
          Expanded(
            child: _isAnalyzingPlot
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlotSection(
                          title: '導入部',
                          content: _plotData['introduction'] ?? '',
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '主な出来事',
                          content: _plotData['mainEvents'] ?? [],
                          isList: true,
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '転換点',
                          content: _plotData['turningPoints'] ?? [],
                          isList: true,
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '現在の展開段階',
                          content: _plotData['currentStage'] ?? '',
                          isHighlighted: true,
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '未解決の問題',
                          content: _plotData['unresolvedIssues'] ?? [],
                          isList: true,
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
    bool isList = false,
    bool isHighlighted = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.primary.withOpacity(0.7)
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        if (!isList)
          Container(
            padding: isHighlighted ? const EdgeInsets.all(4) : null,
            decoration: isHighlighted
                ? BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              content.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          )
        else if (content is List && content.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: content.map<Widget>((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('・', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        item.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        else
          const Text('-', style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // 次の展開候補パネルを構築
  Widget _buildSuggestionsPanel() {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade700
              : Colors.grey.shade300,
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
                      Icons.lightbulb,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '次の展開候補',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: '展開候補を更新',
                  onPressed: _getAISuggestions,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 展開候補内容
          Expanded(
            child: FutureBuilder<List<String>>(
              future: _aiService.generateContinuations(_contentController.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('展開候補はありません'));
                }

                final suggestions = snapshot.data!;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: suggestions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final suggestion = entry.value;

                      return InkWell(
                        onTap: () => _applySuggestion(suggestion),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '提案 ${index + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                suggestion,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
