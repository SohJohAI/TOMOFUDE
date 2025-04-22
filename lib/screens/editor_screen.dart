// ✅ REVISED: NovelEditorScreen – now includes AI‑powered resource generation button
//            and pop‑up panels for 設定情報, プロット, 展開候補, 感情分析, レビュー.
// IMPORTANT: replace <PROJECT_ID> with your Supabase project id.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/novel_list_provider.dart';
import '../models/novel.dart';
import '../models/emotion.dart';
import '../services/ai_service.dart';
import '../services/ai_service_interface.dart';
import '../services/service_locator.dart';
import '../services/point_service_interface.dart';
import '../widgets/novel_editor.dart';
import '../widgets/emotion_panel.dart';
import '../widgets/ai_panel.dart';
import 'work_list_screen.dart';
import 'plot_booster_screen.dart';

class NovelEditorScreen extends StatefulWidget {
  final Novel novel;
  const NovelEditorScreen({Key? key, required this.novel}) : super(key: key);
  @override
  State<NovelEditorScreen> createState() => _NovelEditorScreenState();
}

class _NovelEditorScreenState extends State<NovelEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final AIService _aiService;
  late final PointServiceInterface _pointService;

  final Map<String, dynamic> _settingsData = {};
  final Map<String, dynamic> _plotData = {};
  final Map<String, List<String>> _candidates = {};
  final Map<String, String> _reviewData = {
    'reader': '',
    'editor': '',
    'jury': ''
  };
  EmotionAnalysis? _emotionAnalysis;

  bool _busy = false;
  String _busyMessage = '';

  @override
  void initState() {
    super.initState();
    _aiService = serviceLocator<AIService>();
    _pointService = serviceLocator<PointServiceInterface>();

    _titleController = TextEditingController(text: widget.novel.title)
      ..addListener(_persistNovel);
    _contentController = TextEditingController(text: widget.novel.content)
      ..addListener(_persistNovel);
  }

  // ---------------------------------------------------------------------------
  // Data persistence
  // ---------------------------------------------------------------------------
  void _persistNovel() {
    final provider = Provider.of<NovelListProvider>(context, listen: false);
    provider.updateNovel(
      widget.novel.copyWith(
        title: _titleController.text,
        content: _contentController.text,
        updatedAt: DateTime.now(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI resource generation
  // ---------------------------------------------------------------------------

  // ポイント消費の確認
  Future<bool> _checkAndConfirmPointConsumption(int amount) async {
    // ポイント残高を確認
    final hasEnoughPoints = await _pointService.hasEnoughPoints(amount);

    if (!hasEnoughPoints) {
      // ポイント不足の場合、ダイアログを表示
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ポイント不足'),
          content: Text('この操作には$amountポイントが必要ですが、ポイントが足りません。ポイントを購入しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                // ポイント購入画面に遷移
                Navigator.pop(context, false);
                // TODO: ポイント購入画面への遷移を実装
              },
              child: const Text('ポイントを購入'),
            ),
          ],
        ),
      );

      return shouldProceed ?? false;
    }

    // ポイント消費の確認ダイアログを表示
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ポイント消費の確認'),
        content: Text('この操作には$amountポイントが消費されます。続行しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('続行'),
          ),
        ],
      ),
    );

    return shouldProceed ?? false;
  }

  // ポイントを消費
  Future<bool> _consumePoints(int amount, String purpose) async {
    try {
      final success = await _pointService.consumePoints(amount, purpose);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$amountポイントを消費しました')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ポイント消費に失敗しました')),
        );
      }
      return success;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ポイント消費エラー: $e')),
      );
      return false;
    }
  }

  Future<void> _generateResources() async {
    if (_busy) return;
<<<<<<< HEAD

    // ポイント消費の確認（100ポイント）
    final canProceed = await _checkAndConfirmPointConsumption(100);
    if (!canProceed) return;

    // 既存資料の入力を確認するダイアログを表示
    final existingDocs = await _showExistingDocsDialog();
    if (existingDocs == null) return; // キャンセルされた場合

=======
>>>>>>> parent of 8de1867 (修正６)
    setState(() {
      _busy = true;
      _busyMessage = 'AIが資料を生成中…';
    });
    try {
      final content = _contentController.text;
      final novelTitle =
          _titleController.text.isEmpty ? 'Untitled' : _titleController.text;

      // 🔮 1) 設定情報
      _settingsData.clear();
      _settingsData.addAll(
          await _aiService.generateSettings(content, contentType: novelTitle));

      // 🔮 2) プロット
      _plotData.clear();
      _plotData.addAll(await _aiService.generatePlotAnalysis(content,
          newContent: novelTitle));

      // 🔮 3) 展開候補
      _candidates.clear();
      final suggestions = await _aiService.generateContinuations(content,
          newContent: novelTitle);
      _candidates['次の展開候補'] = suggestions;

      // 🔮 4) 感情分析
      final emotionData = await _aiService.analyzeEmotion(
        content,
        aiDocs: novelTitle,
      );
      _emotionAnalysis = EmotionAnalysis.fromJson(emotionData);

      // 🔮 5) レビュー
      _reviewData.updateAll((k, v) => '');
      _reviewData.addAll(await _aiService.generateReview(content));

      if (!mounted) return;

      // 生成成功後にポイントを消費
      await _consumePoints(100, 'AI資料生成');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI資料を生成しました')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('生成失敗: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = '';
        });
      }
    }
  }

