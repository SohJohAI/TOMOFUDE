import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../utils/ai_helper.dart';

/// STEP 1: ログライン（物語の要約）の作成
class Step1LoglineWidget extends StatefulWidget {
  @override
  _Step1LoglineWidgetState createState() => _Step1LoglineWidgetState();
}

class _Step1LoglineWidgetState extends State<Step1LoglineWidget> {
  final TextEditingController _loglineController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      _loglineController.text = provider.plotBooster.logline;
    });
  }

  void _requestAIHelp() async {
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    if (!provider.isAIAssistEnabled) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // ここでClaudeAPIを使用してAIアシストを取得する
      final genre = provider.plotBooster.genre;
      final style = provider.plotBooster.style;

      // モックレスポンス
      final aiResponse = '''
## ログラインのアイデア

1. 「記憶を失った元暗殺者が、自分の過去と向き合いながら、かつての組織から家族を守るために戦う。」
2. 「不思議な能力を持つ少女が、差別と偏見に満ちた世界で、自分の居場所と真の仲間を見つける旅に出る。」
3. 「死んだはずの双子の兄から届いた手紙をきっかけに、妹は兄の失踪の真相を追う中で家族の隠された秘密に迫る。」
4. 「人工知能に支配された未来世界で、最後の人類レジスタンスのリーダーが、機械と人間の共存の道を模索する。」
5. 「古い屋敷を相続した作家が、そこに住む幽霊たちの未解決の物語を書き上げることで、彼らを成仏させようとする。」
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
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 1：ログライン（物語の要約）の作成',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            '主人公の目的と、それを阻む障害を簡潔に一文で表現します。\n例：「復讐のために帝国を滅ぼそうとする少女が、仲間との絆に揺れる。」',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // ログライン入力
          TextField(
            controller: _loglineController,
            decoration: InputDecoration(
              labelText: 'ログライン',
              hintText: '例：復讐のために帝国を滅ぼそうとする少女が、仲間との絆に揺れる。',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            onChanged: (value) {
              provider.updateLogline(value);
            },
          ),

          // AIアシスト
          SizedBox(height: 24),
          if (provider.isAIAssistEnabled) ...[
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _loglineController.dispose();
    super.dispose();
  }
}
