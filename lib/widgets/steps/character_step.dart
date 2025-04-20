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
    print("CharacterStep initState called");
    _tabController = TabController(length: 2, vsync: this);

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("CharacterStep PostFrameCallback executed");
      try {
        final provider =
            Provider.of<PlotBoosterProvider>(context, listen: false);
        print(
            "Provider in CharacterStep PostFrameCallback: Protagonist=${provider.plotBooster.protagonist.name}, Antagonist=${provider.plotBooster.antagonist.name}");

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
      } catch (e) {
        print("Error in CharacterStep PostFrameCallback: $e");
      }
    });
  }

  Future<void> _loadProtagonistSuggestion() async {
    print("CharacterStep _loadProtagonistSuggestion called");
    setState(() {
      _isLoadingProtagonist = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      print(
          "Provider in _loadProtagonistSuggestion: AI Assist=${provider.isAIAssistEnabled}, Logline=${provider.plotBooster.logline}, Themes=${provider.plotBooster.themes}");
      if (provider.isAIAssistEnabled) {
        final suggestion = await _service.suggestProtagonist(
          provider.plotBooster.logline,
          provider.plotBooster.themes,
        );
        print("Protagonist suggestion loaded: ${suggestion.name}");

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
      print('Protagonist提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoadingProtagonist = false;
      });
    }
  }

  Future<void> _loadAntagonistSuggestion() async {
    print("CharacterStep _loadAntagonistSuggestion called");
    setState(() {
      _isLoadingAntagonist = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      print(
          "Provider in _loadAntagonistSuggestion: AI Assist=${provider.isAIAssistEnabled}, Logline=${provider.plotBooster.logline}, Protagonist=${provider.plotBooster.protagonist.name}");
      if (provider.isAIAssistEnabled) {
        // Use current state from provider for protagonist context
        final protagonist = provider.plotBooster.protagonist;

        final suggestion = await _service.suggestAntagonist(
          provider.plotBooster.logline,
          protagonist,
        );
        print("Antagonist suggestion loaded: ${suggestion.name}");

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
      print('Antagonist提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoadingAntagonist = false;
      });
    }
  }

  void _updateProtagonist() {
    print("CharacterStep _updateProtagonist called");
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final protagonist = Character(
      name: _protagonistNameController.text,
      description: _protagonistDescController.text,
      motivation: _protagonistMotivationController.text,
      conflict: _protagonistConflictController.text,
    );
    print("Updating protagonist in provider: ${protagonist.name}");
    provider.updateProtagonist(protagonist);
  }

  void _updateAntagonist() {
    print("CharacterStep _updateAntagonist called");
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final antagonist = Character(
      name: _antagonistNameController.text,
      description: _antagonistDescController.text,
      motivation: _antagonistMotivationController.text,
      conflict: _antagonistConflictController.text,
    );
    print("Updating antagonist in provider: ${antagonist.name}");
    provider.updateAntagonist(antagonist);
  }

  @override
  Widget build(BuildContext context) {
    print("CharacterStep build method called");

    try {
      final provider = Provider.of<PlotBoosterProvider>(context);
      print(
          "Provider in CharacterStep build: Protagonist=${provider.plotBooster.protagonist.name}, Antagonist=${provider.plotBooster.antagonist.name}");

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
                SizedBox(height: 8),
                // デバッグ情報
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.red.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("デバッグ情報 (CharacterStep):",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text("Provider: ${provider != null ? '取得済み' : 'null'}"),
                      Text(
                          "Protagonist (Provider): ${provider.plotBooster.protagonist.name}"),
                      Text(
                          "Antagonist (Provider): ${provider.plotBooster.antagonist.name}"),
                      Text("AI Assist: ${provider.isAIAssistEnabled}"),
                    ],
                  ),
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
                _buildCharacterForm(
                  context: context,
                  nameController: _protagonistNameController,
                  descController: _protagonistDescController,
                  motivationController: _protagonistMotivationController,
                  conflictController: _protagonistConflictController,
                  updateCharacter: _updateProtagonist,
                  loadSuggestion: _loadProtagonistSuggestion,
                  isLoading: _isLoadingProtagonist,
                  characterType: '主人公',
                  provider: provider,
                ),

                // 敵対者タブ
                _buildCharacterForm(
                  context: context,
                  nameController: _antagonistNameController,
                  descController: _antagonistDescController,
                  motivationController: _antagonistMotivationController,
                  conflictController: _antagonistConflictController,
                  updateCharacter: _updateAntagonist,
                  loadSuggestion: _loadAntagonistSuggestion,
                  isLoading: _isLoadingAntagonist,
                  characterType: '敵対者',
                  provider: provider,
                ),
              ],
            ),
          ),
        ],
      );
    } catch (e) {
      print("Error in CharacterStep build method: $e");
      // エラー時のフォールバック表示
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text("エラーが発生しました: $e"),
            SizedBox(height: 16),
            Text("デバッグ用テキスト: CharacterStep is rendering"),
          ],
        ),
      );
    }
  }

  // Helper method to build character form
  Widget _buildCharacterForm({
    required BuildContext context,
    required TextEditingController nameController,
    required TextEditingController descController,
    required TextEditingController motivationController,
    required TextEditingController conflictController,
    required VoidCallback updateCharacter,
    required Future<void> Function() loadSuggestion,
    required bool isLoading,
    required String characterType,
    required PlotBoosterProvider provider,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: '名前',
              hintText: '例: 太郎、アリス、$characterType名など',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => updateCharacter(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: descController,
            decoration: InputDecoration(
              labelText: '人物像',
              hintText: '例: 18歳の少年。魔法学校の落ちこぼれだが...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => updateCharacter(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: motivationController,
            decoration: InputDecoration(
              labelText: '動機',
              hintText: '例: 失われた力を取り戻し...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => updateCharacter(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: conflictController,
            decoration: InputDecoration(
              labelText: '内的葛藤',
              hintText: '例: 自分の能力に自信が持てず...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => updateCharacter(),
          ),
          SizedBox(height: 24),
          if (provider.isAIAssistEnabled)
            Center(
              child: isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: Icon(Icons.auto_awesome),
                      label: Text('$characterTypeを提案してもらう'),
                      onPressed: loadSuggestion,
                    ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    print("CharacterStep dispose called");
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
