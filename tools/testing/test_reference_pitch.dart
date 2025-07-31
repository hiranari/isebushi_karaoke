import 'dart:io';
import 'dart:math' show sqrt, log, ln2;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/infrastructure/services/pitch_detection_service.dart';
import '../../lib/infrastructure/services/cache_service.dart';

/// 基準ピッチ算出の外部検証ツール
/// WAVファイルから基準ピッチを抽出し、詳細な統計情報を出力
void main() async {
  // Flutter binding の初期化
  TestWidgetsFlutterBinding.ensureInitialized();
  
  print('=== 基準ピッチ検証・デバッグツール ===');
  
  // 固定でTest.wavを使用（後で引数対応可能）
  final String wavFilePath = 'assets/sounds/Test.wav';
  final bool useCache = true;
  final bool debugMode = true;

  try {
    if (debugMode) {
      print('🔧 デバッグモード: 有効');
      print('📁 WAVファイル: $wavFilePath');
      print('💾 キャッシュ使用: $useCache');
    }

    // サービスの初期化
    final pitchService = PitchDetectionService();
    
    if (debugMode) {
      print('⚙️ PitchDetectionService初期化中...');
    }
    pitchService.initialize();
    
    if (debugMode) {
      print('✅ PitchDetectionService初期化完了');
    }

    print('\n=== 📊 基準ピッチ分析開始 ===');
    print('対象ファイル: $wavFilePath');

    // キャッシュチェック
    var cachedResult;
    if (useCache) {
      if (debugMode) {
        print('🔍 キャッシュ確認中...');
      }
      
      cachedResult = await CacheService.loadFromCache(wavFilePath);
      
      if (cachedResult != null) {
        print('💾 キャッシュから結果を取得');
        
        if (debugMode) {
          print('キャッシュ情報:');
          print('  - 分析日時: ${cachedResult.createdAt.toLocal()}');
          print('  - 経過時間: ${DateTime.now().difference(cachedResult.createdAt).inHours}時間');
          print('  - ピッチ数: ${cachedResult.pitches.length}');
        }
      }
    }

    // ピッチ検出実行
    final stopwatch = Stopwatch()..start();
    
    final result = cachedResult ?? await pitchService.extractPitchFromAudio(
      sourcePath: wavFilePath,
      isAsset: true,
    );
    
    stopwatch.stop();

    // 新規分析の場合はキャッシュに保存
    if (cachedResult == null && useCache) {
      await CacheService.saveToCache(wavFilePath, result);
      if (debugMode) {
        print('💾 結果をキャッシュに保存');
      }
    }

    // 結果表示
    print('\n=== 📈 分析結果 ===');
    print('処理時間: ${stopwatch.elapsedMilliseconds}ms');
    print('分析日時: ${result.createdAt.toLocal()}');
    print('総ピッチ数: ${result.pitches.length}');

    if (result.pitches.isNotEmpty) {
      // 統計情報の計算
      final allPitches = result.pitches.cast<double>();
      final validPitches = <double>[];
      for (final pitch in allPitches) {
        if (pitch > 0) {
          validPitches.add(pitch);
        }
      }
      final invalidCount = result.pitches.length - validPitches.length;
      
      print('\n=== 📊 統計情報 ===');
      print('有効ピッチ数: ${validPitches.length}');
      print('無効ピッチ数: $invalidCount');
      print('有効率: ${(validPitches.length / result.pitches.length * 100).toStringAsFixed(1)}%');
      
      if (validPitches.isNotEmpty) {
        validPitches.sort();
        final minPitch = validPitches.first;
        final maxPitch = validPitches.last;
        final avgPitch = validPitches.reduce((a, b) => a + b) / validPitches.length;
        
        // 中央値計算
        final median = validPitches.length % 2 == 0 
            ? (validPitches[validPitches.length ~/ 2 - 1] + validPitches[validPitches.length ~/ 2]) / 2
            : validPitches[validPitches.length ~/ 2];
        
        // 標準偏差計算
        final variance = validPitches.map((p) => (p - avgPitch) * (p - avgPitch)).reduce((a, b) => a + b) / validPitches.length;
        final stdDev = sqrt(variance);
        
        print('最小ピッチ: ${minPitch.toStringAsFixed(1)} Hz');
        print('最大ピッチ: ${maxPitch.toStringAsFixed(1)} Hz');
        print('平均ピッチ: ${avgPitch.toStringAsFixed(1)} Hz');
        print('中央値: ${median.toStringAsFixed(1)} Hz');
        print('標準偏差: ${stdDev.toStringAsFixed(1)} Hz');
        
        // 四分位数
        final q1Index = validPitches.length ~/ 4;
        final q3Index = (validPitches.length * 3) ~/ 4;
        print('第1四分位数 (Q1): ${validPitches[q1Index].toStringAsFixed(1)} Hz');
        print('第3四分位数 (Q3): ${validPitches[q3Index].toStringAsFixed(1)} Hz');
        
        // 音域分析
        final octaveRange = (maxPitch / minPitch);
        print('音域幅: ${octaveRange.toStringAsFixed(2)}倍 (${(log(octaveRange) / ln2).toStringAsFixed(1)}オクターブ)');

        // ピッチ分布分析
        print('\n=== 🎵 ピッチ分布分析 ===');
        _analyzePitchDistribution(validPitches);

        if (debugMode) {
          print('\n=== 🔍 詳細デバッグ情報 ===');
          _printDetailedDebugInfo(result, validPitches);
        }

        // CopilotDebugBridge向け出力
        print('\n=== 🤖 CopilotDebugBridge出力 ===');
        _outputForCopilotDebugBridge(wavFilePath, result, validPitches, cachedResult != null);

      } else {
        print('⚠️ 警告: 有効なピッチが検出されませんでした');
      }
    } else {
      print('❌ エラー: ピッチが検出されませんでした');
    }

    print('\n✅ 基準ピッチ分析完了');

  } catch (e, stackTrace) {
    print('❌ エラーが発生しました: $e');
    print('スタックトレース: $stackTrace');
  }
}

