import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// ピッチデバッグ用のヘルパークラス
class PitchDebugHelper {
  /// 純音テスト用のPCMデータを生成
  /// 
  /// [frequency] 生成する周波数（Hz）
  /// [durationSec] 生成する長さ（秒）
  /// [sampleRate] サンプリングレート（Hz）
  /// 戻り値: 純音のPCMデータ
  static List<int> generatePureTone(double frequency, double durationSec, int sampleRate) {
    final sampleCount = (durationSec * sampleRate).round();
    final pcmData = <int>[];
    
    debugPrint('=== 純音生成デバッグ ===');
    debugPrint('周波数: ${frequency.toStringAsFixed(2)}Hz');
    debugPrint('長さ: ${durationSec}秒');
    debugPrint('サンプリングレート: ${sampleRate}Hz');
    debugPrint('サンプル数: $sampleCount');
    
    for (int i = 0; i < sampleCount; i++) {
      final time = i / sampleRate;
      final amplitude = 0.5; // 50%の音量
      final sample = amplitude * math.sin(2 * math.pi * frequency * time);
      final pcmSample = (sample * 32767).round().clamp(-32767, 32767);
      
      // 16bitのPCMデータとして2バイトに分割
      pcmData.add(pcmSample & 0xFF);        // 下位バイト
      pcmData.add((pcmSample >> 8) & 0xFF); // 上位バイト
    }
    
    debugPrint('生成PCMバイト数: ${pcmData.length}');
    debugPrint('=== 純音生成完了 ===');
    
    return pcmData;
  }
  
  /// ピッチデータの統計分析
  static Map<String, dynamic> analyzePitchData(List<double> pitches, String label) {
    final validPitches = pitches.where((p) => p > 0).toList();
    
    if (validPitches.isEmpty) {
      return {
        'label': label,
        'totalCount': pitches.length,
        'validCount': 0,
        'validRatio': 0.0,
        'average': 0.0,
        'min': 0.0,
        'max': 0.0,
        'standardDeviation': 0.0,
      };
    }
    
    validPitches.sort();
    
    final average = validPitches.reduce((a, b) => a + b) / validPitches.length;
    final variance = validPitches
        .map((p) => math.pow(p - average, 2))
        .reduce((a, b) => a + b) / validPitches.length;
    
    return {
      'label': label,
      'totalCount': pitches.length,
      'validCount': validPitches.length,
      'validRatio': validPitches.length / pitches.length,
      'average': average,
      'min': validPitches.first,
      'max': validPitches.last,
      'standardDeviation': math.sqrt(variance),
    };
  }
  
  /// 2つのピッチデータの比較分析
  static void comparePitchData(List<double> reference, List<double> recorded) {
    debugPrint('=== ピッチデータ比較分析 ===');
    
    final refAnalysis = analyzePitchData(reference, '基準ピッチ');
    final recAnalysis = analyzePitchData(recorded, '録音ピッチ');
    
    // 基準ピッチの分析結果
    debugPrint('【基準ピッチ分析】');
    debugPrint('  総数: ${refAnalysis['totalCount']}個');
    debugPrint('  有効: ${refAnalysis['validCount']}個 (${(refAnalysis['validRatio'] * 100).toStringAsFixed(1)}%)');
    debugPrint('  平均: ${refAnalysis['average'].toStringAsFixed(2)}Hz');
    debugPrint('  範囲: ${refAnalysis['min'].toStringAsFixed(2)}Hz - ${refAnalysis['max'].toStringAsFixed(2)}Hz');
    debugPrint('  標準偏差: ${refAnalysis['standardDeviation'].toStringAsFixed(2)}Hz');
    
    // 録音ピッチの分析結果
    debugPrint('【録音ピッチ分析】');
    debugPrint('  総数: ${recAnalysis['totalCount']}個');
    debugPrint('  有効: ${recAnalysis['validCount']}個 (${(recAnalysis['validRatio'] * 100).toStringAsFixed(1)}%)');
    debugPrint('  平均: ${recAnalysis['average'].toStringAsFixed(2)}Hz');
    debugPrint('  範囲: ${recAnalysis['min'].toStringAsFixed(2)}Hz - ${recAnalysis['max'].toStringAsFixed(2)}Hz');
    debugPrint('  標準偏差: ${recAnalysis['standardDeviation'].toStringAsFixed(2)}Hz');
    
    // 比較分析
    if (refAnalysis['validCount'] > 0 && recAnalysis['validCount'] > 0) {
      final avgDiff = recAnalysis['average'] - refAnalysis['average'];
      final avgRatio = recAnalysis['average'] / refAnalysis['average'];
      
      debugPrint('【比較結果】');
      debugPrint('  平均差: ${avgDiff.toStringAsFixed(2)}Hz');
      debugPrint('  平均比: ${avgRatio.toStringAsFixed(3)}');
      
      // オクターブ関係の検出
      final octaveRatio = avgRatio;
      if ((octaveRatio > 1.9 && octaveRatio < 2.1) || (octaveRatio > 0.45 && octaveRatio < 0.55)) {
        debugPrint('  🎵 オクターブ差を検出: ${octaveRatio < 1 ? "1オクターブ下" : "1オクターブ上"}');
      } else if ((octaveRatio > 3.8 && octaveRatio < 4.2) || (octaveRatio > 0.23 && octaveRatio < 0.27)) {
        debugPrint('  🎵 2オクターブ差を検出: ${octaveRatio < 1 ? "2オクターブ下" : "2オクターブ上"}');
      } else if (avgRatio > 1.1 || avgRatio < 0.9) {
        debugPrint('  ⚠️ 警告: 平均ピッチに大きな差があります！');
      }
      
      if (avgDiff.abs() > 50) {
        debugPrint('  ⚠️ 警告: 平均ピッチ差が50Hz以上です！');
      }
    }
    
    debugPrint('=== 比較分析終了 ===');
  }
  
  /// セント単位での偏差計算
  static double calculateCentsDeviation(double reference, double recorded) {
    if (reference <= 0 || recorded <= 0) return 0.0;
    return 1200 * math.log(recorded / reference) / math.ln2;
  }
  
  /// 楽音名に変換
  static String frequencyToNoteName(double frequency) {
    if (frequency <= 0) return 'Silent';
    
    final a4 = 440.0;
    final semitonesFromA4 = (12 * math.log(frequency / a4) / math.ln2).round();
    
    final noteNames = ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'];
    final octave = 4 + ((semitonesFromA4 + 9) ~/ 12);
    final noteIndex = (semitonesFromA4 + 9) % 12;
    
    return '${noteNames[noteIndex]}$octave';
  }
}
