import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../models/plot_booster.dart';

/// STEP 4: キー設定
class Step4KeySettingWidget extends StatefulWidget {
  @override
  _Step4KeySettingWidgetState createState() => _Step4KeySettingWidgetState();
}

class _Step4KeySettingWidgetState extends State<Step4KeySettingWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _effectController = TextEditingController();
  final TextEditingController _limitationController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();
  bool _isLoading = false;
  int _editingIndex = -1;

  @override
  void initState() {
    super.initState();
  }

  void _addKeySettings() {
    final name = _nameController.text.trim();
    final effect = _effectController.text.trim();
    final limitation = _limitationController.text.trim();

    if (name.isNotEmpty) {
      final keySetting = KeySetting(
        name: name,
        effect: effect,
        limitation: limitation,
      );

      if (_editingIndex >= 0) {
        Provider.of<PlotBoosterProvider>(context, listen: false)
            .updateKeySettings(_editingIndex, keySetting);
      } else {
        Provider.of<PlotBoosterProvider>(context, listen: false)
            .addKeySettings(keySetting);
      }

      _nameController.clear();
      _effectController.clear();
      _limitationController.clear();
      setState(() {
        _editingIndex = -1;
      });
    }
  }

  void _editKeySettings(int index, KeySetting setting) {
    setState(() {
      _editingIndex = index;
      _nameController.text = setting.name;
      _effectController.text = setting.effect;
      _limitationController.text = setting.limitation;
    });
  }

  void _removeKeySettings(int index) {
    Provider.of<PlotBoosterProvider>(context, listen: false)
        .removeKeySettings(index);
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
## キー設定のアイデア

1. **古代の予言書** - 主人公だけが解読できる謎の予言書。その内容が物語の展開を予告し、同時に主人公の運命を暗示する。

2. **記憶を映し出す鏡** - 触れた者の忘れた記憶や抑圧した過去を映し出す魔法の鏡。真実を知ることの恐怖と必要性のジレンマを生む。

3. **時を止める懐中時計** - 限られた時間だけ世界の時を止められる不思議な時計。使うたびに持ち主の寿命が縮むという代償がある。

4. **感情を吸収する宝石** - 周囲の人々の感情を吸収し、持ち主に力を与える宝石。しかし強い感情ほど持ち主の精神を蝕む危険性がある。

5. **二つの世界を繋ぐ扉** - 現実世界と幻想世界を行き来できる扉。どちらの世界で起きたことがもう一方の世界に影響を与える。
      ''';

      // AIレスポンスをダイアログで表示
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('AIアシスト'),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Markdown(
                data: aiResponse,
                shrinkWrap: true,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('閉じる'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AIアシストの取得に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);
    final keySettings = provider.plotBooster.keySettings;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STEP 4：キー設定',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            '物語の鍵となる重要な設定（アイテム、場所、イベントなど）を決めます。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 16),

          // キー設定入力フォーム
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingIndex >= 0 ? 'キー設定を編集' : 'キー設定を追加',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: '名前',
                      hintText: '例：古代の予言書、記憶を映し出す鏡など',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _effectController,
                    decoration: InputDecoration(
                      labelText: '効果・役割',
                      hintText: '例：触れた者の記憶を映し出す',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: _limitationController,
                    decoration: InputDecoration(
                      labelText: '制限・代償',
                      hintText: '例：真実を知ることの恐怖と必要性のジレンマを生む',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_editingIndex >= 0)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _editingIndex = -1;
                              _nameController.clear();
                              _effectController.clear();
                              _limitationController.clear();
                            });
                          },
                          child: Text('キャンセル'),
                        ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addKeySettings,
                        child: Text(_editingIndex >= 0 ? '更新' : '追加'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 追加されたキー設定のリスト
          if (keySettings.isNotEmpty) ...[
            SizedBox(height: 24),
            Text(
              '追加したキー設定',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: keySettings.length,
              itemBuilder: (context, index) {
                final setting = keySettings[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(setting.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (setting.effect.isNotEmpty)
                          Text('効果: ${setting.effect}'),
                        if (setting.limitation.isNotEmpty)
                          Text('制限: ${setting.limitation}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editKeySettings(index, setting),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _removeKeySettings(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],

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
    _nameController.dispose();
    _effectController.dispose();
    _limitationController.dispose();
    super.dispose();
  }
}
