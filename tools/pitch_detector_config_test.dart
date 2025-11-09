import 'dart:io';
import 'dart:typed_data';
import 'package:pitch_detector_dart/pitch_detector.dart';

void main() async {
  print('🔍 PitchDetectorライブラリ設定テスト');
  
  // Test.wavファイルを読み込み
  final file = File('assets/sounds/Test.wav');
  final bytes = await file.readAsBytes();
  
  // WAVヘッダー解析
  final sampleRate = _readUint32LE(bytes, 24);
  print('WAVファイルのサンプルレート: ${sampleRate}Hz');
  
  // 異なる設定でテスト
  final configs = [
    {'sampleRate': 48000.0, 'bufferSize': 1024, 'name': '48kHz/1024 (現設定)'},
    {'sampleRate': 44100.0, 'bufferSize': 1024, 'name': '44.1kHz/1024'},
    {'sampleRate': 48000.0, 'bufferSize': 2048, 'name': '48kHz/2048'},
    {'sampleRate': 44100.0, 'bufferSize': 2048, 'name': '44.1kHz/2048'},
    {'sampleRate': 48000.0, 'bufferSize': 4096, 'name': '48kHz/4096'},
  ];
  
  // 音声データ部分（0.5秒後から小さなチャンクを取得）
  final dataStart = 44;
  final startSample = (0.5 * sampleRate).round();
  final testChunkSize = 4096; // 固定チャンクサイズ
  
  final startOffset = dataStart + (startSample * 2 * 2); // 16bit stereo
  final testChunk = bytes.sublist(startOffset, startOffset + testChunkSize);
  
  print('\nテストデータ:');
  print('  チャンクサイズ: $testChunkSize bytes');
  print('  時刻: 0.5秒');
  
  for (final config in configs) {
    final sr = config['sampleRate'] as double;
    final bs = config['bufferSize'] as int;
    final name = config['name'] as String;
    
    print('\n🎵 設定: $name');
    
    try {
      final detector = PitchDetector(
        audioSampleRate: sr,
        bufferSize: bs,
      );
      
      // 小さなチャンクを作成（バッファサイズに合わせる）
      final adjustedChunk = testChunk.sublist(0, bs * 2); // 2 bytes per sample
      
      final result = await detector.getPitchFromIntBuffer(adjustedChunk);
      
      print('  結果:');
      print('    pitched: ${result.pitched}');
      print('    pitch: ${result.pitch.toStringAsFixed(2)}Hz');
      print('    probability: ${(result.probability * 100).toStringAsFixed(1)}%');
      
      // 異常値の分析
      if (result.pitch > 5000) {
        print('    ⚠️  異常に高い値！');
        
        // 可能な原因を推測
        final possibleFundamental = result.pitch;
        for (int divisor = 2; divisor <= 1000; divisor++) {
          final divided = possibleFundamental / divisor;
          if (divided >= 60 && divided <= 75) {
            print('    🔍 ${divisor}で割ると: ${divided.toStringAsFixed(2)}Hz (C2域!)');
            break;
          }
        }
      } else if (result.pitch >= 60 && result.pitch <= 75) {
        print('    ✅ C2域で正常！');
      } else if (result.pitch >= 240 && result.pitch <= 300) {
        print('    ⚠️  C4域（2倍波の可能性）');
      }
      
    } catch (e) {
      print('  エラー: $e');
    }
  }
  
  print('\n🔬 追加分析: PCMデータ検証');
  
  // PCMデータの最初の数サンプルを確認
  final samples = <int>[];
  for (int i = 0; i < 20 && i < testChunk.length ~/ 2; i++) {
    final sample = _readInt16LE(testChunk, i * 2);
    samples.add(sample);
  }
  
  print('最初の20サンプル: ${samples.take(10).join(", ")}...');
  
  final maxSample = samples.map((s) => s.abs()).reduce((a, b) => a > b ? a : b);
  print('最大振幅: $maxSample (${(maxSample / 32768.0 * 100).toStringAsFixed(1)}%)');
  
  // ゼロクロッシング分析
  int zeroCrossings = 0;
  for (int i = 1; i < samples.length; i++) {
    if ((samples[i-1] >= 0 && samples[i] < 0) || 
        (samples[i-1] < 0 && samples[i] >= 0)) {
      zeroCrossings++;
    }
  }
  print('ゼロクロッシング数: $zeroCrossings (推定周波数: ${(zeroCrossings / 2.0 * sampleRate / samples.length).toStringAsFixed(2)}Hz)');
}

int _readUint32LE(Uint8List bytes, int offset) {
  return bytes[offset] | 
         (bytes[offset + 1] << 8) | 
         (bytes[offset + 2] << 16) | 
         (bytes[offset + 3] << 24);
}

int _readInt16LE(Uint8List bytes, int offset) {
  final value = bytes[offset] | (bytes[offset + 1] << 8);
  return value > 32767 ? value - 65536 : value;
}
