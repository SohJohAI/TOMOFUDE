import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../utils/ai_helper.dart';

/// STEP 2: テーマやモチーフの選定
class Step2ThemeWidget extends StatefulWidget {
  @override
  _Step2ThemeWidgetState createState() => _Step2ThemeWidgetState();
}

class _Step2ThemeWidgetState extends State<Step2ThemeWidget> {
  final TextEditingController _customThemeController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();

  List<String> _themeSuggestions = [
    '愛と喪失',
    '成長と変化',
    '正義と復讐',
    '希望と絶望',
    '自由と束縛',
    '孤独と繋がり',
    '過去と未来',
    '真実と嘘',
    '運命と選択',
    '生と死',
    '自然と文明',
    '伝統と革新',
    '理性と感情',
    '秩序と混沌',
    '個人と社会',
  ];
  List<String> _selectedThemes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      _selectedThemes = List.from(provider.plotBooster.themes);
      setState(() {});
    });
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        // 実際の実装ではサービスからテーマ提案を取得
        // _themeSuggestions = await _service.suggestThemes(
        //   provider.plotBooster.genre,
        //   provider.plotBooster.logline,
        // );
      }
    } catch (e) {
      print('提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleTheme(String theme) {
    setState(() {
      if (_selectedThemes.contains(theme)) {
        _selectedThemes.remove(theme);
      } else {
        _selectedThemes.add(theme);
      }

      // プロバイダーを更新
      Provider.of<PlotBoosterProvider>(context, listen: false)
          .updateThemes(_selectedThemes);
    });
  }

  void _addCustomTheme() {
    final theme = _customThemeController.text.trim();
    if (theme.isNotEmpty) {
      setState(() {
        if (!_selectedThemes.contains(theme)) {
          _selectedThemes.add(theme);

          // プロバイダーを更新
          Provider.of<PlotBoosterProvider>(context, listen: false)
              .updateThemes(_selectedThemes);
        }
        _customThemeController.clear();
      });
    }
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
## テーマ・モチーフのアイデア

1. **贖罪と救済** - 過去の罪や過ちからの精神的な回復と自己許容の旅
2. **アイデンティティの探求** - 自分は何者なのか、どこに属するのかという問いへの答え探し
3. **選択と責任** - 決断の重さとその結果に対する責任の取り方
4. **孤独と繋がり** - 人間の根源的な孤独と、それでも誰かと繋がりたいという願望
5. **変化と適応** - 避けられない変化に直面したときの人間の適応力と成長
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
    final provider = Provider.of<PlotBoosterProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 2：テーマやモチーフの選定',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            '物語を通して探求するテーマやモチーフを選びましょう。複数選択可能です。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // テーマ選択
          Text(
            '一般的なテーマ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _themeSuggestions.map((theme) {
              final isSelected = _selectedThemes.contains(theme);
              return FilterChip(
                label: Text(theme),
                selected: isSelected,
                onSelected: (_) => _toggleTheme(theme),
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                selectedColor: isDark ? Colors.amber[700] : Colors.blue[100],
                checkmarkColor: isDark ? Colors.black : Colors.blue[800],
              );
            }).toList(),
          ),

          // カスタムテーマ追加
          SizedBox(height: 24),
          Text(
            'カスタムテーマを追加',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customThemeController,
                  decoration: InputDecoration(
                    hintText: '例：信頼と裏切り、科学と魔法の融合など',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCustomTheme,
                child: Text('追加'),
              ),
            ],
          ),

          // 選択したテーマ
          if (_selectedThemes.isNotEmpty) ...[
            SizedBox(height: 24),
            Text(
              '選択したテーマ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedThemes.map((theme) {
                return Chip(
                  label: Text(theme),
                  onDeleted: () => _toggleTheme(theme),
                  deleteIcon: Icon(Icons.close, size: 18),
                  backgroundColor:
                      isDark ? Colors.amber[700] : Colors.blue[100],
                  labelStyle: TextStyle(
                    color: isDark ? Colors.black : Colors.blue[800],
                  ),
                );
              }).toList(),
            ),
          ],

          // AIアシスト - 条件付きレンダリングを修正
          SizedBox(height: 24),
          // AIアシストボタンを常に表示（無効化はするが非表示にはしない）
          ElevatedButton.icon(
            icon: Icon(Icons.lightbulb_outline),
            label: Text('AIに助けを求める'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              // ボタンが見えるように最小サイズを設定
              minimumSize: Size(200, 48),
            ),
            onPressed: (_isLoading || !provider.isAIAssistEnabled)
                ? null
                : _requestAIHelp,
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          // AIアシストが無効の場合のメッセージ
          if (!provider.isAIAssistEnabled)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'AIアシストは現在無効です。有効にするには画面上部のスイッチをオンにしてください。',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customThemeController.dispose();
    super.dispose();
  }
}
