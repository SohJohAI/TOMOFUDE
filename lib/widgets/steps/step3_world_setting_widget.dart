import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../utils/ai_helper.dart';

/// STEP 3: 世界観設定
class Step3WorldSettingWidget extends StatefulWidget {
  const Step3WorldSettingWidget({super.key});

  @override
  _Step3WorldSettingWidgetState createState() =>
      _Step3WorldSettingWidgetState();
}

class _Step3WorldSettingWidgetState extends State<Step3WorldSettingWidget> {
  final TextEditingController _worldSettingController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      _worldSettingController.text = provider.plotBooster.worldSetting;
    });
  }

  void _requestAIHelp() async {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    if (!provider.isAIAssistEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // モックレスポンス
      const aiResponse = '''
## 世界観設定のアイデア

1. **失われた文明の遺跡が点在する未来世界** - 高度な科学技術と古代の魔法が融合した世界。巨大な浮遊都市と荒廃した地上の対比。

2. **記憶を通貨として使う社会** - 人々は自分の記憶を売買し、価値ある記憶ほど高価格で取引される。記憶を失った者は社会的地位を失う。

3. **季節が数十年単位で変わる惑星** - 一つの季節が何十年も続き、世代を超えて冬を経験したことのない人々も存在する。季節の変わり目は大きな社会変動をもたらす。

4. **感情が目に見える形で現れる世界** - 人々の感情は色彩豊かなオーラとして視覚化され、感情を隠すことは不可能。感情の制御が社会的ステータスとなる。

5. **夢と現実の境界が曖昧な世界** - 夢の中で経験したことが現実に影響を与え、夢の中での行動が法的責任を問われることもある。夢を操る能力を持つ者は強大な力を持つ。
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 3：世界観設定',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '物語の舞台となる世界の特徴や法則、歴史などを設定します。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // 世界観設定入力 - 明示的な高さを設定
          Container(
            constraints: const BoxConstraints(minHeight: 200),
            child: TextField(
              controller: _worldSettingController,
              decoration: InputDecoration(
                labelText: '世界観設定',
                hintText: '例：魔法が日常的に使われる中世ファンタジー世界。魔法の才能は生まれつき決まっており...',
                border: const OutlineInputBorder(),
                // 入力欄が見えるようにフィルカラーを設定
                filled: true,
                fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                    (Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200]),
              ),
              maxLines: 8,
              onChanged: (value) {
                provider.updateWorldSetting(value);
              },
            ),
          ),

          // AIアシスト - 条件付きレンダリングを修正
          const SizedBox(height: 24),
          // AIアシストボタンを常に表示（無効化はするが非表示にはしない）
          ElevatedButton.icon(
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('AIに助けを求める'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              // ボタンが見えるように最小サイズを設定
              minimumSize: const Size(200, 48),
            ),
            onPressed: (_isLoading || !provider.isAIAssistEnabled)
                ? null
                : _requestAIHelp,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          // AIアシストが無効の場合のメッセージ
          if (!provider.isAIAssistEnabled)
            const Padding(
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
    _worldSettingController.dispose();
    super.dispose();
  }
}