<<<<<<< HEAD
  // 既存資料入力ダイアログを表示
  Future<Map<String, String>?> _showExistingDocsDialog() async {
    final settingsController = TextEditingController();
    final plotController = TextEditingController();
    final emotionController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('既存の資料を入力しますか？'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: settingsController,
                decoration: const InputDecoration(labelText: '設定情報'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: plotController,
                decoration: const InputDecoration(labelText: 'プロット情報'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emotionController,
                decoration: const InputDecoration(labelText: '感情分析情報'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {}), // 空のマップを返す（既存資料なし）
            child: const Text('資料なしで生成'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'settingInfo': settingsController.text,
              'plotInfo': plotController.text,
              'emotionInfo': emotionController.text,
            }),
            child: const Text('この資料で生成'),
          ),
        ],
      ),
    );
  }

  // AI執筆支援資料を生成
  Future<void> _generateAIDocs({
    String? settingInfo,
    String? plotInfo,
    String? emotionInfo,
  }) async {
    setState(() {
      _busyMessage = 'AI執筆支援資料を生成中…';
    });

    try {
      final content = _contentController.text;

      // 設定情報、プロット情報、感情分析情報を使用
      final settingInfoToUse = settingInfo ??
          (_settingsData.isNotEmpty ? jsonEncode(_settingsData) : null);

      final plotInfoToUse =
          plotInfo ?? (_plotData.isNotEmpty ? jsonEncode(_plotData) : null);

      final emotionInfoToUse = emotionInfo ??
          (_emotionAnalysis != null
              ? jsonEncode(_emotionAnalysis!.toJson())
              : null);

      // AIドキュメントを生成
      _aiDocsPreview = await _aiService.generateAIDocs(
        content,
        settingInfo: settingInfoToUse,
        plotInfo: plotInfoToUse,
        emotionInfo: emotionInfoToUse,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI執筆支援資料の生成に失敗: $e')),
        );
      }
    }
  }

  // AI執筆支援資料のプレビューを表示
  void _showAIDocsPreview() {
    _openDialog(
      'AI執筆支援資料',
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    // ポイント消費の確認（30ポイント）
                    final canProceed =
                        await _checkAndConfirmPointConsumption(30);
                    if (!canProceed) return;

                    // 再生成
                    await _generateAIDocs();

                    // 成功後にポイントを消費
                    await _consumePoints(30, 'AI執筆支援資料再生成');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('再生成'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _aiDocsPreview.isEmpty
                ? const Center(child: Text('資料がまだ生成されていません'))
                : Markdown(
                    data: _aiDocsPreview,
                    selectable: true,
                    padding: const EdgeInsets.all(16),
                  ),
          ),
        ],
      ),
    );
  }

