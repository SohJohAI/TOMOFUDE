import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/plot_booster_provider.dart';
import '../../services/plot_booster_service.dart';

class GenreStyleStep extends StatefulWidget {
  @override
  _GenreStyleStepState createState() => _GenreStyleStepState();
}

class _GenreStyleStepState extends State<GenreStyleStep> {
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final PlotBoosterService _service = PlotBoosterService();

  List<String> _genreSuggestions = [];
  List<String> _styleSuggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print("GenreStyleStep initState called");
    _loadSuggestions();

    // 既存の値があれば設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("GenreStyleStep PostFrameCallback executed");
      try {
        final provider =
            Provider.of<PlotBoosterProvider>(context, listen: false);
        print("Provider in PostFrameCallback: ${provider.plotBooster.genre}");
        _genreController.text = provider.plotBooster.genre;
        _styleController.text = provider.plotBooster.style;
      } catch (e) {
        print("Error in PostFrameCallback: $e");
      }
    });
  }

  Future<void> _loadSuggestions() async {
    print("GenreStyleStep _loadSuggestions called");
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<PlotBoosterProvider>(context, listen: false);
      print("Provider in _loadSuggestions: ${provider.isAIAssistEnabled}");
      if (provider.isAIAssistEnabled) {
        _genreSuggestions = await _service.suggestGenres();
        _styleSuggestions = await _service.suggestStyles();
        print(
            "Suggestions loaded: ${_genreSuggestions.length} genres, ${_styleSuggestions.length} styles");
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
    print("GenreStyleStep build method called");

    try {
      final provider = Provider.of<PlotBoosterProvider>(context);
      print("Provider in build: ${provider.plotBooster.genre}");

      // デバッグ用のテキスト表示
      return SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ジャンルと作風を決めましょう',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 8),

            // デバッグ情報
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.amber.withOpacity(0.2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("デバッグ情報:",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text("Provider: ${provider != null ? '取得済み' : 'null'}"),
                  Text("Genre: ${provider.plotBooster.genre}"),
                  Text("Style: ${provider.plotBooster.style}"),
                  Text("AI Assist: ${provider.isAIAssistEnabled}"),
                ],
              ),
            ),
            SizedBox(height: 16),

            // ジャンル入力
            TextField(
              controller: _genreController,
              decoration: InputDecoration(
                labelText: 'ジャンル',
                hintText: '例: ファンタジー、SF、ミステリーなど',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                provider.updateGenre(value);
              },
            ),
            SizedBox(height: 16),

            // 作風入力
            TextField(
              controller: _styleController,
              decoration: InputDecoration(
                labelText: '作風',
                hintText: '例: シリアス、コメディ、ダークなど',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                provider.updateStyle(value);
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
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else ...[
                // ジャンル提案
                Text('ジャンル提案:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _genreSuggestions.map((genre) {
                    return ActionChip(
                      label: Text(genre),
                      onPressed: () {
                        _genreController.text = genre;
                        provider.updateGenre(genre);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),

                // 作風提案
                Text('作風提案:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _styleSuggestions.map((style) {
                    return ActionChip(
                      label: Text(style),
                      onPressed: () {
                        _styleController.text = style;
                        provider.updateStyle(style);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ],
        ),
      );
    } catch (e) {
      print("Error in build method: $e");
      // エラー時のフォールバック表示
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text("エラーが発生しました: $e"),
            SizedBox(height: 16),
            Text("デバッグ用テキスト: GenreStyleStep is rendering"),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _genreController.dispose();
    _styleController.dispose();
    super.dispose();
  }
}
