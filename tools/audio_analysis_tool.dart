import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

void main() async {
  final file = File('assets/sounds/Test.wav');
  
  if (!file.existsSync()) {
    print('❌ Test.wavファイルが見つかりません');
    return;
  }
  
  final bytes = await file.readAsBytes();
  print('📁 ファイル情報:');
  print('   サイズ: ${bytes.length} bytes (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)');
  
  // WAVヘッダー解析
  if (bytes.length < 44) {
    print('❌ WAVファイルが小さすぎます');
    return;
  }
  
  // RIFFヘッダー確認
  final riff = String.fromCharCodes(bytes.sublist(0, 4));
  final wave = String.fromCharCodes(bytes.sublist(8, 12));
  
  if (riff != 'RIFF' || wave != 'WAVE') {
    print('❌ 有効なWAVファイルではありません');
    return;
  }
  
  // フォーマット情報の読み取り
  final formatChunkSize = _readUint32LE(bytes, 16);
  final audioFormat = _readUint16LE(bytes, 20);
  final numChannels = _readUint16LE(bytes, 22);
  final sampleRate = _readUint32LE(bytes, 24);
  final byteRate = _readUint32LE(bytes, 28);
  final blockAlign = _readUint16LE(bytes, 32);
  final bitsPerSample = _readUint16LE(bytes, 34);
  
  print('\n🎵 WAVフォーマット情報:');
  print('   フォーマット: ${audioFormat == 1 ? "PCM" : "その他 ($audioFormat)"}');
  print('   チャンネル数: $numChannels');
  print('   サンプルレート: ${sampleRate}Hz');
  print('   ビットレート: ${byteRate}bytes/sec');
  print('   ブロックアライン: $blockAlign');
  print('   ビット深度: ${bitsPerSample}bit');
  
  // データチャンクを探す
  int dataOffset = 36;
  while (dataOffset < bytes.length - 8) {
    final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
    final chunkSize = _readUint32LE(bytes, dataOffset + 4);
    
    if (chunkId == 'data') {
      print('\n📊 音声データ:');
      print('   データ開始位置: ${dataOffset + 8}');
      print('   データサイズ: $chunkSize bytes');
      
      final duration = chunkSize / byteRate;
      print('   再生時間: ${duration.toStringAsFixed(2)}秒');
      
      // 最初の数サンプルを分析
      await _analyzeAudioSamples(bytes, dataOffset + 8, chunkSize, sampleRate, numChannels, bitsPerSample);
      break;
    }
    
    dataOffset += 8 + chunkSize;
    if (chunkSize % 2 == 1) dataOffset++; // パディング
  }
}

Future<void> _analyzeAudioSamples(
  Uint8List bytes, 
  int dataStart, 
  int dataSize, 
  int sampleRate, 
  int numChannels, 
  int bitsPerSample
) async {
  print('\n🔍 音声波形分析:');
  
  final bytesPerSample = bitsPerSample ~/ 8;
  final totalSamples = dataSize ~/ (bytesPerSample * numChannels);
  
  print('   総サンプル数: $totalSamples');
  print('   分析範囲: 最初の1000サンプル');
  
  // 最初の1000サンプルを取得
  final samplesToAnalyze = min(1000, totalSamples);
  final amplitudes = <double>[];
  
  for (int i = 0; i < samplesToAnalyze; i++) {
    final sampleOffset = dataStart + (i * bytesPerSample * numChannels);
    
    double amplitude = 0.0;
    if (bitsPerSample == 16) {
      // 16bit signed PCM
      final sample = _readInt16LE(bytes, sampleOffset);
      amplitude = sample / 32768.0;
    } else if (bitsPerSample == 24) {
      // 24bit signed PCM
      final sample = _readInt24LE(bytes, sampleOffset);
      amplitude = sample / 8388608.0;
    } else if (bitsPerSample == 32) {
      // 32bit signed PCM
      final sample = _readInt32LE(bytes, sampleOffset);
      amplitude = sample / 2147483648.0;
    }
    
    amplitudes.add(amplitude);
  }
  
  // 統計情報
  final maxAmplitude = amplitudes.map((a) => a.abs()).reduce(max);
  final avgAmplitude = amplitudes.map((a) => a.abs()).reduce((a, b) => a + b) / amplitudes.length;
  
  print('   最大振幅: ${maxAmplitude.toStringAsFixed(4)}');
  print('   平均振幅: ${avgAmplitude.toStringAsFixed(4)}');
  
  // 簡易周波数分析（ゼロクロッシング）
  int zeroCrossings = 0;
  for (int i = 1; i < amplitudes.length; i++) {
    if ((amplitudes[i-1] >= 0 && amplitudes[i] < 0) || 
        (amplitudes[i-1] < 0 && amplitudes[i] >= 0)) {
      zeroCrossings++;
    }
  }
  
  final estimatedFreq = (zeroCrossings / 2.0) * sampleRate / samplesToAnalyze;
  print('   推定基本周波数: ${estimatedFreq.toStringAsFixed(2)}Hz');
  
  // C2の周波数範囲をチェック
  final c2Range = 'C2 (65.41Hz)';
  final c4Range = 'C4 (261.63Hz)';
  
  print('\n🎼 周波数判定:');
  if (estimatedFreq >= 60 && estimatedFreq <= 135) {
    print('   ✅ C2域と判定: $c2Range');
  } else if (estimatedFreq >= 240 && estimatedFreq <= 540) {
    print('   ❌ C4域と判定: $c4Range');
    print('   ⚠️  本来はC2域のはず！');
  } else {
    print('   ❓ その他の周波数域: ${estimatedFreq.toStringAsFixed(2)}Hz');
  }
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

int _readInt24LE(Uint8List bytes, int offset) {
  final value = bytes[offset] | (bytes[offset + 1] << 8) | (bytes[offset + 2] << 16);
  return value > 8388607 ? value - 16777216 : value;
}

int _readInt32LE(Uint8List bytes, int offset) {
  final value = _readUint32LE(bytes, offset);
  return value > 2147483647 ? value - 4294967296 : value;
}
