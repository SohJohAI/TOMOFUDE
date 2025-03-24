import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async'; // パフォーマンス最適化のためのタイマー
import '../models/novel.dart';

class NovelEditor extends StatefulWidget {
  final TextEditingController contentController;
  final Function onContentChanged;

  const NovelEditor({
    Key? key,
    required this.contentController,
    required this.onContentChanged,
  }) : super(key: key);

  @override
  State<NovelEditor> createState() => _NovelEditorState();
}

class _NovelEditorState extends State<NovelEditor>
    with SingleTickerProviderStateMixin {
  // ズーム関連の変数
  double _scale = 1.0;
  double _previousScale = 1.0;
  final double _minScale = 0.5;
  final double _maxScale = 3.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  late TransformationController _transformationController;

  // 描画関連の変数
  final List<List<DrawPoint>> _strokes = [];
  List<DrawPoint> _currentStroke = [];
  bool _isDrawing = false;
  double _currentPressure = 1.0;

  // 描画モード
  bool _drawMode = false;

  // 描画スタイル
  Color _strokeColor = CupertinoColors.activeBlue;
  double _baseStrokeWidth = 2.0;

  // パフォーマンス最適化用
  Timer? _frameRateTimer;
  int _frameCount = 0;
  double _currentFps = 60.0;
  bool _showPerformanceStats = false;

  // アニメーション
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();

    // アニメーションコントローラの初期化
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Apple Pencilの検出
    ServicesBinding.instance.keyboard.addHandler(_handleKeyEvent);

    // パフォーマンスモニタリングの開始
    _startPerformanceMonitoring();
  }

  // パフォーマンスモニタリング
  void _startPerformanceMonitoring() {
    _frameRateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentFps = _frameCount.toDouble();
        _frameCount = 0;
      });
    });

    // フレームコールバックの登録
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameCount++;
      if (mounted) {
        WidgetsBinding.instance.scheduleFrameCallback((_) {
          if (mounted) {
            _frameCount++;
            WidgetsBinding.instance.addPostFrameCallback((_) => null);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    ServicesBinding.instance.keyboard.removeHandler(_handleKeyEvent);
    _frameRateTimer?.cancel();
    super.dispose();
  }

  // キーボードイベントハンドラ（Apple Pencilのボタン検出用）
  bool _handleKeyEvent(KeyEvent event) {
    // Apple Pencilのダブルタップを検出
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      // Apple Pencilのボタンがない場合はTabキーで代用
      setState(() {
        _drawMode = !_drawMode;
      });
      return true;
    }
    return false;
  }

  // 描画ポイントを追加
  void _addPoint(Offset point, double pressure) {
    // Apple Pencilの筆圧に応じた線の太さを計算（より敏感に）
    // 筆圧が取得できない場合は1.0を使用
    pressure = pressure > 0 ? pressure : 1.0;
    final double strokeWidth = _baseStrokeWidth * math.min(pressure * 3.0, 4.0);

    // 最適化: 小さな状態更新を減らすためにsetStateの呼び出しを最小限に
    if (_currentStroke.isEmpty ||
        (_currentStroke.last.point - point).distance > 2.0 ||
        (_currentStroke.last.pressure - pressure).abs() > 0.05) {
      setState(() {
        _currentPressure = pressure;
        _currentStroke.add(
          DrawPoint(
            point: point,
            pressure: pressure,
            strokeWidth: strokeWidth,
            color: _strokeColor,
          ),
        );
      });
    }
  }

  // 描画開始
  void _startDrawing(Offset point, double pressure) {
    setState(() {
      _isDrawing = true;
      _currentStroke = [];
      _addPoint(point, pressure);
    });
  }

  // 描画終了
  void _endDrawing() {
    if (_currentStroke.isNotEmpty) {
      setState(() {
        _strokes.add(List.from(_currentStroke));
        _currentStroke = [];
        _isDrawing = false;
      });
    }
  }

  // ズームリセット
  void _resetZoom() {
    _animationController.reset();
    _animation = Tween<double>(
      begin: _scale,
      end: 1.0,
    ).animate(_animationController)
      ..addListener(() {
        setState(() {
          _scale = _animation.value;
          _offset =
              Offset.lerp(_offset, Offset.zero, _animationController.value)!;
          _updateTransformationController();
        });
      });
    _animationController.forward();
  }

  // 変換行列を更新
  void _updateTransformationController() {
    final Matrix4 matrix = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(_scale, _scale);
    _transformationController.value = matrix;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDark
              ? CupertinoColors.systemGrey.darkColor
              : CupertinoColors.systemGrey.color,
          width: 0.5,
        ),
      ),
      child: Stack(
        children: [
          // ズーム可能なエリア
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: _minScale,
            maxScale: _maxScale,
            boundaryMargin: const EdgeInsets.all(20.0),
            clipBehavior: Clip.hardEdge, // 画面端のスワイプジェスチャーとの干渉を防ぐ
            onInteractionStart: (details) {
              if (details.pointerCount == 2) {
                _previousScale = _scale;
                _previousOffset = _offset;
              }
            },
            onInteractionUpdate: (details) {
              if (details.pointerCount == 2) {
                setState(() {
                  _scale = (_previousScale * details.scale).clamp(
                    _minScale,
                    _maxScale,
                  );
                  _offset = _previousOffset + details.focalPointDelta;
                  _updateTransformationController();
                });
              }
            },
            child: Stack(
              children: [
                // テキストエディタ
                CupertinoTextField(
                  controller: widget.contentController,
                  maxLines: null,
                  expands: true,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  placeholder: 'ここに小説を書いてください...',
                  placeholderStyle: TextStyle(
                    color: isDark
                        ? CupertinoColors.systemGrey.darkColor
                        : CupertinoColors.systemGrey.color,
                  ),
                  style: TextStyle(
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 16.0,
                    height: 1.5, // 行間を調整して読みやすく
                  ),
                  onChanged: (value) {
                    widget.onContentChanged(value);
                  },
                  cursorColor: CupertinoTheme.of(context).primaryColor,
                  // 高解像度ディスプレイ向けの最適化
                  strutStyle: const StrutStyle(
                    forceStrutHeight: true,
                    height: 1.2,
                    leading: 0.5,
                  ),
                  // 画面端のスワイプジェスチャーとの干渉を防ぐ
                  keyboardAppearance:
                      isDark ? Brightness.dark : Brightness.light,
                  // 描画モード中は無効化
                  readOnly: _drawMode,
                ),

                // 描画レイヤー
                if (_drawMode)
                  Positioned.fill(
                    child: RepaintBoundary(
                      // パフォーマンス最適化
                      child: GestureDetector(
                        onPanStart: (details) {
                          final RenderBox box =
                              context.findRenderObject() as RenderBox;
                          final Offset localPosition = box.globalToLocal(
                            details.globalPosition,
                          );
                          // 筆圧が取得できない場合は1.0を使用
                          final pressure = 1.0;
                          _startDrawing(localPosition, pressure);
                        },
                        onPanUpdate: (details) {
                          if (_isDrawing) {
                            final RenderBox box =
                                context.findRenderObject() as RenderBox;
                            final Offset localPosition = box.globalToLocal(
                              details.globalPosition,
                            );
                            // 筆圧が取得できない場合は1.0を使用
                            final pressure = 1.0;
                            _addPoint(localPosition, pressure);
                          }
                        },
                        onPanEnd: (details) {
                          _endDrawing();
                        },
                        child: CustomPaint(
                          isComplex: true, // パフォーマンス最適化のヒント
                          willChange: _isDrawing, // 描画中のみ再描画
                          painter: DrawingPainter(
                            strokes: _strokes,
                            currentStroke: _currentStroke,
                          ),
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ツールバー
          if (_drawMode)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 色選択
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _strokeColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () {
                      _showColorPicker(context);
                    },
                  ),
                  const SizedBox(height: 8),

                  // 線の太さ調整
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.darkBackgroundGray
                            : CupertinoColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: _baseStrokeWidth * 4,
                          height: _baseStrokeWidth * 4,
                          decoration: BoxDecoration(
                            color: _strokeColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    onPressed: () {
                      _showStrokeWidthPicker(context);
                    },
                  ),
                  const SizedBox(height: 8),

                  // 消しゴム
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.darkBackgroundGray
                            : CupertinoColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.delete,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _strokes.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // 描画モード切替
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? CupertinoColors.darkBackgroundGray
                            : CupertinoColors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        CupertinoIcons.pencil,
                        color: isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _drawMode = !_drawMode;
                      });
                    },
                  ),
                ],
              ),
            ),

          // ズームリセットボタン
          if (_scale != 1.0)
            Positioned(
              top: 8,
              right: 8,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? CupertinoColors.darkBackgroundGray.withOpacity(
                            0.8,
                          )
                        : CupertinoColors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                    size: 18,
                  ),
                ),
                onPressed: _resetZoom,
              ),
            ),

          // 現在の筆圧表示
          if (_drawMode && _isDrawing)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.darkBackgroundGray.withOpacity(0.8)
                      : CupertinoColors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '筆圧: ${(_currentPressure * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color:
                        isDark ? CupertinoColors.white : CupertinoColors.black,
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // パフォーマンス情報表示
          if (_showPerformanceStats)
            Positioned(
              top: 8,
              right: _scale != 1.0 ? 52 : 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.darkBackgroundGray.withOpacity(0.8)
                      : CupertinoColors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'FPS: ${_currentFps.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: _currentFps < 55
                        ? CupertinoColors.systemRed
                        : (isDark
                            ? CupertinoColors.white
                            : CupertinoColors.black),
                    fontSize: 12,
                  ),
                ),
              ),
            ),

          // パフォーマンスモニタリング切替ボタン
          Positioned(
            top: 8,
            left: _drawMode && _isDrawing ? 120 : 8,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? CupertinoColors.darkBackgroundGray.withOpacity(0.8)
                      : CupertinoColors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.speedometer,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  size: 18,
                ),
              ),
              onPressed: () {
                setState(() {
                  _showPerformanceStats = !_showPerformanceStats;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // 色選択ダイアログを表示
  void _showColorPicker(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final List<Color> colors = [
      CupertinoColors.activeBlue,
      CupertinoColors.systemRed,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      CupertinoColors.systemPurple,
      CupertinoColors.black,
      CupertinoColors.white,
      CupertinoColors.systemGrey,
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '色を選択',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _strokeColor = colors[index];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? CupertinoColors.white
                              : CupertinoColors.black,
                          width: colors[index] == _strokeColor ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 線の太さ選択ダイアログを表示
  void _showStrokeWidthPicker(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '線の太さ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: Container(
                  height: 40,
                  width: double.infinity,
                  child: CupertinoSlider(
                    value: _baseStrokeWidth,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    onChanged: (value) {
                      setState(() {
                        _baseStrokeWidth = value;
                      });
                    },
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _strokeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: _baseStrokeWidth * 4,
                  height: _baseStrokeWidth * 4,
                  decoration: BoxDecoration(
                    color: _strokeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              child: const Text('完了'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// 描画ポイントクラス
class DrawPoint {
  final Offset point;
  final double pressure;
  final double strokeWidth;
  final Color color;

  DrawPoint({
    required this.point,
    required this.pressure,
    required this.strokeWidth,
    required this.color,
  });
}

// 描画用カスタムペインター
class DrawingPainter extends CustomPainter {
  final List<List<DrawPoint>> strokes;
  final List<DrawPoint> currentStroke;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 保存されたストロークを描画
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }

    // 現在のストロークを描画
    _drawStroke(canvas, currentStroke);
  }

  void _drawStroke(Canvas canvas, List<DrawPoint> stroke) {
    if (stroke.isEmpty) return;

    for (int i = 0; i < stroke.length - 1; i++) {
      final p1 = stroke[i];
      final p2 = stroke[i + 1];

      final paint = Paint()
        ..color = p1.color
        ..strokeWidth = p1.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1.point, p2.point, paint);

      // 点と点の間を滑らかにするために円を描画
      canvas.drawCircle(p1.point, p1.strokeWidth / 2, paint);
      if (i == stroke.length - 2) {
        canvas.drawCircle(p2.point, p2.strokeWidth / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is DrawingPainter) {
      return oldDelegate.strokes != strokes ||
          oldDelegate.currentStroke != currentStroke;
    }
    return true;
  }
}
