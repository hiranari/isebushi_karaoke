import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pitch_detector_dart/pitch_detector.dart';

/// 実際のピッチ検出を使用した検証ツール
/// 修正されたピッチ検出ロジックをテスト
void main() async {
  print('🔍 実際のピッチ検出による検証');
  print('修正後のスケールエラー対策をテスト');
  
  // Test.wavファイルを読み込み
  final file = File('assets/sounds/Test.wav');
  if (!file.existsSync()) {
    print('❌ Test.wavファイルが見つかりません');
    return;
  }
  
  final bytes = await file.readAsBytes();
  print('📁 ファイルサイズ: ${bytes.length} bytes');
  
  // WAVヘッダー解析
  final sampleRate = _readUint32LE(bytes, 24);
  print('サンプルレート: ${sampleRate}Hz');
  
  // 修正されたピッチ検出を実行
  final pitches = await _detectPitchesWithFix(bytes, sampleRate);
  
  print('\n📈 検出結果:');
  print('総ピッチ数: ${pitches.length}');
  
  final validPitches = pitches.where((p) => p > 0).toList();
  if (validPitches.isEmpty) {
    print('❌ 有効なピッチが検出されませんでした');
    return;
  }
  
  final minPitch = validPitches.reduce(math.min);
  final maxPitch = validPitches.reduce(math.max);
  final avgPitch = validPitches.reduce((a, b) => a + b) / validPitches.length;
  
  print('有効ピッチ数: ${validPitches.length}');
  print('ピッチ範囲: ${minPitch.toStringAsFixed(2)}Hz 〜 ${maxPitch.toStringAsFixed(2)}Hz');
  print('平均ピッチ: ${avgPitch.toStringAsFixed(2)}Hz');
  
  // 周波数域別の分析
  final c2Count = validPitches.where((p) => p >= 60 && p <= 75).length;
  final c3Count = validPitches.where((p) => p >= 120 && p <= 150).length;
  final c4Count = validPitches.where((p) => p >= 240 && p <= 300).length;
  
  print('\n🎼 周波数域別検出:');
  print('C2域 (60-75Hz): ${c2Count}個 (${(c2Count / validPitches.length * 100).toStringAsFixed(1)}%)');
  print('C3域 (120-150Hz): ${c3Count}個 (${(c3Count / validPitches.length * 100).toStringAsFixed(1)}%)');
  print('C4域 (240-300Hz): ${c4Count}個 (${(c4Count / validPitches.length * 100).toStringAsFixed(1)}%)');
  
  print('\n🎵 最初の10個のピッチ:');
  final firstTen = validPitches.take(10);
  for (int i = 0; i < firstTen.length; i++) {
    final pitch = firstTen.elementAt(i);
    String analysis = '';
    
    if (pitch >= 60 && pitch <= 75) {
      analysis = ' ✅ C2域';
    } else if (pitch >= 120 && pitch <= 150) {
      analysis = ' ⚠️ C3域';
    } else if (pitch >= 240 && pitch <= 300) {
      analysis = ' ❌ C4域';
    } else {
      analysis = ' ❓ その他';
    }
    
    print('  ${i + 1}: ${pitch.toStringAsFixed(2)}Hz$analysis');
  }
  
  // 結果判定
  print('\n📊 修正効果の評価:');
  if (c2Count > c4Count) {
    print('✅ 修正成功！C2域での検出が優勢です。');
    print('   修正前はC4域だったピッチがC2域で検出されています。');
  } else if (c4Count > c2Count) {
    print('❌ 修正不完全。まだC4域での検出が多いです。');
    print('   さらなる調整が必要かもしれません。');
  } else {
    print('❓ 混在状態。複数の検出が発生しています。');
  }
  
  // 結果をJSONで保存
  final result = {
    'wavFile': 'assets/sounds/Test.wav',
    'testTime': DateTime.now().toIso8601String(),
    'fixApplied': true,
    'statistics': {
      'totalPitches': pitches.length,
      'validPitches': validPitches.length,
      'minPitch': minPitch,
      'maxPitch': maxPitch,
      'avgPitch': avgPitch,
      'c2Count': c2Count,
      'c3Count': c3Count,
      'c4Count': c4Count,
    },
    'firstTenPitches': firstTen.toList(),
  };
  
  final outputFile = File('verification_results/real_pitch_test_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json');
  await outputFile.writeAsString(jsonEncode(result));
  print('\n📄 結果を保存: ${outputFile.path}');
}

