import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';

class LoglineStep extends StatefulWidget {
  @override
  _LoglineStepState createState() => _LoglineStepState();
}

class _LoglineStepState extends State<LoglineStep> {
  final TextEditingController _loglineController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();

  List<String> _loglineSuggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("LoglineStep initState called");
    _loadSuggestions();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("LoglineStep PostFrameCallback executed");
      try {
        final provider =
            Provider.of<PlotBoosterProvider>(context, listen: false);
        print(
            "Provider in LoglineStep PostFrameCallback: ${provider.plotBooster.logline}");
        _loglineController.text = provider.plotBooster.logline;
      } catch (e) {
        print("Error in LoglineStep PostFrameCallback: $e");
      }
    });
  }

  Future<void> _loadSuggestions() async {
    print("LoglineStep _loadSuggestions called");
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      print(
          "Provider in LoglineStep _loadSuggestions: AI Assist=${provider.isAIAssistEnabled}, Genre=${provider.plotBooster.genre}, Style=${provider.plotBooster.style}");
      if (provider.isAIAssistEnabled) {
        _loglineSuggestions = await _service.suggestLoglines(
          provider.plotBooster.genre,
          provider.plotBooster.style,
        );
        print("Logline suggestions loaded: ${_loglineSuggestions.length}");
      }
    } catch (e) {
      print('Logline提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print("LoglineStep build method called");

    try {
      final provider = Provider.of<PlotBoosterProvider>(context);
      print("Provider in LoglineStep build: ${provider.plotBooster.logline}");

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ログラインを作成しましょう',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'ログラインとは、物語の要約を一文で表したものです。主人公の目的と障害を簡潔に表現しましょう。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),

            // デバッグ情報
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.lightBlue.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("デバッグ情報 (LoglineStep):",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Provider: ${provider != null ? '取得済み' : 'null'}"),
                  Text("Logline: ${provider.plotBooster.logline}"),
                  Text("Controller Text: ${_loglineController.text}"),
                  Text("AI Assist: ${provider.isAIAssistEnabled}"),
                ],
              ),
            ),
            SizedBox(height: 16),

            // ログライン入力
            TextField(
              controller: _loglineController,
              decoration: InputDecoration(
                labelText: 'ログライン',
                hintText: '例: 魔法の力を失った少年が、古代の遺跡で見つけた謎の石を通じて失われた力を取り戻す冒険に出る。',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                provider.updateLogline(value);
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
              ] else if (_loglineSuggestions.isEmpty) ...[
                Text('ジャンルと作風を設定すると、ログラインの提案が表示されます。')
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _loglineSuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _loglineSuggestions[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(suggestion),
                        trailing: IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            _loglineController.text = suggestion;
                            provider.updateLogline(suggestion);
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      );
    } catch (e) {
      print("Error in LoglineStep build method: $e");
      // エラー時のフォールバック表示
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text("エラーが発生しました: $e"),
            SizedBox(height: 16),
            Text("デバッグ用テキスト: LoglineStep is rendering"),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _loglineController.dispose();
    super.dispose();
  }
}
