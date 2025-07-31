import 'dart:io';
import 'dart:typed_data';

void main() async {
  print('=== オリジナルTest.wavの詳細分析 ===');
  
  final file = File('assets/sounds/Test.wav');
  if (!await file.exists()) {
    print('Error: assets/sounds/Test.wav が見つかりません');
    return;
  }
  
  final bytes = await file.readAsBytes();
  
  print('ファイルサイズ: ${bytes.length} bytes');
  
  // WAVヘッダー解析
  print('\n=== WAVヘッダー解析 ===');
  final headerView = ByteData.sublistView(bytes);
  
  // RIFF chunk
  final riffId = String.fromCharCodes(bytes.sublist(0, 4));
  final fileSize = headerView.getUint32(4, Endian.little);
  final waveId = String.fromCharCodes(bytes.sublist(8, 12));
  
  print('RIFF ID: $riffId');
  print('ファイルサイズ: $fileSize');
  print('WAVE ID: $waveId');
  
  // fmt chunk
  final fmtId = String.fromCharCodes(bytes.sublist(12, 16));
  final fmtSize = headerView.getUint32(16, Endian.little);
  final audioFormat = headerView.getUint16(20, Endian.little);
  final channels = headerView.getUint16(22, Endian.little);
  final sampleRate = headerView.getUint32(24, Endian.little);
  final byteRate = headerView.getUint32(28, Endian.little);
  final blockAlign = headerView.getUint16(32, Endian.little);
  final bitsPerSample = headerView.getUint16(34, Endian.little);
  
  print('\nフォーマット情報:');
  print('fmt ID: $fmtId');
  print('fmt size: $fmtSize');
  print('音声フォーマット: $audioFormat (1=PCM)');
  print('チャンネル数: $channels');
  print('サンプリングレート: ${sampleRate}Hz');
  print('バイトレート: $byteRate');
  print('ブロックアライン: $blockAlign');
  print('ビット深度: $bitsPerSample');
  
  // 期待値との比較
  final expectedBlockAlign = (bitsPerSample * channels) ~/ 8;
  print('期待されるブロックアライン: $expectedBlockAlign');
  if (blockAlign != expectedBlockAlign) {
    print('⚠️ ブロックアライン不整合! 期待値:$expectedBlockAlign 実際値:$blockAlign');
  }
  
  // data chunk
  final dataId = String.fromCharCodes(bytes.sublist(36, 40));
  final dataSize = headerView.getUint32(40, Endian.little);
  
  print('\nデータ情報:');
  print('data ID: $dataId');
  print('データサイズ: $dataSize bytes');
  
  // PCMデータ解析
  print('\n=== PCMデータ解析 ===');
  final pcmStart = 44;
  final pcmData = bytes.sublist(pcmStart, pcmStart + dataSize);
  
  print('PCMデータサイズ: ${pcmData.length} bytes');
  print('理論的サンプル数: ${pcmData.length ~/ 2} samples (16bit想定)');
  print('理論的再生時間: ${(pcmData.length / 2 / channels / sampleRate).toStringAsFixed(2)}秒');
  
  // 最初の100サンプルを解析
  print('\n=== 最初の100サンプル解析 ===');
  final sampleView = ByteData.sublistView(pcmData);
  var zeroCount = 0;
  var nonZeroCount = 0;
  final sampleValues = <int>[];
  
  for (int i = 0; i < 100 && i * 2 < pcmData.length; i++) {
    final sample = sampleView.getInt16(i * 2, Endian.little);
    sampleValues.add(sample);
    if (sample == 0) {
      zeroCount++;
    } else {
      nonZeroCount++;
    }
  }
  
  print('ゼロサンプル数: $zeroCount / 100');
  print('非ゼロサンプル数: $nonZeroCount / 100');
  print('最初の20サンプル値: ${sampleValues.take(20).join(', ')}');
  
  // 全体的な統計
  print('\n=== 全体統計（1000サンプル単位で解析）===');
  var totalZero = 0;
  var totalNonZero = 0;
  final uniqueValues = <int>{};
  
  for (int i = 0; i < 1000 && i * 2 < pcmData.length; i++) {
    final sample = sampleView.getInt16(i * 2, Endian.little);
    uniqueValues.add(sample);
    if (sample == 0) {
      totalZero++;
    } else {
      totalNonZero++;
    }
  }
  
  print('1000サンプル中のゼロ: $totalZero');
  print('1000サンプル中の非ゼロ: $totalNonZero');
  print('ユニークな値の数: ${uniqueValues.length}');
  print('ユニークな値（最初の20個）: ${uniqueValues.take(20).join(', ')}');
  
  // ピッチ検出が困難な理由を推測
  print('\n=== 330Hz固定検出の原因推測 ===');
  if (blockAlign != expectedBlockAlign) {
    print('1. ブロックアライン不整合により、正しいステレオデータが読めない');
  }
  if (totalZero > totalNonZero) {
    print('2. 大部分が無音データ（ゼロサンプル）');
  }
  if (uniqueValues.length < 10) {
    print('3. 音声データのバリエーションが極端に少ない');
  }
  print('4. ステレオデータが正しく処理されず、固定パターンが繰り返される');
  print('5. ピッチ検出アルゴリズムが限られたデータから330Hzという値を推測');
}
