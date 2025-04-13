import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/plot_booster_provider.dart';
import '../widgets/plot_step_indicator.dart';
import '../widgets/steps/genre_style_step.dart';
import '../widgets/steps/logline_step.dart';
import '../widgets/steps/theme_step.dart';
import '../widgets/steps/world_setting_step.dart';
import '../widgets/steps/key_setting_step.dart';
import '../widgets/steps/character_step.dart';
import '../widgets/steps/chapter_structure_step.dart';
import '../widgets/steps/output_step.dart';
import '../models/work.dart';
import '../providers/work_list_provider.dart';

class PlotBoosterScreen extends StatefulWidget {
  @override
  _PlotBoosterScreenState createState() => _PlotBoosterScreenState();
}

class _PlotBoosterScreenState extends State<PlotBoosterScreen> {
  int _currentStep = 0;
  bool _isAIAssistEnabled = true;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 7) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToStep(int step) {
    if (step >= 0 && step <= 7) {
      setState(() {
        _currentStep = step;
      });
      _pageController.animateToPage(
        step,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleAIAssist() {
    setState(() {
      _isAIAssistEnabled = !_isAIAssistEnabled;
    });

    // プロバイダーの状態も更新
    Provider.of<PlotBoosterProvider>(context, listen: false)
        .setAIAssistEnabled(_isAIAssistEnabled);
  }

  void _createWorkFromPlot() {
    final plotBooster =
        Provider.of<PlotBoosterProvider>(context, listen: false).plotBooster;
    final workListProvider =
        Provider.of<WorkListProvider>(context, listen: false);

    // 作品タイトルを決定（ログラインの最初の部分を使用）
    String title = plotBooster.logline;
    if (title.length > 30) {
      title = title.substring(0, 30) + '...';
    }

    // 作品説明を生成
    final description =
        '${plotBooster.genre}・${plotBooster.style}\n\n${plotBooster.worldSetting}';

    // 新しい作品を作成
    final work = Work(
      title: title,
      author: '',
      description: description,
    );

    // 章構成から章を追加
    for (var chapterOutline in plotBooster.chapterOutlines) {
      work.addChapter(
        title: chapterOutline.title,
        content: chapterOutline.content,
      );
    }

    // 作品リストに追加
    workListProvider.addWork(work);

    // 作品を返して画面を閉じる
    Navigator.pop(context, work);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) =>
          PlotBoosterProvider()..setAIAssistEnabled(_isAIAssistEnabled),
      child: Scaffold(
        appBar: AppBar(
          title: Text('プロットブースター'),
          leading: IconButton(
            icon: Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // AI支援切り替えスイッチ
            Row(
              children: [
                Text('AI支援'),
                Switch(
                  value: _isAIAssistEnabled,
                  onChanged: (_) => _toggleAIAssist(),
                ),
              ],
            ),
            // 作品作成ボタン（最終ステップでのみ表示）
            if (_currentStep == 7)
              IconButton(
                icon: Icon(Icons.save),
                tooltip: '作品として保存',
                onPressed: _createWorkFromPlot,
              ),
          ],
        ),
        body: Column(
          children: [
            // ステップインジケーター
            PlotStepIndicator(
              currentStep: _currentStep,
              onStepTapped: _goToStep,
            ),

            // メインコンテンツ
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  GenreStyleStep(),
                  LoglineStep(),
                  ThemeStep(),
                  WorldSettingStep(),
                  KeySettingStep(),
                  CharacterStep(),
                  ChapterStructureStep(),
                  OutputStep(),
                ],
              ),
            ),

            // ナビゲーションボタン
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _currentStep > 0 ? _prevStep : null,
                    child: Text('前へ'),
                  ),
                  Text('${_currentStep + 1}/8'),
                  ElevatedButton(
                    onPressed: _currentStep < 7 ? _nextStep : null,
                    child: Text('次へ'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
