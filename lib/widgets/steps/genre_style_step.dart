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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlotBoosterProvider>(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ジャンルと作風を決めましょう',
            style: Theme.of(context).textTheme.titleLarge,
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
  }

  @override
  void dispose() {
    _genreController.dispose();
    _styleController.dispose();
    super.dispose();
  }
}
