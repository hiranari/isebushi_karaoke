import 'dart:math' as math;
import '../lib/services/pitch_comparison_service.dart';

/// Phase 2 機能のデモンストレーション
/// Flutter UIなしでコア機能をテスト
void main() async {
  print('=== Phase 2 Pitch Comparison Demo ===\n');

  final service = PitchComparisonService();

  // テストデータの生成
  print('1. テストデータ生成中...');
  final referencePitches = generateTestPitches();
  final singingPitches = generateSingingPitches();
  
  print('基準ピッチ数: ${referencePitches.length}');
  print('歌唱ピッチ数: ${singingPitches.length}\n');

  // 基本比較
  print('2. 基本比較実行中...');
  final simpleResult = await service.compareSimple(
    referencePitches: referencePitches,
    singingPitches: singingPitches,
  );
  
  print('基本スコア: ${simpleResult.overallScore.toStringAsFixed(1)}');
  print('セント差分数: ${simpleResult.centDifferences.length}\n');

  // DTW比較
  print('3. DTW精密比較実行中...');
  final dtwResult = await service.compareWithDTW(
    referencePitches: referencePitches,
    singingPitches: singingPitches,
  );

  // 結果表示
  print('=== 精密比較結果 ===');
  printComparisonResults(dtwResult);

  print('\n=== デモ完了 ===');
}

/// テスト用基準ピッチ生成（音階パターン）
List<double> generateTestPitches() {
  // C4-C5のメジャースケール
  const baseFreq = 261.63; // C4
  const semitoneRatio = 1.059463094359; // 2^(1/12)
  
  final pitches = <double>[];
  final scale = [0, 2, 4, 5, 7, 9, 11, 12]; // Major scale intervals
  
  for (int i = 0; i < 20; i++) {
    final note = scale[i % scale.length];
    final octave = i ~/ scale.length;
    final frequency = baseFreq * math.pow(semitoneRatio, note + (octave * 12));
    pitches.add(frequency);
  }
  
  return pitches;
}

/// テスト用歌唱ピッチ生成（基準から少しずれたパターン）
List<double> generateSingingPitches() {
  final reference = generateTestPitches();
  final singing = <double>[];
  
  for (int i = 0; i < reference.length + 3; i++) { // 少し長めに
    if (i < reference.length) {
      // 基準ピッチから±20セント以内のランダムなずれ
      final centDeviation = (math.Random().nextDouble() - 0.5) * 40; // ±20 cents
      final ratio = math.pow(2, centDeviation / 1200); // Cent to frequency ratio
      final adjustedPitch = reference[i] * ratio;
      
      // ビブラート効果を一部に追加
      if (i % 5 == 0 && i > 5) {
        final vibrato = 5.0 * math.sin(2 * math.pi * 6 * i / reference.length);
        final vibratoRatio = math.pow(2, vibrato / 1200);
        singing.add(adjustedPitch * vibratoRatio);
      } else {
        singing.add(adjustedPitch);
      }
    } else {
      // 余分なノート
      singing.add(reference.last * 1.1);
    }
  }
  
  return singing;
}

/// 比較結果の詳細表示
void printComparisonResults(dynamic result) {
  print('総合スコア: ${result.overallScore.toStringAsFixed(1)}');
  
  final summary = result.getSummary();
  print('平均セント差: ${summary['averageCentDifference'].toStringAsFixed(1)}');
  print('最大セント差: ${summary['maxCentDifference'].toStringAsFixed(1)}');
  
  print('\n--- ピッチ安定性 ---');
  print('安定性スコア: ${result.stabilityAnalysis.stabilityScore.toStringAsFixed(1)}');
  print('ピッチ分散: ${result.stabilityAnalysis.pitchVariance.toStringAsFixed(2)}');
  print('不安定区間数: ${result.stabilityAnalysis.unstableRegionCount}');
  
  print('\n--- ビブラート分析 ---');
  print('ビブラート検出: ${result.vibratoAnalysis.vibratoDetected ? "あり" : "なし"}');
  if (result.vibratoAnalysis.vibratoDetected) {
    print('ビブラートレート: ${result.vibratoAnalysis.vibratoRate.toStringAsFixed(1)} Hz');
    print('ビブラート深さ: ${result.vibratoAnalysis.vibratoDepth.toStringAsFixed(1)} cents');
    print('規則性スコア: ${result.vibratoAnalysis.vibratoRegularityScore.toStringAsFixed(1)}');
  }
  
  print('\n--- タイミング精度 ---');
  print('タイミングスコア: ${result.timingAnalysis.accuracyScore.toStringAsFixed(1)}');
  print('平均時間ずれ: ${result.timingAnalysis.averageTimeOffset.toStringAsFixed(1)} ms');
  print('最大時間ずれ: ${result.timingAnalysis.maxTimeOffset.toStringAsFixed(1)} ms');
  print('有意な遅延数: ${result.timingAnalysis.significantDelayCount}');
  
  print('\n--- DTW結果 ---');
  print('アライメント済ペア数: ${result.alignedPitches.length}');
  
  if (result.alignedPitches.isNotEmpty) {
    final firstPair = result.alignedPitches.first;
    final lastPair = result.alignedPitches.last;
    
    print('最初のペア: 基準=${firstPair.referencePitch.toStringAsFixed(1)}Hz, ' +
          '歌唱=${firstPair.singingPitch.toStringAsFixed(1)}Hz, ' +
          'セント差=${firstPair.centDifference.toStringAsFixed(1)}');
    print('最後のペア: 基準=${lastPair.referencePitch.toStringAsFixed(1)}Hz, ' +
          '歌唱=${lastPair.singingPitch.toStringAsFixed(1)}Hz, ' +
          'セント差=${lastPair.centDifference.toStringAsFixed(1)}');
  }
}