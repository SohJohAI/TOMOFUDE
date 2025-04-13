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
        _themeSuggestions = await _service.suggestThemes(
          provider.plotBooster.genre,
          provider.plotBooster.logline,
        );
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);

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
  }

  @override
  void dispose() {
    _customThemeController.dispose();
    super.dispose();
  }
}
