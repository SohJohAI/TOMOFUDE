import 'package:flutter/material.dart';

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

    return Container(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final isActive = index == currentStep;
          final isCompleted = index < currentStep;

          return GestureDetector(
            onTap: () => onStepTapped(index),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                    SizedBox(width: 4),
                  ],
                  Text(
                    steps[index],
                    style: TextStyle(
                      color: isActive
                          ? Colors.white
                          : (isCompleted ? Colors.grey[700] : Colors.grey[600]),
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
