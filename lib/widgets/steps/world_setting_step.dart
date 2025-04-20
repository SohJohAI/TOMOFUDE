import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';

class WorldSettingStep extends StatefulWidget {
  @override
  _WorldSettingStepState createState() => _WorldSettingStepState();
}

class _WorldSettingStepState extends State<WorldSettingStep> {
  final TextEditingController _worldSettingController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();

  String _worldSettingSuggestion = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("WorldSettingStep initState called");
    _loadSuggestion();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("WorldSettingStep PostFrameCallback executed");
      try {
        final provider =
            Provider.of<PlotBoosterProvider>(context, listen: false);
        print(
            "Provider in WorldSettingStep PostFrameCallback: ${provider.plotBooster.worldSetting}");
        _worldSettingController.text = provider.plotBooster.worldSetting;
      } catch (e) {
        print("Error in WorldSettingStep PostFrameCallback: $e");
      }
    });
  }

  Future<void> _loadSuggestion() async {
    print("WorldSettingStep _loadSuggestion called");
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      print(
          "Provider in WorldSettingStep _loadSuggestion: AI Assist=${provider.isAIAssistEnabled}, Genre=${provider.plotBooster.genre}, Logline=${provider.plotBooster.logline}, Themes=${provider.plotBooster.themes}");
      if (provider.isAIAssistEnabled) {
        _worldSettingSuggestion = await _service.suggestWorldSetting(
          provider.plotBooster.genre,
          provider.plotBooster.logline,
          provider.plotBooster.themes,
        );
        print(
            "World setting suggestion loaded: ${_worldSettingSuggestion.isNotEmpty}");
      }
    } catch (e) {
      print('WorldSetting提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("WorldSettingStep build method called");

    try {
      final provider = Provider.of<PlotBoosterProvider>(context);
      print(
          "Provider in WorldSettingStep build: ${provider.plotBooster.worldSetting}");

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '世界観を設定しましょう',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              '物語の舞台となる世界の特徴、時代背景、社会制度などを設定します。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),

            // デバッグ情報
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.orange.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("デバッグ情報 (WorldSettingStep):",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Provider: ${provider != null ? '取得済み' : 'null'}"),
                  Text(
                      "World Setting (Provider): ${provider.plotBooster.worldSetting}"),
                  Text("Controller Text: ${_worldSettingController.text}"),
                  Text("AI Assist: ${provider.isAIAssistEnabled}"),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 世界観入力
            TextField(
              controller: _worldSettingController,
              decoration: InputDecoration(
                labelText: '世界観',
                hintText: '例: 魔法と科学が共存する未来世界。古代の魔法文明の遺跡が点在し...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (value) {
                print("WorldSettingStep onChanged: $value");
                provider.updateWorldSetting(value);
              },
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
              ] else if (_worldSettingSuggestion.isEmpty) ...[
                Text('ジャンル、ログライン、テーマを設定すると、世界観の提案が表示されます。')
              ] else ...[
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_worldSettingSuggestion),
                        SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () {
                              print("WorldSettingStep '採用する' button pressed");
                              _worldSettingController.text =
                                  _worldSettingSuggestion;
                              provider
                                  .updateWorldSetting(_worldSettingSuggestion);
                            },
                            child: Text('採用する'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    } catch (e) {
      print("Error in WorldSettingStep build method: $e");
      // エラー時のフォールバック表示
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text("エラーが発生しました: $e"),
            SizedBox(height: 16),
            Text("デバッグ用テキスト: WorldSettingStep is rendering"),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _worldSettingController.dispose();
    super.dispose();
  }
}
