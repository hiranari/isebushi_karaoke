import 'dart:io';
import 'dart:typed_data';

/// 実際のWAVファイルを使ったピッチ検出テスト
/// Test.wavではなく、実際に音声データが含まれるWAVファイルを使用
void main() async {
  print('=== 実際のWAVファイルテスト ===');
  
  // 利用可能なWAVファイルを探す
  final soundsDir = Directory('assets/sounds');
  final wavFiles = await soundsDir
      .list()
      .where((file) => file.path.endsWith('.wav'))
      .map((file) => file as File)
      .toList();
  
  print('利用可能なWAVファイル:');
  for (final file in wavFiles) {
    print('  ${file.path}');
  }
  
  // Test_improved.wavを優先的に使用
  File? targetFile;
  for (final file in wavFiles) {
    if (file.path.contains('Test_improved.wav')) {
      targetFile = file;
      break;
    }
  }
  
  // Test_improved.wavがない場合は最初のファイルを使用
  targetFile ??= wavFiles.isNotEmpty ? wavFiles.first : null;
  
  if (targetFile == null) {
    print('Error: WAVファイルが見つかりません');
    return;
  }
  
  print('\n=== ${targetFile.path} の解析 ===');
  
  if (!await targetFile.exists()) {
    print('Error: ファイルが存在しません');
    return;
  }
  
  final bytes = await targetFile.readAsBytes();
  
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
  print('理論的サンプル数: ${pcmData.length ~/ (bitsPerSample ~/ 8)} samples');
  print('理論的再生時間: ${(pcmData.length / (bitsPerSample ~/ 8) / channels / sampleRate).toStringAsFixed(2)}秒');
  
  // 音声データの品質チェック
  print('\n=== 音声品質チェック ===');
  final sampleView = ByteData.sublistView(pcmData);
  var zeroCount = 0;
  var nonZeroCount = 0;
  final sampleValues = <int>[];
  var maxAmplitude = 0;
  var minAmplitude = 0;
  
  // サンプル数を適切に計算
  final bytesPerSample = bitsPerSample ~/ 8;
  final sampleCount = pcmData.length ~/ bytesPerSample;
  final testSamples = sampleCount > 1000 ? 1000 : sampleCount;
  
  for (int i = 0; i < testSamples; i++) {
    final sampleIndex = i * bytesPerSample;
    if (sampleIndex + bytesPerSample > pcmData.length) break;
    
    int sample;
    if (bitsPerSample == 16) {
      sample = sampleView.getInt16(sampleIndex, Endian.little);
    } else if (bitsPerSample == 8) {
      sample = sampleView.getInt8(sampleIndex) - 128; // 8bitは符号なしなので調整
    } else {
      continue; // 他のビット深度はスキップ
    }
    
    sampleValues.add(sample);
    if (sample == 0) {
      zeroCount++;
    } else {
      nonZeroCount++;
    }
    
    if (sample > maxAmplitude) maxAmplitude = sample;
    if (sample < minAmplitude) minAmplitude = sample;
  }
  
  print('テストサンプル数: $testSamples');
  print('ゼロサンプル数: $zeroCount');
  print('非ゼロサンプル数: $nonZeroCount');
  print('最大振幅: $maxAmplitude');
  print('最小振幅: $minAmplitude');
  
  final silenceRatio = zeroCount / testSamples;
  print('無音比率: ${(silenceRatio * 100).toStringAsFixed(1)}%');
  
  if (nonZeroCount > 0) {
    print('最初の20サンプル値: ${sampleValues.take(20).join(', ')}');
    
    // 音声の活発度チェック
    if (silenceRatio < 0.5) {
      print('✅ 音声データあり - ピッチ検出に適している');
    } else if (silenceRatio < 0.8) {
      print('⚠️ 音声データ少なめ - ピッチ検出が困難な可能性');
    } else {
      print('❌ ほぼ無音 - ピッチ検出には不適');
    }
  } else {
    print('❌ 完全無音ファイル - ピッチ検出不可能');
  }
  
  // 推奨改善策
  print('\n=== 推奨改善策 ===');
  if (silenceRatio > 0.8) {
    print('1. 実際に音声が録音されたWAVファイルを使用');
    print('2. マイクからの録音テストを実行');
    print('3. サンプル音声ファイルのダウンロード');
  } else if (blockAlign != expectedBlockAlign) {
    print('1. WAVファイルの再エンコード');
    print('2. 適切な音声編集ソフトでの修正');
  } else {
    print('1. ファイル形式は正常です');
    print('2. PitchDetectionServiceでの実際のテストを実行');
  }
}
