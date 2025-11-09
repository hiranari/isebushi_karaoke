import 'package:flutter/material.dart';
import 'dart:math' as math;

/// リアルタイムピッチ可視化ウィジェット
/// 
/// 歌声のピッチをリアルタイムで可視化し、基準音程との比較を行う
class PitchVisualizationWidget extends StatefulWidget {
  /// 現在検出されたピッチ（Hz）
  final double? currentPitch;
  
  /// 基準となるピッチ（Hz）
  final double? referencePitch;
  
  /// ピッチ履歴データ
  final List<double> pitchHistory;
  
  /// 表示する履歴の長さ（秒）
  final int historyLengthSeconds;
  
  /// 音程の許容誤差（セント）
  final double toleranceCents;
  
  /// ウィジェットの高さ
  final double height;
  
  /// 背景色
  final Color backgroundColor;
  
  /// ピッチカーブの色
  final Color pitchCurveColor;
  
  /// 基準線の色
  final Color referenceLineColor;

  const PitchVisualizationWidget({
    super.key,
    this.currentPitch,
    this.referencePitch,
    this.pitchHistory = const [],
    this.historyLengthSeconds = 10,
    this.toleranceCents = 50.0,
    this.height = 200.0,
    this.backgroundColor = Colors.black,
    this.pitchCurveColor = Colors.cyan,
    this.referenceLineColor = Colors.orange,
  });

  @override
  State<PitchVisualizationWidget> createState() => _PitchVisualizationWidgetState();
}

class _PitchVisualizationWidgetState extends State<PitchVisualizationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PitchVisualizationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPitch != oldWidget.currentPitch) {
      _animationController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: CustomPaint(
        painter: PitchVisualizationPainter(
          currentPitch: widget.currentPitch,
          referencePitch: widget.referencePitch,
          pitchHistory: widget.pitchHistory,
          toleranceCents: widget.toleranceCents,
          pitchCurveColor: widget.pitchCurveColor,
          referenceLineColor: widget.referenceLineColor,
          animationValue: _animationController.value,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// ピッチ可視化のカスタムペインター
class PitchVisualizationPainter extends CustomPainter {
  final double? currentPitch;
  final double? referencePitch;
  final List<double> pitchHistory;
  final double toleranceCents;
  final Color pitchCurveColor;
  final Color referenceLineColor;
  final double animationValue;

  static const double minDisplayFreq = 80.0;
  static const double maxDisplayFreq = 400.0;

  PitchVisualizationPainter({
    this.currentPitch,
    this.referencePitch,
    required this.pitchHistory,
    required this.toleranceCents,
    required this.pitchCurveColor,
    required this.referenceLineColor,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景グリッドを描画
    _drawGrid(canvas, size);
    
    // 基準線を描画
    if (referencePitch != null) {
      _drawReferenceLine(canvas, size, referencePitch!);
    }
    
    // 許容範囲を描画
    if (referencePitch != null) {
      _drawToleranceRange(canvas, size, referencePitch!);
    }
    
    // ピッチ履歴のカーブを描画
    if (pitchHistory.isNotEmpty) {
      _drawPitchCurve(canvas, size);
    }
    
    // 現在のピッチを描画
    if (currentPitch != null) {
      _drawCurrentPitch(canvas, size, currentPitch!);
    }
    
    // ピッチ値のラベルを描画
    _drawLabels(canvas, size);
  }

  /// 背景グリッドを描画
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade800
      ..strokeWidth = 0.5;

    // 水平線（周波数ライン）
    for (int freq = 100; freq <= 350; freq += 50) {
      final y = _frequencyToY(freq.toDouble(), size.height);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // 垂直線（時間ライン）
    const timeLines = 10;
    for (int i = 0; i <= timeLines; i++) {
      final x = (size.width / timeLines) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  /// 基準線を描画
  void _drawReferenceLine(Canvas canvas, Size size, double refPitch) {
    final paint = Paint()
      ..color = referenceLineColor
      ..strokeWidth = 2.0;

    final y = _frequencyToY(refPitch, size.height);
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  /// 許容範囲を描画
  void _drawToleranceRange(Canvas canvas, Size size, double refPitch) {
    final paint = Paint()
      ..color = referenceLineColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final upperFreq = _centsToFrequency(refPitch, toleranceCents);
    final lowerFreq = _centsToFrequency(refPitch, -toleranceCents);
    
    final upperY = _frequencyToY(upperFreq, size.height);
    final lowerY = _frequencyToY(lowerFreq, size.height);

    canvas.drawRect(
      Rect.fromLTRB(0, upperY, size.width, lowerY),
      paint,
    );
  }

  /// ピッチ履歴のカーブを描画
  void _drawPitchCurve(Canvas canvas, Size size) {
    if (pitchHistory.length < 2) return;

    final paint = Paint()
      ..color = pitchCurveColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool isFirstPoint = true;

    for (int i = 0; i < pitchHistory.length; i++) {
      final pitch = pitchHistory[i];
      if (pitch <= 0) continue; // 無効なピッチをスキップ

      final x = (size.width / pitchHistory.length) * i;
      final y = _frequencyToY(pitch, size.height);

      if (isFirstPoint) {
        path.moveTo(x, y);
        isFirstPoint = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  /// 現在のピッチを描画
  void _drawCurrentPitch(Canvas canvas, Size size, double pitch) {
    final paint = Paint()
      ..color = pitchCurveColor
      ..style = PaintingStyle.fill;

    final y = _frequencyToY(pitch, size.height);
    final x = size.width - 20; // 右端近くに表示

    // アニメーション効果を適用
    final radius = 8.0 + (4.0 * animationValue);
    final alpha = (255 * (1.0 - animationValue * 0.5)).toInt();
    
    paint.color = pitchCurveColor.withAlpha(alpha);
    canvas.drawCircle(Offset(x, y), radius, paint);
  }

  /// ピッチ値のラベルを描画
  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // 周波数ラベル
    for (int freq = 100; freq <= 350; freq += 50) {
      final y = _frequencyToY(freq.toDouble(), size.height);
      
      textPainter.text = TextSpan(
        text: '${freq}Hz',
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // 現在のピッチ値を表示
    if (currentPitch != null) {
      textPainter.text = TextSpan(
        text: '${currentPitch!.toStringAsFixed(1)}Hz',
        style: TextStyle(
          color: pitchCurveColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(size.width - textPainter.width - 10, 10),
      );
    }
  }

  /// 周波数をY座標に変換
  double _frequencyToY(double frequency, double height) {
    if (frequency <= minDisplayFreq) return height;
    if (frequency >= maxDisplayFreq) return 0;
    
    // 対数スケールで変換
    final logMin = math.log(minDisplayFreq);
    final logMax = math.log(maxDisplayFreq);
    final logFreq = math.log(frequency);
    
    final normalizedPosition = (logFreq - logMin) / (logMax - logMin);
    return height * (1.0 - normalizedPosition);
  }

  /// セントから周波数に変換
  double _centsToFrequency(double baseFreq, double cents) {
    return baseFreq * math.pow(2, cents / 1200.0);
  }

  @override
  bool shouldRepaint(PitchVisualizationPainter oldDelegate) {
    return currentPitch != oldDelegate.currentPitch ||
           referencePitch != oldDelegate.referencePitch ||
           pitchHistory != oldDelegate.pitchHistory ||
           animationValue != oldDelegate.animationValue;
  }
}
