import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pitch_detector_dart/pitch_detector.dart';

void main() async {
  print('🔍 詳細ピッチ検出デバッグ（生データ確認）');
  
  // Test.wavファイルを読み込み
  final file = File('assets/sounds/Test.wav');
  final bytes = await file.readAsBytes();
  
  // WAVヘッダー解析
  final sampleRate = _readUint32LE(bytes, 24);
  print('サンプルレート: ${sampleRate}Hz');
  
  // 音声データ部分（0.5秒後から1秒間を分析）
  final dataStart = 44;
  final startSample = (0.5 * sampleRate).round();
  final endSample = (1.5 * sampleRate).round();
  
  print('分析範囲: ${0.5}秒 〜 ${1.5}秒');
  
  // ピッチ検出器を作成
  final detector = PitchDetector(
    audioSampleRate: sampleRate.toDouble(),
    bufferSize: 1024,
  );
  
  // チャンクサイズとオーバーラップ設定
  const chunkSize = 1024 * 2;
  const overlapRatio = 0.5;
  final stepSize = (chunkSize * (1.0 - overlapRatio)).round();
  
  print('\nチャンク設定:');
  print('  チャンクサイズ: $chunkSize');
  print('  ステップサイズ: $stepSize');
  print('  オーバーラップ: ${(overlapRatio * 100).toInt()}%');
  
  int chunkIndex = 0;
  final results = <Map<String, dynamic>>[];
  
  // 指定範囲を分析
  final startOffset = dataStart + (startSample * 2 * 2); // 16bit stereo
  final endOffset = dataStart + (endSample * 2 * 2);
  
  for (int i = startOffset; i < endOffset - chunkSize && chunkIndex < 10; i += stepSize) {
    final chunk = bytes.sublist(i, i + chunkSize);
    final timePosition = (i - dataStart) / (sampleRate * 2 * 2);
    
    print('\n🎵 チャンク${chunkIndex + 1} (時刻: ${timePosition.toStringAsFixed(3)}秒)');
    
    try {
      // YINアルゴリズムの生結果を取得
      final result = await detector.getPitchFromIntBuffer(chunk);
      
      // 生の結果をログ
      print('  生のYIN結果:');
      print('    pitched: ${result.pitched}');
      print('    pitch: ${result.pitch.toStringAsFixed(2)}Hz');
      print('    probability: ${(result.probability * 100).toStringAsFixed(1)}%');
      
      // 現在のオクターブ補正を適用
      double correctedPitch = _testCorrectOctave(result.pitch);
      print('  オクターブ補正後: ${correctedPitch.toStringAsFixed(2)}Hz');
      
      // 周波数の判定
      _analyzeFrequency(result.pitch, 'YIN生値');
      _analyzeFrequency(correctedPitch, '補正後');
      
      results.add({
        'chunkIndex': chunkIndex,
        'timePosition': timePosition,
        'rawPitch': result.pitch,
        'correctedPitch': correctedPitch,
        'pitched': result.pitched,
        'probability': result.probability,
      });
      
    } catch (e) {
      print('  エラー: $e');
    }
    
    chunkIndex++;
  }
  
  // 統計分析
  print('\n📊 統計分析:');
  final rawPitches = results.map((r) => r['rawPitch'] as double).where((p) => p > 0).toList();
  final correctedPitches = results.map((r) => r['correctedPitch'] as double).where((p) => p > 0).toList();
  
  if (rawPitches.isNotEmpty) {
    final rawAvg = rawPitches.reduce((a, b) => a + b) / rawPitches.length;
    final rawMin = rawPitches.reduce(math.min);
    final rawMax = rawPitches.reduce(math.max);
    
    print('生値統計:');
    print('  平均: ${rawAvg.toStringAsFixed(2)}Hz');
    print('  範囲: ${rawMin.toStringAsFixed(2)}Hz 〜 ${rawMax.toStringAsFixed(2)}Hz');
  }
  
  if (correctedPitches.isNotEmpty) {
    final corrAvg = correctedPitches.reduce((a, b) => a + b) / correctedPitches.length;
    final corrMin = correctedPitches.reduce(math.min);
    final corrMax = correctedPitches.reduce(math.max);
    
    print('補正後統計:');
    print('  平均: ${corrAvg.toStringAsFixed(2)}Hz');
    print('  範囲: ${corrMin.toStringAsFixed(2)}Hz 〜 ${corrMax.toStringAsFixed(2)}Hz');
  }
}

void _analyzeFrequency(double freq, String label) {
  if (freq <= 0) return;
  
  String analysis = '';
  if (freq >= 60 && freq <= 75) {
    analysis = 'C2域 ✅';
  } else if (freq >= 120 && freq <= 150) {
    analysis = 'C3域 (C2の2倍波)';
  } else if (freq >= 240 && freq <= 300) {
    analysis = 'C4域 (C2の4倍波) ❌';
  } else if (freq >= 480 && freq <= 600) {
    analysis = 'C5域 (C2の8倍波)';
  } else {
    analysis = 'その他域';
  }
  
  print('    $label: ${freq.toStringAsFixed(2)}Hz → $analysis');
}

double _testCorrectOctave(double detectedPitch) {
  const minPitchHz = 60.0;
  const maxPitchHz = 1000.0;
  
  // C2域（60-75Hz）の特別保護
  if (detectedPitch >= 58.0 && detectedPitch <= 77.0) {
    return detectedPitch;
  }
  
  double correctedPitch = detectedPitch;
  
  // 範囲内に収まるようにオクターブを調整
  while (correctedPitch < minPitchHz && correctedPitch > 0) {
    correctedPitch *= 2.0;
  }
  while (correctedPitch > maxPitchHz) {
    correctedPitch /= 2.0;
  }
  
  return correctedPitch;
}

int _readUint32LE(Uint8List bytes, int offset) {
  return bytes[offset] | 
         (bytes[offset + 1] << 8) | 
         (bytes[offset + 2] << 16) | 
         (bytes[offset + 3] << 24);
}
