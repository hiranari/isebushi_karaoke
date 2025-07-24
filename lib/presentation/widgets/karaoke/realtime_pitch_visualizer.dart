import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Phase 3: リアルタイムピッチ視覚化ウィジェット
/// 
/// 録音中のピッチと基準ピッチをリアルタイムで表示します。
/// 単一責任の原則に従い、ピッチの視覚化のみを担当します。
/// タップで基準ピッチの詳細情報を表示する隠し機能付き。
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

  /// 基準ピッチの統計情報を計算
  Map<String, dynamic> _calculatePitchStats() {
    final validPitches = referencePitches.where((p) => p > 0).toList();
    
    if (validPitches.isEmpty) {
      return {
        'count': 0,
        'min': 0.0,
        'max': 0.0,
        'average': 0.0,
        'range': '範囲なし',
      };
    }

    validPitches.sort();
    final min = validPitches.first;
    final max = validPitches.last;
    final average = validPitches.reduce((a, b) => a + b) / validPitches.length;
    
    // 音階名を推定（A4=440Hzを基準）
    String getNoteRange() {
      final minNote = _frequencyToNote(min);
      final maxNote = _frequencyToNote(max);
      return '$minNote - $maxNote';
    }

    return {
      'count': validPitches.length,
      'min': min,
      'max': max,
      'average': average,
      'range': getNoteRange(),
    };
  }

  /// 周波数を音階名に変換（簡易版）
  String _frequencyToNote(double frequency) {
    const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const a4 = 440.0;
    
    if (frequency <= 0) return '---';
    
    final semitonesFromA4 = 12 * (math.log(frequency / a4) / math.ln2);
    final octave = 4 + (semitonesFromA4 / 12).floor();
    final noteIndex = ((semitonesFromA4 % 12) + 9).round() % 12; // A=9なので調整
    
    return '${notes[noteIndex]}$octave';
  }

  /// タップ時の詳細情報表示
  void _showPitchDetails(BuildContext context) {
    final stats = _calculatePitchStats();
    
    final message = '''
基準ピッチ詳細情報 🎵
━━━━━━━━━━━━━━━━
📊 データ数: ${stats['count']}個
📈 最高: ${stats['max'].toStringAsFixed(1)}Hz
📉 最低: ${stats['min'].toStringAsFixed(1)}Hz
📐 平均: ${stats['average'].toStringAsFixed(1)}Hz
🎼 音域: ${stats['range']}

💡 ヒント: この情報で基準ピッチが正しく抽出されているか確認できます
💡 ダブルタップで録音ピッチの詳細も表示''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.blue[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 録音ピッチの詳細情報を表示
  void _showRecordedPitchDetails(BuildContext context) {
    final validPitches = recordedPitches.where((p) => p > 0).toList();
    
    if (validPitches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('録音ピッチデータがまだありません'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    validPitches.sort();
    final min = validPitches.first;
    final max = validPitches.last;
    final average = validPitches.reduce((a, b) => a + b) / validPitches.length;
    
    final message = '''
録音ピッチ詳細情報 🎤
━━━━━━━━━━━━━━━━
📊 録音数: ${validPitches.length}個
📈 最高: ${max.toStringAsFixed(1)}Hz (${_frequencyToNote(max)})
📉 最低: ${min.toStringAsFixed(1)}Hz (${_frequencyToNote(min)})
📐 平均: ${average.toStringAsFixed(1)}Hz (${_frequencyToNote(average)})
🎼 音域: ${_frequencyToNote(min)} - ${_frequencyToNote(max)}

現在: ${currentPitch?.toStringAsFixed(1) ?? '--'}Hz''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        backgroundColor: Colors.red[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPitchDetails(context),
      onDoubleTap: () => _showRecordedPitchDetails(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          // 微妙なシャドウでタップ可能であることを示唆
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.2),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            CustomPaint(
              painter: PitchVisualizerPainter(
                currentPitch: currentPitch,
                referencePitches: referencePitches,
                recordedPitches: recordedPitches,
                isRecording: isRecording,
              ),
              size: Size(width, height),
            ),
            // 右下に小さなアイコンでタップ可能を示唆
            Positioned(
              bottom: 4,
              right: 8,
              child: Icon(
                Icons.info_outline,
                size: 12,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
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
  static const double minPitch = 80.0;   // 最低表示ピッチ(Hz) - 人間の歌声範囲に拡張
  static const double maxPitch = 800.0;  // 最高表示ピッチ(Hz) - 500Hz制限を解除
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
  /// 
  /// 録音中の現在のピッチを視覚的に表示します。
  /// プロバイダーから取得したcurrentPitchに基づいて、リアルタイムで更新されます。
  /// 
  /// @param canvas 描画キャンバス
  /// @param size 描画領域のサイズ
  /// @ensures 録音中でピッチが検出されている場合のみ描画される
  /// @ensures 緑色の円で現在のピッチを表示し、脈動効果を追加
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
      ..color = Colors.green[600]!.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(x, y), 10, outerPaint);
    
    // 現在のピッチ値をテキストで表示
    final pitchTextPainter = TextPainter(
      text: TextSpan(
        text: '${currentPitch!.round()}Hz',
        style: const TextStyle(
          color: Colors.green,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    pitchTextPainter.layout();
    pitchTextPainter.paint(
      canvas, 
      Offset(size.width - pitchTextPainter.width - 10, 10)
    );
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