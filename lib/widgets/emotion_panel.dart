import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../models/emotion.dart';

// HexColorユーティリティクラス
class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

// 感情セグメント項目ウィジェット
class EmotionSegmentItem extends StatelessWidget {
  final EmotionSegment segment;
  final bool isDark;

  const EmotionSegmentItem({
    Key? key,
    required this.segment,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: HexColor(segment.emotionCode).withOpacity(0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: HexColor(segment.emotionCode),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${segment.name}: ${segment.dominantEmotion}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  '強度: ${segment.emotionValue}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              segment.description,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// 感情グラフペインター
class EmotionGraphPainter extends CustomPainter {
  final List<EmotionSegment> segments;

  EmotionGraphPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty) return;

    // X軸のステップ計算
    final double xStep = size.width / (segments.length - 1);

    // 感情強度のポイント
    final List<Offset> emotionPoints = [];
    // 盛り上がり度のポイント
    final List<Offset> excitementPoints = [];

    // ポイントの計算（一度に計算して描画回数を減らす）
    for (int i = 0; i < segments.length; i++) {
      double x = i * xStep;

      // 感情強度のY座標（上下反転）
      double emotionY =
          size.height - (segments[i].emotionValue / 100 * size.height);
      emotionPoints.add(Offset(x, emotionY));

      // 盛り上がり度のY座標（上下反転）
      double excitementY =
          size.height - (segments[i].excitement / 100 * size.height);
      excitementPoints.add(Offset(x, excitementY));
    }

    // 感情強度の線と塗りつぶし
    _drawLineWithFill(
      canvas,
      emotionPoints,
      const Color(0xFF5D5CDE), // 青紫色
      const Color(0x335D5CDE), // 半透明の青紫色
      size,
    );

    // 盛り上がり度の線と塗りつぶし
    _drawLineWithFill(
      canvas,
      excitementPoints,
      const Color(0xFFE57373), // 赤色
      const Color(0x33E57373), // 半透明の赤色
      size,
    );

    // 感情ポイントを描画（バッチ処理）
    for (int i = 0; i < segments.length; i++) {
      final point = emotionPoints[i];
      final color = HexColor(segments[i].emotionCode);

      // ポイントを描画
      canvas.drawCircle(point, 4, Paint()..color = color);

      // 白い縁取り
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  // 線と塗りつぶしを描画（最適化版）
  void _drawLineWithFill(
    Canvas canvas,
    List<Offset> points,
    Color lineColor,
    Color fillColor,
    Size size,
  ) {
    if (points.isEmpty) return;

    // パスを一度だけ作成
    final path = Path()..moveTo(points.first.dx, points.first.dy);

    // すべてのポイントを追加
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    // 線を描画
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // 塗りつぶし用にパスをコピーして閉じる
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    // 塗りつぶし
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant EmotionGraphPainter oldDelegate) {
    return !listEquals(oldDelegate.segments, segments);
  }
}

// メイン感情パネルウィジェット
class EmotionPanel extends StatelessWidget {
  final EmotionAnalysis? emotionAnalysis;
  final bool isLoading;
  final VoidCallback onRefresh;

  const EmotionPanel({
    Key? key,
    this.emotionAnalysis,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey4,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          _buildHeader(context, isDark),

          Container(
            height: 0.5,
            color: isDark
                ? CupertinoColors.systemGrey.darkColor
                : CupertinoColors.systemGrey4,
          ),

          // 感情分析内容
          Expanded(
            child: _buildContent(context, isDark),
          ),
        ],
      ),
    );
  }

  // ヘッダー部分を構築
  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 18,
                color: CupertinoColors.activeBlue,
              ),
              const SizedBox(width: 8),
              const Text(
                '感情分析',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.refresh,
              size: 18,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }

  // コンテンツ部分を構築
  Widget _buildContent(BuildContext context, bool isDark) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (emotionAnalysis == null) {
      return Center(
        child: Text(
          '感情分析を更新ボタンで生成できます',
          style: TextStyle(
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
            fontSize: 14,
          ),
        ),
      );
    }

    return CupertinoScrollbar(
      thickness: 6.0,
      radius: const Radius.circular(10.0),
      thumbVisibility: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 感情グラフ
            RepaintBoundary(
              child: SizedBox(
                height: 150,
                child: _buildEmotionGraph(),
              ),
            ),
            const SizedBox(height: 16),

            // 感情サマリー
            _buildSummarySection(isDark),
            const SizedBox(height: 16),

            // 感情セグメント詳細
            _buildSegmentsSection(isDark),
          ],
        ),
      ),
    );
  }

  // 感情グラフを構築
  Widget _buildEmotionGraph() {
    return CustomPaint(
      painter: EmotionGraphPainter(
        segments: emotionAnalysis!.segments,
      ),
      child: Container(),
    );
  }

  // サマリーセクションを構築
  Widget _buildSummarySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '感情の流れ',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          emotionAnalysis!.summary,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  // セグメントセクションを構築
  Widget _buildSegmentsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '感情セグメント詳細',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey2,
          ),
        ),
        const SizedBox(height: 8),
        ...emotionAnalysis!.segments.map((segment) {
          return EmotionSegmentItem(
            segment: segment,
            isDark: isDark,
          );
        }).toList(),
      ],
    );
  }
}
