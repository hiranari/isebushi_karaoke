import '../../lib/infrastructure/services/pitch_detection_service.dart';

/// PitchDetectionServiceの実際のテスト
/// Test_improved.wavを使用して実際のピッチ検出を実行
void main() async {
  print('=== PitchDetectionService 実テスト ===');
  
  try {
    // PitchDetectionServiceの初期化
    final pitchService = PitchDetectionService();
    pitchService.initialize();
    
    print('✅ PitchDetectionService初期化完了');
    
    // Test_improved.wavでピッチ検出テスト
    final testFile = 'assets/sounds/Test_improved.wav';
    print('\n=== $testFile のピッチ検出テスト ===');
    
    final stopwatch = Stopwatch()..start();
    
    final result = await pitchService.extractPitchFromAudio(
      sourcePath: testFile,
      isAsset: true,
    );
    
    stopwatch.stop();
    
    print('✅ ピッチ検出完了 (処理時間: ${stopwatch.elapsedMilliseconds}ms)');
    print('\n=== 検出結果 ===');
    print('検出されたピッチ数: ${result.pitches.length}');
    
    if (result.pitches.isNotEmpty) {
      // 統計情報の計算
      final validPitches = result.pitches.where((p) => p > 0).toList();
      
      if (validPitches.isNotEmpty) {
        final minPitch = validPitches.reduce((a, b) => a < b ? a : b);
        final maxPitch = validPitches.reduce((a, b) => a > b ? a : b);
        final avgPitch = validPitches.reduce((a, b) => a + b) / validPitches.length;
        
        print('有効ピッチ数: ${validPitches.length}');
        print('最小ピッチ: ${minPitch.toStringAsFixed(1)} Hz');
        print('最大ピッチ: ${maxPitch.toStringAsFixed(1)} Hz');
        print('平均ピッチ: ${avgPitch.toStringAsFixed(1)} Hz');
        
        // 最初の20個のピッチを表示
        final displayPitches = result.pitches.take(20).toList();
        print('\n最初の20個のピッチ値:');
        for (int i = 0; i < displayPitches.length; i++) {
          final pitch = displayPitches[i];
          final status = pitch > 0 ? '${pitch.toStringAsFixed(1)}Hz' : '無音';
          print('  ${i + 1}: $status');
        }
        
        // ピッチの安定性チェック
        print('\n=== ピッチ安定性分析 ===');
        var stableCount = 0;
        var fluctuationCount = 0;
        
        for (int i = 1; i < validPitches.length; i++) {
          final diff = (validPitches[i] - validPitches[i - 1]).abs();
          if (diff < 10.0) { // 10Hz以下の変動は安定とみなす
            stableCount++;
          } else {
            fluctuationCount++;
          }
        }
        
        final stabilityRatio = stableCount / (stableCount + fluctuationCount);
        print('安定区間: $stableCount');
        print('変動区間: $fluctuationCount');
        print('安定性: ${(stabilityRatio * 100).toStringAsFixed(1)}%');
        
        if (stabilityRatio > 0.7) {
          print('✅ ピッチ検出は安定しています');
        } else if (stabilityRatio > 0.4) {
          print('⚠️ ピッチ検出にやや変動があります');
        } else {
          print('❌ ピッチ検出が不安定です');
        }
        
      } else {
        print('❌ 有効なピッチが検出されませんでした');
      }
    } else {
      print('❌ ピッチデータが空です');
    }
    
    // 統計情報の表示
    print('\n=== 統計情報 ===');
    final stats = result.getStatistics();
    print('最小ピッチ: ${stats['min']!.toStringAsFixed(1)} Hz');
    print('最大ピッチ: ${stats['max']!.toStringAsFixed(1)} Hz');
    print('平均ピッチ: ${stats['average']!.toStringAsFixed(1)} Hz');
    print('有効データ比率: ${(stats['validRatio']! * 100).toStringAsFixed(1)}%');
    
  } catch (e, stackTrace) {
    print('❌ エラーが発生しました: $e');
    print('スタックトレース: $stackTrace');
    
    // 一般的な問題の診断
    print('\n=== 問題診断 ===');
    if (e.toString().contains('PitchDetectionException')) {
      print('1. WAVファイル形式の問題の可能性');
      print('2. ファイルパスの確認が必要');
    } else if (e.toString().contains('FileSystemException')) {
      print('1. ファイルが存在しない可能性');
      print('2. パーミッションの問題の可能性');
    } else {
      print('1. 依存関係の問題の可能性');
      print('2. 初期化の問題の可能性');
    }
  }
  
  print('\n=== テスト完了 ===');
}
