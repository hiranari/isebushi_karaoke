// TODO: 実装後に有効化 - 現在はコンパイルエラー回避のためコメントアウト
/*import 'dart:io';
import 'dart:typed_data';

void main() async {
  print('=== Test.wav 全体データ分析 ===');
  
  final file = File('assets/sounds/Test.wav');
  final bytes = await file.readAsBytes();
  
  // PCMデータ取得
  final pcmStart = 44;
  final dataSize = ByteData.sublistView(bytes).getUint32(40, Endian.little);
  final pcmData = bytes.sublist(pcmStart, pcmStart + dataSize);
  final sampleView = ByteData.sublistView(pcmData);
  
  print('PCMデータサイズ: ${pcmData.length} bytes');
  print('総サンプル数: ${pcmData.length ~/ 2}');
  
  // 全体を10%刻みで分析
  print('\n=== 全体データ分析（10%刻みサンプリング）===');
  
  for (int section = 0; section < 10; section++) {
    final startPos = (pcmData.length * section ~/ 10) ~/ 2 * 2; // 偶数位置に調整
    final endPos = (pcmData.length * (section + 1) ~/ 10) ~/ 2 * 2;
    
    var zeroCount = 0;
    var nonZeroCount = 0;
    final uniqueValues = <int>{};
    var minVal = 32768;
    var maxVal = -32768;
    
    // 100サンプルずつ抽出して分析
    for (int i = startPos; i < endPos && i + 1 < pcmData.length; i += 2) {
      final sample = sampleView.getInt16(i, Endian.little);
      uniqueValues.add(sample);
      
      if (sample == 0) {
        zeroCount++;
      } else {
        nonZeroCount++;
      }
      
      if (sample < minVal) minVal = sample;
      if (sample > maxVal) maxVal = sample;
    }
    
    final totalSamples = (endPos - startPos) ~/ 2;
    final zeroRatio = totalSamples > 0 ? (zeroCount / totalSamples * 100) : 0;
    
    print('セクション ${section + 1} (${section * 10}%-${(section + 1) * 10}%):');
    print('  サンプル数: $totalSamples');
    print('  ゼロ率: ${zeroRatio.toStringAsFixed(1)}%');
    print('  ユニーク値数: ${uniqueValues.length}');
    print('  値の範囲: $minVal ～ $maxVal');
    
    if (uniqueValues.length <= 10) {
      print('  ユニーク値: ${uniqueValues.join(', ')}');
    }
    
    // 非ゼロデータがある場合、詳細表示
    if (nonZeroCount > 0) {
      print('  ⭐ 音声データ検出! 非ゼロサンプル: $nonZeroCount個');
    }
    print('');
  }
  
  // 特に非ゼロデータが多い部分を詳細分析
  print('=== 非ゼロデータの詳細分析 ===');
  var maxNonZeroSection = -1;
  var maxNonZeroCount = 0;
  
  for (int section = 0; section < 10; section++) {
    final startPos = (pcmData.length * section ~/ 10) ~/ 2 * 2;
    final endPos = (pcmData.length * (section + 1) ~/ 10) ~/ 2 * 2;
    
    var nonZeroCount = 0;
    for (int i = startPos; i < endPos && i + 1 < pcmData.length; i += 2) {
      final sample = sampleView.getInt16(i, Endian.little);
      if (sample != 0) nonZeroCount++;
    }
    
    if (nonZeroCount > maxNonZeroCount) {
      maxNonZeroCount = nonZeroCount;
      maxNonZeroSection = section;
    }
  }
  
  if (maxNonZeroSection >= 0) {
    print('最も音声データが多いセクション: ${maxNonZeroSection + 1} ($maxNonZeroCount個の非ゼロサンプル)');
    
    // その部分のサンプル値を表示
    final startPos = (pcmData.length * maxNonZeroSection ~/ 10) ~/ 2 * 2;
    final endPos = (pcmData.length * (maxNonZeroSection + 1) ~/ 10) ~/ 2 * 2;
    
    print('サンプル値（最初の50個）:');
    final samples = <int>[];
    for (int i = startPos; i < endPos && i + 1 < pcmData.length && samples.length < 50; i += 2) {
      final sample = sampleView.getInt16(i, Endian.little);
      samples.add(sample);
    }
    print(samples.join(', '));
  } else {
    print('全体的に無音データです');
  }
}
*/

void main() {
  print("analyze_wav_sections.dart - 実装待ち");
}
