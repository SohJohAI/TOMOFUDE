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
    _loadSuggestion();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      _worldSettingController.text = provider.plotBooster.worldSetting;
    });
  }

  Future<void> _loadSuggestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        _worldSettingSuggestion = await _service.suggestWorldSetting(
          provider.plotBooster.genre,
          provider.plotBooster.logline,
          provider.plotBooster.themes,
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);

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
  }

  @override
  void dispose() {
    _worldSettingController.dispose();
    super.dispose();
  }
}
