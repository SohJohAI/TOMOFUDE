import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/plot_booster_provider.dart';
import '../widgets/plot_step_indicator.dart';
import '../widgets/steps/step0_genre_style_widget.dart';
import '../widgets/steps/step1_logline_widget.dart';
import '../widgets/steps/step2_theme_widget.dart';
import '../widgets/steps/step3_world_setting_widget.dart';
import '../widgets/steps/step4_key_setting_widget.dart';
import '../widgets/steps/step5_character_widget.dart';
import '../widgets/steps/step6_chapter_structure_widget.dart';
import '../widgets/steps/step7_output_widget.dart';
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
  late PlotBoosterProvider _plotBoosterProvider;

  @override
  void initState() {
    super.initState();
    print("PlotBoosterScreen initState called");
    // プロバイダーを一度だけ初期化
    _plotBoosterProvider = PlotBoosterProvider()
      ..setAIAssistEnabled(_isAIAssistEnabled);
  }

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
    _plotBoosterProvider.setAIAssistEnabled(_isAIAssistEnabled);
  }

  void _createWorkFromPlot() {
    final plotBooster = _plotBoosterProvider.plotBooster;
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
    print("PlotBoosterScreen build method called");
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _plotBoosterProvider,
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
                  Step0GenreStyleWidget(),
                  Step1LoglineWidget(),
                  Step2ThemeWidget(),
                  Step3WorldSettingWidget(),
                  Step4KeySettingWidget(),
                  Step5CharacterWidget(),
                  Step6ChapterStructureWidget(),
                  Step7OutputWidget(),
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
