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
    _loadSuggestions();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      _loglineController.text = provider.plotBooster.logline;
    });
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        _loglineSuggestions = await _service.suggestLoglines(
          provider.plotBooster.genre,
          provider.plotBooster.style,
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
            'ログラインを作成しましょう',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'ログラインとは、物語の要約を一文で表したものです。主人公の目的と障害を簡潔に表現しましょう。',
            style: Theme.of(context).textTheme.bodyMedium,
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
  }

  @override
  void dispose() {
    _loglineController.dispose();
    super.dispose();
  }
}
