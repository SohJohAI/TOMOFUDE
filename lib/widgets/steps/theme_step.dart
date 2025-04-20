import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';

class ThemeStep extends StatefulWidget {
  @override
  _ThemeStepState createState() => _ThemeStepState();
}

class _ThemeStepState extends State<ThemeStep> {
  final TextEditingController _customThemeController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();

  List<String> _themeSuggestions = [];
  List<String> _selectedThemes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("ThemeStep initState called");
    _loadSuggestions();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("ThemeStep PostFrameCallback executed");
      try {
        final provider =
            Provider.of<PlotBoosterProvider>(context, listen: false);
        print(
            "Provider in ThemeStep PostFrameCallback: ${provider.plotBooster.themes}");
        _selectedThemes = List.from(provider.plotBooster.themes);
        setState(() {}); // Ensure UI updates if themes are loaded from provider
      } catch (e) {
        print("Error in ThemeStep PostFrameCallback: $e");
      }
    });
  }

  Future<void> _loadSuggestions() async {
    print("ThemeStep _loadSuggestions called");
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      print(
          "Provider in ThemeStep _loadSuggestions: AI Assist=${provider.isAIAssistEnabled}, Genre=${provider.plotBooster.genre}, Logline=${provider.plotBooster.logline}");
      if (provider.isAIAssistEnabled) {
        _themeSuggestions = await _service.suggestThemes(
          provider.plotBooster.genre,
          provider.plotBooster.logline,
        );
        print("Theme suggestions loaded: ${_themeSuggestions.length}");
      }
    } catch (e) {
      print('Theme提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleTheme(String theme) {
    print("ThemeStep _toggleTheme called with: $theme");
    setState(() {
      if (_selectedThemes.contains(theme)) {
        _selectedThemes.remove(theme);
      } else {
        _selectedThemes.add(theme);
      }

      // プロバイダーを更新
      Provider.of<PlotBoosterProvider>(context, listen: false)
          .updateThemes(_selectedThemes);
      print("Provider updated with themes: $_selectedThemes");
    });
  }

  void _addCustomTheme() {
    final theme = _customThemeController.text.trim();
    print("ThemeStep _addCustomTheme called with: $theme");
    if (theme.isNotEmpty) {
      setState(() {
        if (!_selectedThemes.contains(theme)) {
          _selectedThemes.add(theme);

          // プロバイダーを更新
          Provider.of<PlotBoosterProvider>(context, listen: false)
              .updateThemes(_selectedThemes);
          print("Provider updated with themes: $_selectedThemes");
        }
        _customThemeController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("ThemeStep build method called");

    try {
      final provider = Provider.of<PlotBoosterProvider>(context);
      print("Provider in ThemeStep build: ${provider.plotBooster.themes}");

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'テーマやモチーフを選びましょう',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'テーマは物語の根底にある概念や思想です。複数選択することもできます。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),

            // デバッグ情報
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.green.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("デバッグ情報 (ThemeStep):",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Provider: ${provider != null ? '取得済み' : 'null'}"),
                  Text("Selected Themes (State): $_selectedThemes"),
                  Text(
                      "Selected Themes (Provider): ${provider.plotBooster.themes}"),
                  Text("AI Assist: ${provider.isAIAssistEnabled}"),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 選択されたテーマの表示
            if (_selectedThemes.isNotEmpty) ...[
              Text(
                '選択したテーマ:',
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
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
            ],

            // カスタムテーマの追加
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customThemeController,
                    decoration: InputDecoration(
                      labelText: 'カスタムテーマを追加',
                      hintText: '例: 友情、裏切り、成長など',
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
            SizedBox(height: 24),

            // AI提案セクション
            if (provider.isAIAssistEnabled) ...[
              Text(
                'AI提案',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              if (_isLoading) ...[
                Center(child: CircularProgressIndicator())
              ] else if (_themeSuggestions.isEmpty) ...[
                Text('ジャンルとログラインを設定すると、テーマの提案が表示されます。')
              ] else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _themeSuggestions.map((theme) {
                    final isSelected = _selectedThemes.contains(theme);
                    return FilterChip(
                      label: Text(theme),
                      selected: isSelected,
                      onSelected: (_) => _toggleTheme(theme),
                      backgroundColor: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : null,
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      );
    } catch (e) {
      print("Error in ThemeStep build method: $e");
      // エラー時のフォールバック表示
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text("エラーが発生しました: $e"),
            SizedBox(height: 16),
            Text("デバッグ用テキスト: ThemeStep is rendering"),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _customThemeController.dispose();
    super.dispose();
  }
}
