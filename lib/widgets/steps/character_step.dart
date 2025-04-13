import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../models/plot_booster.dart';

class CharacterStep extends StatefulWidget {
  @override
  _CharacterStepState createState() => _CharacterStepState();
}

class _CharacterStepState extends State<CharacterStep>
    with SingleTickerProviderStateMixin {
  final PlotBoosterService _service = PlotBoosterService();
  late TabController _tabController;

  bool _isLoadingProtagonist = false;
  bool _isLoadingAntagonist = false;

  // 主人公用コントローラー
  final TextEditingController _protagonistNameController =
      TextEditingController();
  final TextEditingController _protagonistDescController =
      TextEditingController();
  final TextEditingController _protagonistMotivationController =
      TextEditingController();
  final TextEditingController _protagonistConflictController =
      TextEditingController();

  // 敵対者用コントローラー
  final TextEditingController _antagonistNameController =
      TextEditingController();
  final TextEditingController _antagonistDescController =
      TextEditingController();
  final TextEditingController _antagonistMotivationController =
      TextEditingController();
  final TextEditingController _antagonistConflictController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);

      // 主人公の情報を設定
      _protagonistNameController.text = provider.plotBooster.protagonist.name;
      _protagonistDescController.text =
          provider.plotBooster.protagonist.description;
      _protagonistMotivationController.text =
          provider.plotBooster.protagonist.motivation;
      _protagonistConflictController.text =
          provider.plotBooster.protagonist.conflict;

      // 敵対者の情報を設定
      _antagonistNameController.text = provider.plotBooster.antagonist.name;
      _antagonistDescController.text =
          provider.plotBooster.antagonist.description;
      _antagonistMotivationController.text =
          provider.plotBooster.antagonist.motivation;
      _antagonistConflictController.text =
          provider.plotBooster.antagonist.conflict;
    });
  }

  Future<void> _loadProtagonistSuggestion() async {
    setState(() {
      _isLoadingProtagonist = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        final suggestion = await _service.suggestProtagonist(
          provider.plotBooster.logline,
          provider.plotBooster.themes,
        );

        setState(() {
          _protagonistNameController.text = suggestion.name;
          _protagonistDescController.text = suggestion.description;
          _protagonistMotivationController.text = suggestion.motivation;
          _protagonistConflictController.text = suggestion.conflict;
        });

        // プロバイダーを更新
        provider.updateProtagonist(suggestion);
      }
    } catch (e) {
      print('提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoadingProtagonist = false;
      });
    }
  }

  Future<void> _loadAntagonistSuggestion() async {
    setState(() {
      _isLoadingAntagonist = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        final protagonist = Character(
          name: _protagonistNameController.text,
          description: _protagonistDescController.text,
          motivation: _protagonistMotivationController.text,
          conflict: _protagonistConflictController.text,
        );

        final suggestion = await _service.suggestAntagonist(
          provider.plotBooster.logline,
          protagonist,
        );

        setState(() {
          _antagonistNameController.text = suggestion.name;
          _antagonistDescController.text = suggestion.description;
          _antagonistMotivationController.text = suggestion.motivation;
          _antagonistConflictController.text = suggestion.conflict;
        });

        // プロバイダーを更新
        provider.updateAntagonist(suggestion);
      }
    } catch (e) {
      print('提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoadingAntagonist = false;
      });
    }
  }

  void _updateProtagonist() {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final protagonist = Character(
      name: _protagonistNameController.text,
      description: _protagonistDescController.text,
      motivation: _protagonistMotivationController.text,
      conflict: _protagonistConflictController.text,
    );

    provider.updateProtagonist(protagonist);
  }

  void _updateAntagonist() {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final antagonist = Character(
      name: _antagonistNameController.text,
      description: _antagonistDescController.text,
      motivation: _antagonistMotivationController.text,
      conflict: _antagonistConflictController.text,
    );

    provider.updateAntagonist(antagonist);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'キャラクターを設計しましょう',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 8),
              Text(
                '主人公と敵対者（または主な障害）を設定します。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // タブバー
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: '主人公'),
            Tab(text: '敵対者/障害'),
          ],
        ),

        // タブビュー
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 主人公タブ
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 主人公入力フォーム
                    TextField(
                      controller: _protagonistNameController,
                      decoration: InputDecoration(
                        labelText: '名前',
                        hintText: '例: 太郎、アリス、主人公名など',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateProtagonist(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _protagonistDescController,
                      decoration: InputDecoration(
                        labelText: '人物像',
                        hintText: '例: 18歳の少年。魔法学校の落ちこぼれだが、好奇心旺盛で冒険心がある。',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (_) => _updateProtagonist(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _protagonistMotivationController,
                      decoration: InputDecoration(
                        labelText: '動機',
                        hintText: '例: 失われた力を取り戻し、家族の名誉を回復したい。',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (_) => _updateProtagonist(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _protagonistConflictController,
                      decoration: InputDecoration(
                        labelText: '内的葛藤',
                        hintText: '例: 自分の能力に自信が持てず、重要な場面で躊躇してしまう。',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (_) => _updateProtagonist(),
                    ),
                    SizedBox(height: 24),

                    // AI提案ボタン
                    if (provider.isAIAssistEnabled)
                      Center(
                        child: _isLoadingProtagonist
                            ? CircularProgressIndicator()
                            : ElevatedButton.icon(
                                icon: Icon(Icons.auto_awesome),
                                label: Text('主人公を提案してもらう'),
                                onPressed: _loadProtagonistSuggestion,
                              ),
                      ),
                  ],
                ),
              ),

              // 敵対者タブ
              SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 敵対者入力フォーム
                    TextField(
                      controller: _antagonistNameController,
                      decoration: InputDecoration(
                        labelText: '名前',
                        hintText: '例: 次郎、ダークロード、敵対者名など',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateAntagonist(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _antagonistDescController,
                      decoration: InputDecoration(
                        labelText: '人物像',
                        hintText: '例: 古代魔法を研究する秘密結社のリーダー。冷静沈着で計算高い。',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      onChanged: (_) => _updateAntagonist(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _antagonistMotivationController,
                      decoration: InputDecoration(
                        labelText: '動機',
                        hintText: '例: 古代の禁断の魔法を復活させ、世界を支配したい。',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (_) => _updateAntagonist(),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _antagonistConflictController,
                      decoration: InputDecoration(
                        labelText: '内的葛藤',
                        hintText: '例: 過去のトラウマから他者を信頼できず、孤独に苦しんでいる。',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (_) => _updateAntagonist(),
                    ),
                    SizedBox(height: 24),

                    // AI提案ボタン
                    if (provider.isAIAssistEnabled)
                      Center(
                        child: _isLoadingAntagonist
                            ? CircularProgressIndicator()
                            : ElevatedButton.icon(
                                icon: Icon(Icons.auto_awesome),
                                label: Text('敵対者を提案してもらう'),
                                onPressed: _loadAntagonistSuggestion,
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();

    _protagonistNameController.dispose();
    _protagonistDescController.dispose();
    _protagonistMotivationController.dispose();
    _protagonistConflictController.dispose();

    _antagonistNameController.dispose();
    _antagonistDescController.dispose();
    _antagonistMotivationController.dispose();
    _antagonistConflictController.dispose();

    super.dispose();
  }
}
