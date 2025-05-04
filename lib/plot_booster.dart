import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/plot_booster_provider.dart';

// ステップウィジェットのインポート
import 'widgets/steps/step0_genre_style_widget.dart';
import 'widgets/steps/step1_logline_widget.dart';
import 'widgets/steps/step2_theme_widget.dart';
import 'widgets/steps/step3_world_setting_widget.dart';
import 'widgets/steps/step4_key_setting_widget.dart';
import 'widgets/steps/step5_character_widget.dart';
import 'widgets/steps/step6_chapter_structure_widget.dart';
import 'widgets/steps/step7_output_widget.dart';

/// プロットブースター画面
/// 物語の骨子を対話的に作り上げる支援ツール
class PlotBoosterPage extends StatefulWidget {
  const PlotBoosterPage({Key? key}) : super(key: key);

  @override
  _PlotBoosterPageState createState() => _PlotBoosterPageState();
}

class _PlotBoosterPageState extends State<PlotBoosterPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  bool _isAIAssistEnabled = true;

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
        duration: const Duration(milliseconds: 300),
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
        duration: const Duration(milliseconds: 300),
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
        duration: const Duration(milliseconds: 300),
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

  void _showToast(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _restart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('最初からやり直しますか？'),
        content: const Text('入力内容はリセットされます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<PlotBoosterProvider>(context, listen: false).reset();
              _goToStep(0);
              _showToast('入力内容をリセットしました');
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          PlotBoosterProvider()..setAIAssistEnabled(_isAIAssistEnabled),
      child: ScaffoldMessenger(
        key: _scaffoldMessengerKey,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('プロットブースター'),
            actions: [
              // AI支援切り替えスイッチ
              Row(
                children: [
                  const Text('AI支援'),
                  Switch(
                    value: _isAIAssistEnabled,
                    onChanged: (_) => _toggleAIAssist(),
                  ),
                ],
              ),
              // リスタートボタン
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '最初からやり直す',
                onPressed: _restart,
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
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  children: const [
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _currentStep > 0 ? _prevStep : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('前へ'),
                    ),
                    Text('${_currentStep + 1}/8'),
                    ElevatedButton.icon(
                      onPressed: _currentStep < 7 ? _nextStep : null,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('次へ'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ステップインジケーター
/// 現在のステップを表示し、タップでステップを切り替える
class PlotStepIndicator extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepTapped;

  const PlotStepIndicator({
    Key? key,
    required this.currentStep,
    required this.onStepTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final steps = [
      'ジャンル・作風',
      'ログライン',
      'テーマ',
      '世界観',
      'キー設定',
      'キャラクター',
      '章構成',
      '出力',
    ];

    return SizedBox(
      height: 60,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;

            return GestureDetector(
              onTap: () => onStepTapped(index),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : (isCompleted
                          ? Theme.of(context).primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    if (isCompleted) ...[
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: isActive ? Colors.white : Colors.grey[700],
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      steps[index],
                      style: TextStyle(
                        color: isActive
                            ? Colors.white
                            : (isCompleted
                                ? Colors.grey[700]
                                : Colors.grey[600]),
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