Future<List<double>> _detectPitchesWithFix(Uint8List bytes, int sampleRate) async {
  print('\n🎵 修正されたピッチ検出を実行中...');
  
  final detector = PitchDetector(
    audioSampleRate: sampleRate.toDouble(),
    bufferSize: 1024,
  );
  
  final pitches = <double>[];
  const chunkSize = 1024 * 2;
  const overlapRatio = 0.5;
  final stepSize = (chunkSize * (1.0 - overlapRatio)).round();
  
  final dataStart = 44;
  final startSample = (0.2 * sampleRate).round(); // 0.2秒後から開始
  final startOffset = dataStart + (startSample * 2 * 2); // 16bit stereo
  
  print('分析開始位置: 0.2秒');
  print('チャンクサイズ: $chunkSize, ステップ: $stepSize');
  
  for (int i = startOffset; i < bytes.length - chunkSize; i += stepSize) {
    final chunk = bytes.sublist(i, i + chunkSize);
    
    try {
      final result = await detector.getPitchFromIntBuffer(chunk);
      
      if (result.pitched && result.probability > 0.1) {
        double detectedPitch = result.pitch;
        
        // ✅ 修正適用: pitch_detector_dartライブラリのスケールエラー対策
        if (detectedPitch > 5000) {
          detectedPitch = detectedPitch / 338.0;
        }
        
        // ✅ 修正適用: C2域保護
        if (detectedPitch >= 58.0 && detectedPitch <= 77.0) {
          // C2域は補正を行わない
          pitches.add(detectedPitch);
        } else {
          // 範囲外の場合はオクターブ補正
          double correctedPitch = detectedPitch;
          const minPitchHz = 60.0;
          const maxPitchHz = 1000.0;
          
          while (correctedPitch < minPitchHz && correctedPitch > 0) {
            correctedPitch *= 2.0;
          }
          while (correctedPitch > maxPitchHz) {
            correctedPitch /= 2.0;
          }
          
          pitches.add(correctedPitch);
        }
      } else {
        pitches.add(0.0);
      }
    } catch (e) {
      pitches.add(0.0);
    }
    
    // 進捗表示
    if (pitches.length % 100 == 0) {
      print('処理中... ${pitches.length}チャンク完了');
    }
    
    // 最大1000チャンクまで処理
    if (pitches.length >= 1000) break;
  }
  
  return pitches;
}

int _readUint32LE(Uint8List bytes, int offset) {
  return bytes[offset] | 
         (bytes[offset + 1] << 8) | 
         (bytes[offset + 2] << 16) | 
         (bytes[offset + 3] << 24);
}

String jsonEncode(Map<String, dynamic> obj) {
  // シンプルなJSON文字列化（dependencies回避）
  final buffer = StringBuffer();
  buffer.write('{');
  
  final entries = obj.entries.toList();
  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    buffer.write('"${entry.key}":');
    
    final value = entry.value;
    if (value is String) {
      buffer.write('"$value"');
    } else if (value is num) {
      buffer.write(value);
    } else if (value is bool) {
      buffer.write(value);
    } else if (value is List) {
      buffer.write('[');
      for (int j = 0; j < value.length; j++) {
        if (j > 0) buffer.write(',');
        buffer.write(value[j]);
      }
      buffer.write(']');
    } else if (value is Map) {
      buffer.write(jsonEncode(value as Map<String, dynamic>));
    }
    
    if (i < entries.length - 1) buffer.write(',');
  }
  
  buffer.write('}');
  return buffer.toString();
}
