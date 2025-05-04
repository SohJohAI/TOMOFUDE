import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';
import '../../utils/ai_helper.dart';

/// STEP 0: ジャンルと作風の決定
class Step0GenreStyleWidget extends StatefulWidget {
  const Step0GenreStyleWidget({super.key});

  @override
  _Step0GenreStyleWidgetState createState() => _Step0GenreStyleWidgetState();
}

class _Step0GenreStyleWidgetState extends State<Step0GenreStyleWidget> {
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();

  List<String> _genreSuggestions = [];
  List<String> _styleSuggestions = [];
  bool _isLoading = false;
  bool _showCustomGenre = false;
  bool _showCustomStyle = false;
  bool _showOtherGenreStyle = false;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      _genreController.text = provider.plotBooster.genre;
      _styleController.text = provider.plotBooster.style;
    });
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      if (provider.isAIAssistEnabled) {
        _genreSuggestions = await _service.suggestGenres();
        _styleSuggestions = await _service.suggestStyles();
      }
    } catch (e) {
      print('提案の読み込みエラー: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleCustomGenre(String? value) {
    setState(() {
      _showCustomGenre = value == 'フリー入力';
      _showOtherGenreStyle = value == 'その他' || _styleController.text == 'その他';
    });
  }

  void _toggleCustomStyle(String? value) {
    setState(() {
      _showCustomStyle = value == 'フリー入力';
      _showOtherGenreStyle = value == 'その他' || _genreController.text == 'その他';
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
      // 実際の実装ではClaudeAIServiceを使用
      await Future.delayed(const Duration(seconds: 1)); // モック遅延

      // モックレスポンス
      const aiResponse = '''
## ジャンルと作風のアイデア

1. **ダークファンタジー × 哲学的** - 魔法と神話が存在する世界で、存在の意味や道徳的ジレンマを探求
2. **近未来SF × サスペンス** - テクノロジーが発達した社会での陰謀と真実の追求
3. **歴史 × ミステリー** - 実際の歴史的出来事を背景にした謎解き
4. **現代ドラマ × 叙情的** - 日常の中の小さな感動と人間関係の機微を描く
5. **異世界ファンタジー × コメディ** - 異世界転生や召喚を題材にしたユーモラスな冒険
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
            'STEP 0：ジャンルと作風の決定',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            '小説のジャンルと雰囲気を選んで、物語の方向性を決めましょう。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // ジャンルと作風の入力フォーム
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ジャンル', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _genreController.text.isEmpty
                          ? null
                          : _genreController.text,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '選択してください',
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'ファンタジー', child: Text('ファンタジー')),
                        DropdownMenuItem(value: 'SF', child: Text('SF')),
                        DropdownMenuItem(value: '現代ドラマ', child: Text('現代ドラマ')),
                        DropdownMenuItem(value: 'ミステリー', child: Text('ミステリー')),
                        DropdownMenuItem(value: 'ホラー', child: Text('ホラー')),
                        DropdownMenuItem(value: '恋愛', child: Text('恋愛')),
                        DropdownMenuItem(value: '歴史', child: Text('歴史')),
                        DropdownMenuItem(
                            value: 'アクション・冒険', child: Text('アクション・冒険')),
                        DropdownMenuItem(value: '青春', child: Text('青春')),
                        DropdownMenuItem(value: 'その他', child: Text('その他')),
                        DropdownMenuItem(value: 'フリー入力', child: Text('フリー入力')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _genreController.text = value;
                          provider.updateGenre(value);
                          _toggleCustomGenre(value);
                        }
                      },
                    ),
                    if (_showCustomGenre) ...[
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'ジャンルを自由に入力',
                        ),
                        onChanged: (value) {
                          provider.updateGenre(value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('作風・雰囲気',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _styleController.text.isEmpty
                          ? null
                          : _styleController.text,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '選択してください',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'ダーク', child: Text('ダーク')),
                        DropdownMenuItem(value: 'コメディ', child: Text('コメディ')),
                        DropdownMenuItem(value: 'シリアス', child: Text('シリアス')),
                        DropdownMenuItem(value: '青春', child: Text('青春')),
                        DropdownMenuItem(value: 'メルヘン', child: Text('メルヘン')),
                        DropdownMenuItem(value: 'バトル', child: Text('バトル')),
                        DropdownMenuItem(value: '哲学的', child: Text('哲学的')),
                        DropdownMenuItem(value: '叙情的', child: Text('叙情的')),
                        DropdownMenuItem(value: 'サスペンス', child: Text('サスペンス')),
                        DropdownMenuItem(value: 'アクション', child: Text('アクション')),
                        DropdownMenuItem(value: 'その他', child: Text('その他')),
                        DropdownMenuItem(value: 'フリー入力', child: Text('フリー入力')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _styleController.text = value;
                          provider.updateStyle(value);
                          _toggleCustomStyle(value);
                        }
                      },
                    ),
                    if (_showCustomStyle) ...[
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '作風・雰囲気を自由に入力',
                        ),
                        onChanged: (value) {
                          provider.updateStyle(value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // その他のジャンル・作風
          if (_showOtherGenreStyle) ...[
            const SizedBox(height: 16),
            const Text('その他のジャンル・作風を入力',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '例：異世界転生ファンタジー、アンティーク要素のある日常系ミステリーなど',
              ),
              onChanged: (value) {
                if (_genreController.text == 'その他') {
                  provider.updateGenre(value);
                }
                if (_styleController.text == 'その他') {
                  provider.updateStyle(value);
                }
              },
            ),
          ],

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
    _genreController.dispose();
    _styleController.dispose();
    super.dispose();
  }
}
