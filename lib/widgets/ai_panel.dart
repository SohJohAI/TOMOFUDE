import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/point_service_interface.dart';

enum SettingType { text, character, organization, terminology }

class AIPanel extends StatefulWidget {
  final Map<String, dynamic> settingsData;
  final Map<String, dynamic> plotData;
  final Map<String, String> reviewData;
  final Function onAnalyzeSettings;
  final Function onAnalyzePlot;
  final Function onGenerateReview;
  final bool isAnalyzingSettings;
  final bool isAnalyzingPlot;
  final bool isGeneratingReview;
  final PointServiceInterface? pointService;
  final Function? onConsumePoints;

  const AIPanel({
    Key? key,
    required this.settingsData,
    required this.plotData,
    required this.reviewData,
    required this.onAnalyzeSettings,
    required this.onAnalyzePlot,
    required this.onGenerateReview,
    required this.isAnalyzingSettings,
    required this.isAnalyzingPlot,
    required this.isGeneratingReview,
    this.pointService,
    this.onConsumePoints,
  }) : super(key: key);

  @override
  _AIPanelState createState() => _AIPanelState();
}

class _AIPanelState extends State<AIPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // ポイント消費の確認
  Future<bool> _checkAndConfirmPointConsumption(int amount) async {
    if (widget.pointService == null) return true;

    // ポイント残高を確認
    final hasEnoughPoints = await widget.pointService!.hasEnoughPoints(amount);

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
    if (widget.pointService == null) return true;

    try {
      if (widget.onConsumePoints != null) {
        return await widget.onConsumePoints!(amount, purpose);
      }

      final success = await widget.pointService!.consumePoints(amount, purpose);
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '設定'),
            Tab(text: 'プロット'),
            Tab(text: 'レビュー'),
          ],
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSettingsPanel(),
              _buildPlotPanel(),
              _buildReviewPanel(),
            ],
          ),
        ),
      ],
    );
  }

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
                  onPressed: () async {
                    // ポイント消費の確認（30ポイント）
                    final canProceed =
                        await _checkAndConfirmPointConsumption(30);
                    if (!canProceed) return;

                    // 設定情報を更新
                    await widget.onAnalyzeSettings();

                    // 成功後にポイントを消費
                    await _consumePoints(30, '設定情報更新');
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 設定内容
          Expanded(
            child: widget.isAnalyzingSettings
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSettingSection(
                          title: '登場人物',
                          content: widget.settingsData['characters'] ?? [],
                          type: SettingType.character,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: '組織',
                          content: widget.settingsData['organizations'] ?? [],
                          type: SettingType.organization,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: '舞台',
                          content: widget.settingsData['setting'] ?? '',
                          type: SettingType.text,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: 'ジャンル',
                          content: widget.settingsData['genre'] ?? '',
                          type: SettingType.text,
                        ),
                        const SizedBox(height: 8),
                        _buildSettingSection(
                          title: '専門用語',
                          content: widget.settingsData['terminology'] ?? [],
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
                  onPressed: () async {
                    // ポイント消費の確認（30ポイント）
                    final canProceed =
                        await _checkAndConfirmPointConsumption(30);
                    if (!canProceed) return;

                    // プロットを更新
                    await widget.onAnalyzePlot();

                    // 成功後にポイントを消費
                    await _consumePoints(30, 'プロット更新');
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // プロット内容
          Expanded(
            child: widget.isAnalyzingPlot
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlotSection(
                          title: '導入部',
                          content: widget.plotData['introduction'] ?? '',
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '主な出来事',
                          content: widget.plotData['mainEvents'] ?? [],
                          isList: true,
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '転換点',
                          content: widget.plotData['turningPoints'] ?? [],
                          isList: true,
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '現在の展開段階',
                          content: widget.plotData['currentStage'] ?? '',
                          isHighlighted: true,
                        ),
                        const SizedBox(height: 8),
                        _buildPlotSection(
                          title: '未解決の問題',
                          content: widget.plotData['unresolvedIssues'] ?? [],
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
                  onPressed: () async {
                    // ポイント消費の確認（30ポイント）
                    final canProceed =
                        await _checkAndConfirmPointConsumption(30);
                    if (!canProceed) return;

                    // レビューを更新
                    await widget.onGenerateReview();

                    // 成功後にポイントを消費
                    await _consumePoints(30, 'レビュー更新');
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // レビュー内容
          Expanded(
            child: widget.isGeneratingReview
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReviewSection(
                          icon: Icons.menu_book,
                          title: '読者視点',
                          content: widget.reviewData['reader'] ?? '',
                          iconColor: Colors.purple,
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(
                          icon: Icons.edit_note,
                          title: '編集者視点',
                          content: widget.reviewData['editor'] ?? '',
                          iconColor: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        _buildReviewSection(
                          icon: Icons.emoji_events,
                          title: '審査員視点',
                          content: widget.reviewData['jury'] ?? '',
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
}
