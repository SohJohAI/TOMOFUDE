import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../models/plot_booster.dart';

class KeySettingStep extends StatefulWidget {
  @override
  _KeySettingStepState createState() => _KeySettingStepState();
}

class _KeySettingStepState extends State<KeySettingStep> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _effectController = TextEditingController();
  final TextEditingController _limitationController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();

  List<KeySetting> _keySuggestions = [];
  bool _isLoading = false;
  int? _editingIndex;

  @override
  void initState() {
    super.initState();
    print("KeySettingStep initState called");
    _loadSuggestions();
    // Note: No PostFrameCallback needed here as state is managed via provider updates
  }

  Future<void> _loadSuggestions() async {
    print("KeySettingStep _loadSuggestions called");
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      print(
          "Provider in KeySettingStep _loadSuggestions: AI Assist=${provider.isAIAssistEnabled}, Genre=${provider.plotBooster.genre}, WorldSetting=${provider.plotBooster.worldSetting}");
      if (provider.isAIAssistEnabled) {
        _keySuggestions = await _service.suggestKeySettings(
          provider.plotBooster.genre,
          provider.plotBooster.worldSetting,
        );
        print("Key setting suggestions loaded: ${_keySuggestions.length}");
      }
    } catch (e) {
      print('KeySetting提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addKeySetting() {
    final name = _nameController.text.trim();
    final effect = _effectController.text.trim();
    final limitation = _limitationController.text.trim();
    print(
        "KeySettingStep _addKeySetting called: Name=$name, Effect=$effect, Limitation=$limitation, EditingIndex=$_editingIndex");

    if (name.isNotEmpty && effect.isNotEmpty) {
      final setting = KeySetting(
        name: name,
        effect: effect,
        limitation: limitation,
      );

      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);

      if (_editingIndex != null) {
        // 既存の設定を更新
        print("Updating key setting at index $_editingIndex");
        provider.updateKeySettings(_editingIndex!, setting);
        _editingIndex = null;
      } else {
        // 新しい設定を追加
        print("Adding new key setting");
        provider.addKeySettings(setting);
      }

      // フォームをクリア
      _nameController.clear();
      _effectController.clear();
      _limitationController.clear();

      // setState(() {}); // Provider listener should handle UI updates
    } else {
      print("Key setting not added: Name or Effect is empty");
    }
  }

  void _editKeySetting(int index, KeySetting setting) {
    print(
        "KeySettingStep _editKeySetting called for index $index: ${setting.name}");
    setState(() {
      _editingIndex = index;
      _nameController.text = setting.name;
      _effectController.text = setting.effect;
      _limitationController.text = setting.limitation;
    });
  }

  void _removeKeySetting(int index) {
    print("KeySettingStep _removeKeySetting called for index $index");
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    provider.removeKeySettings(index);
    // setState(() {}); // Provider listener should handle UI updates
  }

  void _adoptSuggestion(KeySetting suggestion) {
    print("KeySettingStep _adoptSuggestion called: ${suggestion.name}");
    final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
    provider.addKeySettings(suggestion);
    // setState(() {}); // Provider listener should handle UI updates
  }

  @override
  Widget build(BuildContext context) {
    print("KeySettingStep build method called");

    try {
      final provider = Provider.of<PlotBoosterProvider>(context);
      final keySettings = provider.plotBooster.keySettings;
      print(
          "Provider in KeySettingStep build: KeySettings count=${keySettings.length}");

      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'キー設定を構築しましょう',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),
            Text(
              'キー設定とは、物語世界の独自の仕組みや特殊能力などの設定です。',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8),

            // デバッグ情報
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.purple.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("デバッグ情報 (KeySettingStep):",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Provider: ${provider != null ? '取得済み' : 'null'}"),
                  Text("Key Settings (Provider): ${keySettings.length} items"),
                  Text("Editing Index: $_editingIndex"),
                  Text("AI Assist: ${provider.isAIAssistEnabled}"),
                ],
              ),
            ),
            SizedBox(height: 16),

            // 設定入力フォーム
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingIndex != null ? '設定を編集' : '新しい設定を追加',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '名前',
                        hintText: '例: 魔法の石、記憶転写能力など',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _effectController,
                      decoration: InputDecoration(
                        labelText: '効果',
                        hintText: '例: 持ち主に特殊な能力を与える',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _limitationController,
                      decoration: InputDecoration(
                        labelText: '制約・限界（任意）',
                        hintText: '例: 使用するたびに持ち主の寿命が縮む',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (_editingIndex != null)
                          TextButton(
                            onPressed: () {
                              print("KeySettingStep Cancel edit pressed");
                              setState(() {
                                _editingIndex = null;
                                _nameController.clear();
                                _effectController.clear();
                                _limitationController.clear();
                              });
                            },
                            child: Text('キャンセル'),
                          ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addKeySetting,
                          child: Text(_editingIndex != null ? '更新' : '追加'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // 既存の設定リスト
            if (keySettings.isNotEmpty) ...[
              Text(
                '設定一覧',
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
                          Text('効果: ${setting.effect}'),
                          if (setting.limitation.isNotEmpty)
                            Text('制約: ${setting.limitation}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editKeySetting(index, setting),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeKeySetting(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
            ],

            // AI提案セクション
            if (provider.isAIAssistEnabled) ...[
              Text(
                'AI提案',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              if (_isLoading) ...[
                Center(child: CircularProgressIndicator())
              ] else if (_keySuggestions.isEmpty) ...[
                Text('ジャンルと世界観を設定すると、キー設定の提案が表示されます。')
              ] else ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _keySuggestions.length,
                  itemBuilder: (context, index) {
                    final suggestion = _keySuggestions[index];
                    // 既に追加済みかチェック
                    final isAdded =
                        keySettings.any((s) => s.name == suggestion.name);

                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(suggestion.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('効果: ${suggestion.effect}'),
                            if (suggestion.limitation.isNotEmpty)
                              Text('制約: ${suggestion.limitation}'),
                          ],
                        ),
                        trailing: isAdded
                            ? Icon(Icons.check, color: Colors.green)
                            : IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () => _adoptSuggestion(suggestion),
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
      print("Error in KeySettingStep build method: $e");
      // エラー時のフォールバック表示
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text("エラーが発生しました: $e"),
            SizedBox(height: 16),
            Text("デバッグ用テキスト: KeySettingStep is rendering"),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    print("KeySettingStep dispose called");
    _nameController.dispose();
    _effectController.dispose();
    _limitationController.dispose();
    super.dispose();
  }
}