=======
>>>>>>> parent of 8de1867 (修正６)
  // ---------------------------------------------------------------------------
  // Helpers – modal windows
  // ---------------------------------------------------------------------------
  void _openDialog(String title, Widget body) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).canvasColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        minChildSize: 0.4,
        initialChildSize: 0.75,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  void _showSettings() => _openDialog(
        '設定情報',
        ListView(
          padding: const EdgeInsets.all(16),
          children: _settingsData.entries
              .map((e) => ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value.toString()),
                  ))
              .toList(),
        ),
      );

  void _showPlot() => _openDialog(
        'プロット',
        ListView(
          padding: const EdgeInsets.all(16),
          children: _plotData.entries
              .map((e) => ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value.toString()),
                  ))
              .toList(),
        ),
      );

  // 展開候補を本文に挿入
  Future<void> _insertContinuation(String continuation) async {
    // ポイント消費の確認（20ポイント）
    final canProceed = await _checkAndConfirmPointConsumption(20);
    if (!canProceed) return;

    final currentText = _contentController.text;
    final selection = _contentController.selection;

    // 選択範囲の末尾に挿入
    final newText = currentText.replaceRange(
      selection.end,
      selection.end,
      '\n\n$continuation',
    );

    // テキストを更新し、カーソルを挿入した文章の末尾に移動
    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.end + continuation.length + 2,
      ),
    );

    // ダイアログを閉じる
    Navigator.pop(context);

    // ポイントを消費
    await _consumePoints(20, '展開候補挿入');

    // 挿入完了メッセージを表示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('展開候補を挿入しました')),
    );
  }

  void _showCandidates() => _openDialog(
        '展開候補',
        ListView(
          padding: const EdgeInsets.all(16),
          children: _candidates.entries
              .expand((e) => [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text('★ ${e.key}',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ..._buildCandidateItems(e.value),
                  ])
              .toList(),
        ),
      );

  // 展開候補アイテムを構築（挿入ボタン付き）
  List<Widget> _buildCandidateItems(List<String> candidates) {
    return candidates
        .map((c) => Card(
              margin: const EdgeInsets.only(left: 12, bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('挿入'),
                          onPressed: () => _insertContinuation(c),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ))
        .toList();
  }

  void _showEmotion() => _openDialog(
        '感情分析',
        _emotionAnalysis == null
            ? const Center(child: Text('未分析'))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: EmotionPanel(
                  emotionAnalysis: _emotionAnalysis,
                  isLoading: false,
                  onRefresh: _generateResources,
                  pointService: _pointService,
                  onConsumePoints: _consumePoints,
                ),
              ),
      );

  void _showReviews() => _openDialog(
        'レビュー',
        ListView(
          padding: const EdgeInsets.all(16),
          children: _reviewData.entries
              .map((e) => ListTile(
                    title: Text(e.key),
                    subtitle: Text(e.value),
                  ))
              .toList(),
        ),
      );

  // AIパネルを表示（設定情報、プロット、レビューをタブ形式で表示）
  void _showAIPanel() => _openDialog(
        'AI分析パネル',
        AIPanel(
          settingsData: _settingsData,
          plotData: _plotData,
          reviewData: _reviewData,
          onAnalyzeSettings: _generateResources,
          onAnalyzePlot: _generateResources,
          onGenerateReview: _generateResources,
          isAnalyzingSettings: _busy,
          isAnalyzingPlot: _busy,
          isGeneratingReview: _busy,
          pointService: _pointService,
          onConsumePoints: _consumePoints,
        ),
      );

  // ---------------------------------------------------------------------------
  // Plot Booster Integration
  // ---------------------------------------------------------------------------

  // プロットブースターからデータをインポート
  Future<void> _importFromPlotBooster() async {
    try {
      // ポイント消費の確認（50ポイント）
      final canProceed = await _checkAndConfirmPointConsumption(50);
      if (!canProceed) return;

      // プロットブースター画面を表示
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlotBoosterScreen()),
      );

      // プロットブースターから戻ってきた結果を処理
      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _busy = true;
          _busyMessage = 'プロットブースターからデータをインポート中...';
        });

        // プロットデータをインポート
        if (result.containsKey('plotData')) {
          _plotData.clear();
          _plotData.addAll(result['plotData']);
        }

        // 設定データをインポート
        if (result.containsKey('settingsData')) {
          _settingsData.clear();
          _settingsData.addAll(result['settingsData']);
        }

        // AI執筆支援資料を生成
        await _generateAIDocs();

        // 成功後にポイントを消費
        await _consumePoints(50, 'プロットブースターインポート');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('プロットブースターからデータをインポートしました')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('インポート失敗: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = '';
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.novel.title.isEmpty ? '新規小説' : widget.novel.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'AI分析パネル',
            onPressed: () => _showAIPanel(),
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _persistNovel),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const WorkListScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateResources,
        label: const Text('AI資料生成'),
        icon: const Icon(Icons.auto_awesome),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'タイトル',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: NovelEditor(
                    contentController: _contentController,
                    onContentChanged: (_) {},
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    _QuickButton('設定情報', _showSettings,
                        enabled: _settingsData.isNotEmpty),
                    _QuickButton('プロット', _showPlot,
                        enabled: _plotData.isNotEmpty),
                    _QuickButton('展開候補', _showCandidates,
                        enabled: _candidates.isNotEmpty),
                    _QuickButton('感情分析', _showEmotion,
                        enabled: _emotionAnalysis != null),
                    _QuickButton('レビュー', _showReviews,
                        enabled: _reviewData.values.any((v) => v.isNotEmpty)),
<<<<<<< HEAD
                    _QuickButton('AI執筆支援資料', _showAIDocsPreview,
                        enabled: _aiDocsPreview.isNotEmpty),
                    _QuickButton('プロットブースター', _importFromPlotBooster,
                        enabled: true),
=======
>>>>>>> parent of 8de1867 (修正６)
                  ],
                ),
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_busyMessage,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick access pill‑style buttons
// ---------------------------------------------------------------------------
class _QuickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  const _QuickButton(this.label, this.onTap, {this.enabled = true, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: enabled ? null : colorScheme.onSurfaceVariant,
          backgroundColor: enabled
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: enabled ? onTap : null,
        child: Text(label),
      ),
    );
  }
}
