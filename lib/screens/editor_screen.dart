// ✅ REVISED: NovelEditorScreen – now includes AI‑powered resource generation button
//            and pop‑up panels for 設定情報, プロット, 展開候補, 感情分析, レビュー.
// IMPORTANT: replace <PROJECT_ID> with your Supabase project id.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../providers/novel_list_provider.dart';
import '../models/novel.dart';
import '../models/emotion.dart';
import '../services/ai_service.dart';
import '../services/ai_service_interface.dart';
import '../widgets/novel_editor.dart';
import '../widgets/emotion_panel.dart';
import 'work_list_screen.dart';

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

  final Map<String, dynamic> _settingsData = {};
  final Map<String, dynamic> _plotData = {};
  final Map<String, List<String>> _candidates = {};
  final Map<String, String> _reviewData = {
    'reader': '',
    'editor': '',
    'jury': ''
  };
  EmotionAnalysis? _emotionAnalysis;

  // AI執筆支援資料のプレビュー用
  String _aiDocsPreview = '';

  bool _busy = false;
  String _busyMessage = '';

  @override
  void initState() {
    super.initState();
    _aiService = const SupabaseAIService();

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
  Future<void> _generateResources() async {
    if (_busy) return;

    // 既存資料の入力を確認するダイアログを表示
    final existingDocs = await _showExistingDocsDialog();
    if (existingDocs == null) return; // キャンセルされた場合

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

      // 🔮 6) AI執筆支援資料の生成（既存資料がある場合はそれを使用）
      if (existingDocs.isNotEmpty) {
        await _generateAIDocs(
          settingInfo: existingDocs['settingInfo'],
          plotInfo: existingDocs['plotInfo'],
          emotionInfo: existingDocs['emotionInfo'],
        );
      } else {
        // 生成した資料を使用してAI執筆支援資料を生成
        await _generateAIDocs();
      }

      if (!mounted) return;
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
                  onPressed: () => _generateAIDocs(),
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
                    ...e.value.map((c) => Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Text('• $c'),
                        ))
                  ])
              .toList(),
        ),
      );

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

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.novel.title.isEmpty ? '新規小説' : widget.novel.title),
        actions: [
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
                    _QuickButton('AI執筆支援資料', _showAIDocsPreview,
                        enabled: _aiDocsPreview.isNotEmpty),
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
