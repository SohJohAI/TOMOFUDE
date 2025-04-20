import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../models/plot_booster.dart';
import '../../utils/ai_helper.dart';

/// STEP 5: キャラクター設定
class Step5CharacterWidget extends StatefulWidget {
  @override
  _Step5CharacterWidgetState createState() => _Step5CharacterWidgetState();
}

class _Step5CharacterWidgetState extends State<Step5CharacterWidget>
    with SingleTickerProviderStateMixin {
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;
  late TabController _tabController;

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

  void _updateProtagonist() {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final character = Character(
      name: _protagonistNameController.text,
      description: _protagonistDescController.text,
      motivation: _protagonistMotivationController.text,
      conflict: _protagonistConflictController.text,
    );
    provider.updateProtagonist(character);
  }

  void _updateAntagonist() {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    final character = Character(
      name: _antagonistNameController.text,
      description: _antagonistDescController.text,
      motivation: _antagonistMotivationController.text,
      conflict: _antagonistConflictController.text,
    );
    provider.updateAntagonist(character);
  }

  void _requestAIHelp() async {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    if (!provider.isAIAssistEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // モックレスポンス
      final aiResponse = '''
## キャラクター設定のアイデア

### 主人公のアイデア
1. **記憶喪失の元暗殺者** - 過去の罪から逃れるために記憶を消したが、その技術を持つ者として再び組織に狙われる。動機：平和な生活を守ること。葛藤：暴力的な過去と平和を望む現在の自分の間で揺れる。

2. **予知能力を持つ少女** - 不幸な出来事を予知できるが、それを変える方法がわからない。動機：愛する人々を守ること。葛藤：予知した未来を変えようとすればするほど、その未来に近づいていく恐怖。

### 敵対者/障害のアイデア
1. **理想主義的な独裁者** - 完璧な社会を作るために極端な手段を取る。動機：理想社会の実現。特徴：自分の行動を完全に正当化し、目的のためには手段を選ばない。

2. **主人公の分身/双子** - 主人公と同じ能力を持つが、正反対の価値観を持つ。動機：主人公の否定と自己証明。特徴：主人公の弱点をすべて知っており、心理的にも攻撃できる。

3. **システム自体** - 社会の仕組みや常識、制度そのものが主人公の障害となる。特徴：個人ではなく、社会全体が無意識に作り出した障壁。
      ''';

      // AIレスポンスをダイアログで表示
      AIHelper.showAIResponse(context, aiResponse);
    } catch (e) {
      // エラーダイアログを表示
      AIHelper.showAIError(context, e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 5：キャラクター設定',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            '物語の主人公と敵対者（または障害）を設定します。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // タブ
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: '主人公'),
              Tab(text: '敵対者/障害'),
            ],
          ),
          SizedBox(height: 16),

          // タブコンテンツ
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                // 主人公タブ
                _buildProtagonistTab(),

                // 敵対者タブ
                _buildAntagonistTab(),
              ],
            ),
          ),

          // AIアシスト
          SizedBox(height: 24),
          Consumer<PlotBoosterProvider>(
            builder: (context, provider, child) {
              if (provider.isAIAssistEnabled) {
                return Column(
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.lightbulb_outline),
                      label: Text('AIに助けを求める'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                      ),
                      onPressed: _isLoading ? null : _requestAIHelp,
                    ),
                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                );
              }
              return SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProtagonistTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _protagonistNameController,
            decoration: InputDecoration(
              labelText: '名前',
              hintText: '例：鈴木太郎',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _updateProtagonist(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _protagonistDescController,
            decoration: InputDecoration(
              labelText: '人物像・特徴',
              hintText: '例：28歳の会社員。真面目で責任感が強いが、自分の感情を表に出すのが苦手。',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _updateProtagonist(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _protagonistMotivationController,
            decoration: InputDecoration(
              labelText: '動機・目標',
              hintText: '例：失踪した妹を見つけ出すこと。',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => _updateProtagonist(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _protagonistConflictController,
            decoration: InputDecoration(
              labelText: '内的葛藤・弱点',
              hintText: '例：過去のトラウマから、人を信じることができない。',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => _updateProtagonist(),
          ),
        ],
      ),
    );
  }

  Widget _buildAntagonistTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _antagonistNameController,
            decoration: InputDecoration(
              labelText: '名前',
              hintText: '例：黒川一郎、または「社会の無関心」など',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _updateAntagonist(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _antagonistDescController,
            decoration: InputDecoration(
              labelText: '人物像・特徴',
              hintText: '例：謎の組織のリーダー。冷静沈着で計算高い。または「情報操作による大衆の無関心」など',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (_) => _updateAntagonist(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _antagonistMotivationController,
            decoration: InputDecoration(
              labelText: '動機・目標',
              hintText: '例：世界を支配すること。または「社会の秩序維持」など',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => _updateAntagonist(),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _antagonistConflictController,
            decoration: InputDecoration(
              labelText: '主人公との対立点',
              hintText: '例：主人公の持つ能力を利用したい。または「主人公の理想と現実社会の壁」など',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (_) => _updateAntagonist(),
          ),
        ],
      ),
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