/// ピッチ分布を分析して表示
void _analyzePitchDistribution(List<double> validPitches) {
  // 音名への変換と分布
  final Map<String, int> noteDistribution = {};
  
  for (final pitch in validPitches) {
    final noteNumber = 12 * (log(pitch) / ln2 - log(440) / ln2) + 69;
    final note = _getNoteFromNumber(noteNumber.round());
    noteDistribution[note] = (noteDistribution[note] ?? 0) + 1;
  }
  
  // 上位5音名を表示
  final sortedNotes = noteDistribution.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  
  print('出現頻度上位5音名:');
  for (int i = 0; i < 5 && i < sortedNotes.length; i++) {
    final entry = sortedNotes[i];
    final percentage = (entry.value / validPitches.length * 100).toStringAsFixed(1);
    print('  ${i + 1}. ${entry.key}: ${entry.value}回 (${percentage}%)');
  }
}

/// 詳細デバッグ情報を出力
void _printDetailedDebugInfo(dynamic result, List<double> validPitches) {
  print('分析詳細:');
  print('  - ファイルパス: ${result.sourceFile}');
  print('  - 分析時刻: ${result.createdAt.toIso8601String()}');
  print('  - サンプルレート: ${result.sampleRate} Hz');
  
  // 最初と最後の10個のピッチ値
  print('\n最初の10個のピッチ値:');
  final firstTen = result.pitches.take(10).toList();
  for (int i = 0; i < firstTen.length; i++) {
    final pitch = firstTen[i];
    final status = pitch > 0 ? '✓' : '✗';
    print('  [$i] $status ${pitch.toStringAsFixed(1)} Hz');
  }
  
  if (result.pitches.length > 10) {
    print('\n最後の10個のピッチ値:');
    final lastTen = result.pitches.skip(result.pitches.length - 10).toList();
    for (int i = 0; i < lastTen.length; i++) {
      final pitch = lastTen[i];
      final status = pitch > 0 ? '✓' : '✗';
      final index = result.pitches.length - 10 + i;
      print('  [$index] $status ${pitch.toStringAsFixed(1)} Hz');
    }
  }
}

/// CopilotDebugBridge向けの構造化出力
void _outputForCopilotDebugBridge(String filePath, dynamic result, List<double> validPitches, bool fromCache) {
  final summary = {
    'file_path': filePath,
    'analysis_date': result.createdAt.toIso8601String(),
    'from_cache': fromCache,
    'sample_rate': result.sampleRate,
    'total_pitches': result.pitches.length,
    'valid_pitches': validPitches.length,
    'validity_rate': validPitches.length / result.pitches.length,
    'statistics': validPitches.isNotEmpty ? {
      'min_hz': validPitches.reduce((a, b) => a < b ? a : b),
      'max_hz': validPitches.reduce((a, b) => a > b ? a : b),
      'avg_hz': validPitches.reduce((a, b) => a + b) / validPitches.length,
      'std_dev_hz': _calculateStandardDeviation(validPitches),
    } : null,
  };
  
  print('COPILOT_DEBUG_BRIDGE: ${summary.toString()}');
}

/// 標準偏差を計算
double _calculateStandardDeviation(List<double> values) {
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
  return sqrt(variance);
}

/// 音程番号から音名を取得
String _getNoteFromNumber(int noteNumber) {
  const notes = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
  final octave = (noteNumber ~/ 12) - 1;
  final note = notes[noteNumber % 12];
  return '$note$octave';
}

// math系の関数をimport
