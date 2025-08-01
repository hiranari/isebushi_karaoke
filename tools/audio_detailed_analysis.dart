import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() async {
  final file = File('assets/sounds/Test.wav');
  final bytes = await file.readAsBytes();
  
  print('🔍 Test.wav詳細分析');
  print('ファイルサイズ: ${bytes.length} bytes');
  
  // WAVヘッダー読み取り
  final sampleRate = _readUint32LE(bytes, 24);
  final numChannels = _readUint16LE(bytes, 22);
  final bitsPerSample = _readUint16LE(bytes, 34);
  final bytesPerSample = bitsPerSample ~/ 8;
  
  print('サンプルレート: ${sampleRate}Hz');
  print('チャンネル数: $numChannels');
  print('ビット深度: ${bitsPerSample}bit');
  
  // データ部分を探索
  int dataStart = 44; // 標準的なWAVヘッダーサイズ
  final dataSize = bytes.length - dataStart;
  final totalSamples = dataSize ~/ (bytesPerSample * numChannels);
  
  print('\n📊 音声データ分析:');
  print('総サンプル数: $totalSamples');
  print('再生時間: ${(totalSamples / sampleRate).toStringAsFixed(2)}秒');
  
  // 無音でない部分を探す
  int firstNonZeroSample = -1;
  double maxAmplitudeFound = 0.0;
  
  print('\n🔍 無音部分の検出...');
  for (int i = 0; i < min(10000, totalSamples); i++) {
    final sampleOffset = dataStart + (i * bytesPerSample * numChannels);
    final sample = _readInt16LE(bytes, sampleOffset);
    final amplitude = (sample / 32768.0).abs();
    
    if (amplitude > 0.001 && firstNonZeroSample == -1) { // ノイズレベル以上
      firstNonZeroSample = i;
      print('最初の音声データ: サンプル$i (${(i/sampleRate).toStringAsFixed(3)}秒)');
    }
    
    if (amplitude > maxAmplitudeFound) {
      maxAmplitudeFound = amplitude;
    }
  }
  
  print('最大振幅: ${maxAmplitudeFound.toStringAsFixed(4)}');
  
  if (firstNonZeroSample == -1) {
    print('❌ 最初の10000サンプルに音声データが見つかりません');
    return;
  }
  
  // 音声データ部分から1024サンプルを分析（FFT風の周波数解析）
  print('\n🎵 周波数分析 (音声部分):');
  await _analyzeFrequencySpectrum(bytes, dataStart, firstNonZeroSample, sampleRate, numChannels, bitsPerSample);
  
  // 複数の位置で分析
  final positions = [
    firstNonZeroSample + 1000,
    firstNonZeroSample + 5000,
    firstNonZeroSample + 10000,
  ];
  
  for (final pos in positions) {
    if (pos < totalSamples - 1024) {
      print('\n📍 位置 ${(pos/sampleRate).toStringAsFixed(2)}秒での分析:');
      await _analyzeFrequencySpectrum(bytes, dataStart, pos, sampleRate, numChannels, bitsPerSample);
    }
  }
}

Future<void> _analyzeFrequencySpectrum(
  Uint8List bytes, 
  int dataStart, 
  int startSample, 
  int sampleRate, 
  int numChannels, 
  int bitsPerSample
) async {
  final bytesPerSample = bitsPerSample ~/ 8;
  final analyzeLength = 1024; // 分析するサンプル数
  
  // 音声データを取得
  final amplitudes = <double>[];
  for (int i = 0; i < analyzeLength; i++) {
    final sampleIndex = startSample + i;
    final sampleOffset = dataStart + (sampleIndex * bytesPerSample * numChannels);
    
    if (sampleOffset + bytesPerSample <= bytes.length) {
      final sample = _readInt16LE(bytes, sampleOffset);
      amplitudes.add(sample / 32768.0);
    } else {
      break;
    }
  }
  
  if (amplitudes.length < 512) {
    print('   データ不足');
    return;
  }
  
  // ゼロクロッシング法で基本周波数推定
  int zeroCrossings = 0;
  for (int i = 1; i < amplitudes.length; i++) {
    if ((amplitudes[i-1] >= 0 && amplitudes[i] < 0) || 
        (amplitudes[i-1] < 0 && amplitudes[i] >= 0)) {
      zeroCrossings++;
    }
  }
  
  final estimatedFreq = (zeroCrossings / 2.0) * sampleRate / amplitudes.length;
  
  // 自己相関法による周波数推定
  final correlationFreq = _autocorrelationPitchDetection(amplitudes, sampleRate);
  
  print('   ゼロクロッシング法: ${estimatedFreq.toStringAsFixed(2)}Hz');
  print('   自己相関法: ${correlationFreq.toStringAsFixed(2)}Hz');
  
  // C2とC4の判定
  final c2 = 65.41;
  final c4 = 261.63;
  
  if (correlationFreq >= c2 * 0.9 && correlationFreq <= c2 * 1.8) {
    print('   ✅ C2域 (${c2.toStringAsFixed(1)}Hz付近)');
  } else if (correlationFreq >= c4 * 0.9 && correlationFreq <= c4 * 1.8) {
    print('   ❌ C4域 (${c4.toStringAsFixed(1)}Hz付近) - 本来はC2のはず');
  } else {
    print('   ❓ その他域');
  }
  
  // 平均振幅
  final avgAmplitude = amplitudes.map((a) => a.abs()).reduce((a, b) => a + b) / amplitudes.length;
  print('   平均振幅: ${avgAmplitude.toStringAsFixed(4)}');
}

double _autocorrelationPitchDetection(List<double> signal, int sampleRate) {
  final length = signal.length;
  double maxCorr = 0.0;
  int bestLag = 0;
  
  // ラグ範囲: 50Hz-500Hzに対応
  final minLag = (sampleRate / 500).round();
  final maxLag = (sampleRate / 50).round();
  
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
