import 'dart:io';
import '../lib/infrastructure/services/pitch_detection_service.dart';
import '../lib/core/logging/logger.dart';

class TestLogger implements ILogger {
  @override
  void debug(String message) => print('[DEBUG] $message');
  
  @override
  void info(String message) => print('[INFO] $message');
  
  @override
  void warning(String message) => print('[WARN] $message');
  
  @override
  void error(String message, [dynamic exception, StackTrace? stackTrace]) =>
      print('[ERROR] $message ${exception != null ? ': $exception' : ''}');
}

void main() async {
  print('🔍 修正されたPitchDetectionServiceのテスト');
  
  // Test.wavファイルを読み込み
  final file = File('assets/sounds/Test.wav');
  if (!file.existsSync()) {
    print('❌ Test.wavファイルが見つかりません');
    return;
  }
  
  final bytes = await file.readAsBytes();
  print('📁 ファイルサイズ: ${bytes.length} bytes');
  
  // PitchDetectionServiceを初期化
  final logger = TestLogger();
  final pitchService = PitchDetectionService(logger);
  
  // PCMデータを抽出（0.5秒から1秒間）
  final sampleRate = 48000; // Test.wavのサンプルレート
  final dataStart = 44;
  final startSample = (0.5 * sampleRate).round();
  final duration = 1.0; // 1秒間
  final sampleCount = (duration * sampleRate).round();
  
  final pcmStartOffset = dataStart + (startSample * 2 * 2); // 16bit stereo
  final pcmLength = sampleCount * 2 * 2; // 16bit stereo
  
  final pcmData = bytes.sublist(pcmStartOffset, pcmStartOffset + pcmLength);
  
  print('📊 PCMデータ:');
  print('  開始時刻: 0.5秒');
  print('  期間: ${duration}秒');
  print('  データサイズ: ${pcmData.length} bytes');
  
  try {
    // 修正されたピッチ検出サービスでピッチを分析
    print('\n🎵 ピッチ検出実行中...');
    final pitches = await pitchService.detectPitchFromPcm(pcmData, sampleRate);
    
    print('✅ 検出完了: ${pitches.length}個のピッチ');
    
    // 有効なピッチのみをフィルタ
    final validPitches = pitches.where((p) => p > 0).toList();
    
    if (validPitches.isNotEmpty) {
      final minPitch = validPitches.reduce((a, b) => a < b ? a : b);
      final maxPitch = validPitches.reduce((a, b) => a > b ? a : b);
      final avgPitch = validPitches.reduce((a, b) => a + b) / validPitches.length;
      
      print('\n📈 統計情報:');
      print('  有効ピッチ数: ${validPitches.length}/${pitches.length}');
      print('  ピッチ範囲: ${minPitch.toStringAsFixed(2)}Hz 〜 ${maxPitch.toStringAsFixed(2)}Hz');
      print('  平均ピッチ: ${avgPitch.toStringAsFixed(2)}Hz');
      
      print('\n🎼 最初の10個のピッチ:');
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
      
      // C2域の検出率をチェック
      final c2Count = validPitches.where((p) => p >= 60 && p <= 75).length;
      final c3Count = validPitches.where((p) => p >= 120 && p <= 150).length;
      final c4Count = validPitches.where((p) => p >= 240 && p <= 300).length;
      
      print('\n🎯 周波数域別検出率:');
      print('  C2域 (60-75Hz): ${c2Count}個 (${(c2Count / validPitches.length * 100).toStringAsFixed(1)}%)');
      print('  C3域 (120-150Hz): ${c3Count}個 (${(c3Count / validPitches.length * 100).toStringAsFixed(1)}%)');
      print('  C4域 (240-300Hz): ${c4Count}個 (${(c4Count / validPitches.length * 100).toStringAsFixed(1)}%)');
      
      if (c2Count > c4Count) {
        print('\n✅ 修正成功！C2域での検出が優勢です。');
      } else if (c4Count > c2Count) {
        print('\n❌ まだ問題があります。C4域での検出が多いです。');
      } else {
        print('\n❓ 混在状態です。さらなる調整が必要かもしれません。');
      }
      
    } else {
      print('❌ 有効なピッチが検出されませんでした');
    }
    
  } catch (e, stackTrace) {
    print('❌ エラー: $e');
    print('スタックトレース: $stackTrace');
  }
}
