import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Phase 3: リアルタイムピッチ視覚化ウィジェット
/// 
/// 録音中のピッチと基準ピッチをリアルタイムで表示します。
/// 単一責任の原則に従い、ピッチの視覚化のみを担当します。
class RealtimePitchVisualizer extends StatelessWidget {
  final double? currentPitch;
  final List<double> referencePitches;
  final List<double> recordedPitches;
  final bool isRecording;
  final double width;
  final double height;

  const RealtimePitchVisualizer({
    super.key,
    this.currentPitch,
    required this.referencePitches,
    required this.recordedPitches,
    required this.isRecording,
    this.width = 350,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: CustomPaint(
        painter: PitchVisualizerPainter(
          currentPitch: currentPitch,
          referencePitches: referencePitches,
          recordedPitches: recordedPitches,
          isRecording: isRecording,
        ),
        size: Size(width, height),
      ),
    );
  }
}

/// ピッチ可視化カスタムペインター
class PitchVisualizerPainter extends CustomPainter {
  final double? currentPitch;
  final List<double> referencePitches;
  final List<double> recordedPitches;
  final bool isRecording;

  // 表示設定
  static const double minPitch = 100.0;  // 最低表示ピッチ(Hz)
  static const double maxPitch = 500.0;  // 最高表示ピッチ(Hz)
  static const int maxDisplayPoints = 100; // 最大表示ポイント数

  PitchVisualizerPainter({
    this.currentPitch,
    required this.referencePitches,
    required this.recordedPitches,
    required this.isRecording,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 背景の描画
    _drawBackground(canvas, size);
    
    // グリッドの描画
    _drawGrid(canvas, size);
    
    // 基準ピッチラインの描画
    _drawReferencePitchLine(canvas, size);
    
    // 録音済みピッチラインの描画
    _drawRecordedPitchLine(canvas, size);
    
    // 現在のピッチインジケーターの描画
    if (isRecording && currentPitch != null) {
      _drawCurrentPitchIndicator(canvas, size);
    }
    
    // ラベルの描画
    _drawLabels(canvas, size);
  }

  /// 背景の描画
  void _drawBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ),
      paint,
    );
  }

  /// グリッドの描画
  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1.0;

    // 水平線（ピッチレベル）
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(40, y),
        Offset(size.width - 20, y),
        paint,
      );
    }

    // 垂直線（時間軸）
    for (int i = 0; i <= 10; i++) {
      final x = 40 + (size.width - 60) * i / 10;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  /// 基準ピッチラインの描画
  void _drawReferencePitchLine(Canvas canvas, Size size) {
    if (referencePitches.isEmpty) return;

    final paint = Paint()
      ..color = Colors.blue[600]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final displayPoints = _getDisplayPoints(referencePitches);
    
    if (displayPoints.isNotEmpty) {
      final firstPoint = _pitchToPoint(displayPoints.first, 0, displayPoints.length, size);
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < displayPoints.length; i++) {
        if (displayPoints[i] > 0) { // 有効なピッチのみ
          final point = _pitchToPoint(displayPoints[i], i, displayPoints.length, size);
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  /// 録音済みピッチラインの描画
  void _drawRecordedPitchLine(Canvas canvas, Size size) {
    if (recordedPitches.isEmpty) return;

    final paint = Paint()
      ..color = Colors.red[600]!
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final displayPoints = _getDisplayPoints(recordedPitches);
    
    if (displayPoints.isNotEmpty) {
      final firstPoint = _pitchToPoint(displayPoints.first, 0, displayPoints.length, size);
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < displayPoints.length; i++) {
        if (displayPoints[i] > 0) { // 有効なピッチのみ
          final point = _pitchToPoint(displayPoints[i], i, displayPoints.length, size);
          path.lineTo(point.dx, point.dy);
        }
      }

      canvas.drawPath(path, paint);
    }
  }

  /// 現在のピッチインジケーターの描画
  void _drawCurrentPitchIndicator(Canvas canvas, Size size) {
    if (currentPitch == null || currentPitch! <= 0) return;

    final paint = Paint()
      ..color = Colors.green[600]!
      ..style = PaintingStyle.fill;

    // 現在位置のX座標（右端）
    final x = size.width - 20;
    final y = _pitchToY(currentPitch!, size);

    // 現在のピッチを示す円
    canvas.drawCircle(Offset(x, y), 6, paint);

    // 脈動効果用の外側の円
    final outerPaint = Paint()
      ..color = Colors.green[600]!.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(x, y), 10, outerPaint);
  }

  /// ラベルの描画
  void _drawLabels(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Y軸ラベル（ピッチ値）
    for (int i = 0; i <= 4; i++) {
      final pitch = maxPitch - (maxPitch - minPitch) * i / 4;
      final y = size.height * i / 4;

      textPainter.text = TextSpan(
        text: '${pitch.toInt()}Hz',
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // 凡例
    _drawLegend(canvas, size);
  }

  /// 凡例の描画
  void _drawLegend(Canvas canvas, Size size) {
    final legendY = size.height - 25;
    
    // 基準ピッチの凡例
    final referencePaint = Paint()
      ..color = Colors.blue[600]!
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(50, legendY),
      Offset(70, legendY),
      referencePaint,
    );
    
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '基準ピッチ',
        style: TextStyle(color: Colors.grey, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(75, legendY - textPainter.height / 2));

    // 録音ピッチの凡例
    final recordedPaint = Paint()
      ..color = Colors.red[600]!
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(150, legendY),
      Offset(170, legendY),
      recordedPaint,
    );
    
    final textPainter2 = TextPainter(
      text: const TextSpan(
        text: '録音ピッチ',
        style: TextStyle(color: Colors.grey, fontSize: 10),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter2.layout();
    textPainter2.paint(canvas, Offset(175, legendY - textPainter2.height / 2));
  }

  /// 表示用ポイントの取得（最大数制限）
  List<double> _getDisplayPoints(List<double> pitches) {
    if (pitches.length <= maxDisplayPoints) {
      return pitches;
    }
    
    // ダウンサンプリング
    final step = pitches.length / maxDisplayPoints;
    final displayPoints = <double>[];
    
    for (int i = 0; i < maxDisplayPoints; i++) {
      final index = (i * step).floor();
      if (index < pitches.length) {
        displayPoints.add(pitches[index]);
      }
    }
    
    return displayPoints;
  }

  /// ピッチ値を座標に変換
  Offset _pitchToPoint(double pitch, int index, int totalPoints, Size size) {
    final x = 40 + (size.width - 60) * index / math.max(1, totalPoints - 1);
    final y = _pitchToY(pitch, size);
    return Offset(x, y);
  }

  /// ピッチ値をY座標に変換
  double _pitchToY(double pitch, Size size) {
    if (pitch <= 0) return size.height / 2; // 無効なピッチは中央に
    
    final clampedPitch = pitch.clamp(minPitch, maxPitch);
    final normalizedPitch = (clampedPitch - minPitch) / (maxPitch - minPitch);
    return size.height * (1 - normalizedPitch);
  }

  @override
  bool shouldRepaint(PitchVisualizerPainter oldDelegate) {
    return currentPitch != oldDelegate.currentPitch ||
           recordedPitches.length != oldDelegate.recordedPitches.length ||
           isRecording != oldDelegate.isRecording;
  }
}