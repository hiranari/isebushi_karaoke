import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:pitch_detector_dart/pitch_detector_dart.dart';

void main() async {
  print('🔍 YINアルゴリズム詳細デバッグ');
  
  // Test.wavファイルを読み込み
  final file = File('assets/sounds/Test.wav');
  final bytes = await file.readAsBytes();
  
  // WAVヘッダー解析
  final sampleRate = _readUint32LE(bytes, 24);
  final numChannels = _readUint16LE(bytes, 22);
  final bitsPerSample = _readUint16LE(bytes, 34);
  final bytesPerSample = bitsPerSample ~/ 8;
  
  print('サンプルレート: ${sampleRate}Hz');
  print('チャンネル数: $numChannels');
  
  // 音声データ部分を特定（0.5秒後から開始）
  final dataStart = 44;
  final startSample = (0.5 * sampleRate).round(); // 0.5秒後
  final analyzeLength = 2048; // 分析するサンプル数
  
  // 音声データを抽出
  final audioData = <double>[];
  for (int i = 0; i < analyzeLength; i++) {
    final sampleIndex = startSample + i;
    final sampleOffset = dataStart + (sampleIndex * bytesPerSample * numChannels);
    
    if (sampleOffset + bytesPerSample <= bytes.length) {
      final sample = _readInt16LE(bytes, sampleOffset);
      audioData.add(sample / 32768.0);
    }
  }
  
  print('\n📊 分析データ:');
  print('分析開始位置: 0.5秒');
  print('分析サンプル数: ${audioData.length}');
  print('データ範囲: ${audioData.map((d) => d.abs()).reduce(max).toStringAsFixed(4)}');
  
  // 異なる設定でYINアルゴリズムをテスト
  final testConfigs = [
    {'minFreq': 50.0, 'maxFreq': 300.0, 'name': '50-300Hz'},
    {'minFreq': 65.0, 'maxFreq': 500.0, 'name': '65-500Hz'},
    {'minFreq': 80.0, 'maxFreq': 600.0, 'name': '80-600Hz (元設定)'},
    {'minFreq': 65.0, 'maxFreq': 1000.0, 'name': '65-1000Hz (新設定)'},
    {'minFreq': 30.0, 'maxFreq': 2000.0, 'name': '30-2000Hz (広範囲)'},
  ];
  
  print('\n🎵 異なる設定でのYIN結果:');
  
  for (final config in testConfigs) {
    final minFreq = config['minFreq'] as double;
    final maxFreq = config['maxFreq'] as double;
    final name = config['name'] as String;
    
    try {
      final detector = PitchDetector(sampleRate.toDouble(), audioData);
      final result = detector.getPitch();
      
      if (result != null) {
        final pitch = result.pitch;
        final probability = result.probability;
        
        // 周波数が範囲内かチェック
        final inRange = pitch >= minFreq && pitch <= maxFreq;
        final rangeStatus = inRange ? '✅' : '❌範囲外';
        
        print('   $name: ${pitch.toStringAsFixed(2)}Hz (確率: ${(probability*100).toStringAsFixed(1)}%) $rangeStatus');
        
        // C2, C3, C4の判定
        if (pitch >= 60 && pitch <= 75) {
          print('     → C2域 ✅');
        } else if (pitch >= 120 && pitch <= 150) {
          print('     → C3域 (C2の2倍波)');
        } else if (pitch >= 240 && pitch <= 300) {
          print('     → C4域 (C2の4倍波) ❌');
        } else {
          print('     → その他域');
        }
      } else {
        print('   $name: 検出失敗');
      }
    } catch (e) {
      print('   $name: エラー - $e');
    }
  }
  
  // カスタム分析: 手動でのハーモニクス検出
  print('\n🔬 手動ハーモニクス分析:');
  await _manualHarmonicsAnalysis(audioData, sampleRate.toDouble());
}

Future<void> _manualHarmonicsAnalysis(List<double> signal, double sampleRate) async {
  // 自己相関による基本周波数検出
  final fundamentalFreq = _autocorrelationPitchDetection(signal, sampleRate.round());
  print('自己相関による基本周波数: ${fundamentalFreq.toStringAsFixed(2)}Hz');
  
  // ハーモニクスの存在確認
  final harmonics = [1, 2, 3, 4, 5];
  for (final harmonic in harmonics) {
    final harmonicFreq = fundamentalFreq * harmonic;
    print('${harmonic}倍波: ${harmonicFreq.toStringAsFixed(2)}Hz');
    
    if (harmonic == 1 && harmonicFreq >= 60 && harmonicFreq <= 75) {
      print('  → 基本波がC2域！ ✅');
    } else if (harmonic == 2 && harmonicFreq >= 120 && harmonicFreq <= 150) {
      print('  → 2倍波がC3域');
    } else if (harmonic == 4 && harmonicFreq >= 240 && harmonicFreq <= 300) {
      print('  → 4倍波がC4域 (これが誤検出される可能性)');
    }
  }
  
  // YINが検出しやすいハーモニクスの予測
  print('\n⚠️  YINの可能な誤検出:');
  if (fundamentalFreq >= 60 && fundamentalFreq <= 75) {
    print('基本波: C2 (${fundamentalFreq.toStringAsFixed(1)}Hz) ← 正解');
    print('2倍波: C3 (${(fundamentalFreq*2).toStringAsFixed(1)}Hz)');
    print('4倍波: C4 (${(fundamentalFreq*4).toStringAsFixed(1)}Hz) ← YINが検出している可能性');
  }
}

double _autocorrelationPitchDetection(List<double> signal, int sampleRate) {
  final length = signal.length;
  double maxCorr = 0.0;
  int bestLag = 0;
  
  final minLag = (sampleRate / 500).round();
  final maxLag = (sampleRate / 30).round();
  
  for (int lag = minLag; lag < min(maxLag, length ~/ 2); lag++) {
    double correlation = 0.0;
    for (int i = 0; i < length - lag; i++) {
      correlation += signal[i] * signal[i + lag];
    }
    
    if (correlation > maxCorr) {
      maxCorr = correlation;
      bestLag = lag;
    }
  }
  
  return bestLag > 0 ? sampleRate / bestLag : 0.0;
}

int _readUint16LE(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int _readUint32LE(Uint8List bytes, int offset) {
  return bytes[offset] | 
         (bytes[offset + 1] << 8) | 
         (bytes[offset + 2] << 16) | 
         (bytes[offset + 3] << 24);
}

int _readInt16LE(Uint8List bytes, int offset) {
  final value = _readUint16LE(bytes, offset);
  return value > 32767 ? value - 65536 : value;
}
