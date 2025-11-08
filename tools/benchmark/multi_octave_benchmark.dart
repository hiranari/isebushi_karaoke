#!/usr/bin/env dart
/// C2～C4音域マルチオクターブベンチマークツール
/// 
/// 機能:
/// - 生成されたテスト音源を使用したピッチ検出精度測定
/// - オクターブ別統計解析 (C2〜C3低音域 vs C3〜C4中音域)
/// - パフォーマンス測定 (処理時間・メモリ使用量)
/// - 1000回検出でのパフォーマンステスト
/// - 詳細結果のJSON出力
/// 
/// 使用例:
/// ```bash
/// dart tools/benchmark/multi_octave_benchmark.dart
/// dart tools/benchmark/multi_octave_benchmark.dart --test-dir test_audio_c2_c4 --iterations 1000
/// ```

import 'dart:io';
import 'dart:convert';
import 'dart:math';

// プロジェクトのライブラリインポート（Flutterに依存しないもののみ）
import '../../lib/domain/interfaces/i_logger.dart';

/// ベンチマーク結果データクラス
class BenchmarkResult {
  final String fileName;
  final String noteName;
  final double expectedFrequency;
  final double detectedFrequency;
  final double errorHz;
  final double errorPercent;
  final int processingTimeMs;
  final bool isSuccessful;
  
  BenchmarkResult({
    required this.fileName,
    required this.noteName,
    required this.expectedFrequency,
    required this.detectedFrequency,
    required this.errorHz,
    required this.errorPercent,
    required this.processingTimeMs,
    required this.isSuccessful,
  });
  
  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'noteName': noteName,
    'expectedFrequency': expectedFrequency,
    'detectedFrequency': detectedFrequency,
    'errorHz': errorHz,
    'errorPercent': errorPercent,
    'processingTimeMs': processingTimeMs,
    'isSuccessful': isSuccessful,
  };
}

/// オクターブ別統計データ
class OctaveStats {
  final String octaveName;
  final List<BenchmarkResult> results;
  
  OctaveStats(this.octaveName, this.results);
  
  double get averageError => results.isEmpty ? 0.0 : 
      results.map((r) => r.errorHz.abs()).reduce((a, b) => a + b) / results.length;
  
  double get averageErrorPercent => results.isEmpty ? 0.0 : 
      results.map((r) => r.errorPercent.abs()).reduce((a, b) => a + b) / results.length;
  
  double get maxError => results.isEmpty ? 0.0 : 
      results.map((r) => r.errorHz.abs()).reduce(max);
  
  double get standardDeviation {
    if (results.isEmpty) return 0.0;
    final mean = averageError;
    final variance = results.map((r) => pow(r.errorHz.abs() - mean, 2))
        .reduce((a, b) => a + b) / results.length;
    return sqrt(variance);
  }
  
  double get successRate => results.isEmpty ? 0.0 : 
      results.where((r) => r.isSuccessful).length / results.length;
  
  double get averageProcessingTime => results.isEmpty ? 0.0 : 
      results.map((r) => r.processingTimeMs).reduce((a, b) => a + b) / results.length;
  
  Map<String, dynamic> toJson() => {
    'octaveName': octaveName,
    'sampleCount': results.length,
    'averageErrorHz': averageError,
    'averageErrorPercent': averageErrorPercent,
    'maxErrorHz': maxError,
    'standardDeviation': standardDeviation,
    'successRate': successRate,
    'averageProcessingTimeMs': averageProcessingTime,
  };
}

/// 総合ベンチマーク統計
class BenchmarkSummary {
  final DateTime timestamp;
  final String testDirectory;
  final int totalFiles;
  final int iterations;
  final List<OctaveStats> octaveStats;
  final List<BenchmarkResult> allResults;
  
  BenchmarkSummary({
    required this.timestamp,
    required this.testDirectory,
    required this.totalFiles,
    required this.iterations,
    required this.octaveStats,
    required this.allResults,
  });
  
  double get overallAverageError => allResults.isEmpty ? 0.0 : 
      allResults.map((r) => r.errorHz.abs()).reduce((a, b) => a + b) / allResults.length;
  
  double get overallSuccessRate => allResults.isEmpty ? 0.0 : 
      allResults.where((r) => r.isSuccessful).length / allResults.length;
  
  double get overallProcessingTime => allResults.isEmpty ? 0.0 : 
      allResults.map((r) => r.processingTimeMs).reduce((a, b) => a + b) / allResults.length;
  
  Map<String, dynamic> toJson() => {
    'summary': {
      'timestamp': timestamp.toIso8601String(),
      'testDirectory': testDirectory,
      'totalFiles': totalFiles,
      'iterations': iterations,
      'overallAverageErrorHz': overallAverageError,
      'overallSuccessRate': overallSuccessRate,
      'overallProcessingTimeMs': overallProcessingTime,
    },
    'octaveStatistics': octaveStats.map((s) => s.toJson()).toList(),
    'detailedResults': allResults.map((r) => r.toJson()).toList(),
  };
}

/// 簡易ロガー実装
class BenchmarkLogger implements ILogger {
  @override
  void debug(String message) => print('[DEBUG] $message');
  
  @override
  void info(String message) => print('[INFO] $message');
  
  @override
  void warning(String message) => print('[WARNING] $message');
  
  @override
  void error(String message) => print('[ERROR] $message');
  
  @override
  void success(String message) => print('[SUCCESS] $message');
}

/// マルチオクターブベンチマーククラス
class MultiOctaveBenchmark {
  final String testDirectory;
  final int iterations;
  final BenchmarkLogger logger;
  
  MultiOctaveBenchmark({
    required this.testDirectory,
    required this.iterations,
  }) : logger = BenchmarkLogger();
  
  /// 全ベンチマーク実行
  Future<BenchmarkSummary> runFullBenchmark() async {
    print('🎯 C2～C4マルチオクターブベンチマーク開始');
    print('📁 テストディレクトリ: $testDirectory');
    print('🔄 反復回数: $iterations');
    print('');
    
    final allResults = <BenchmarkResult>[];
    
    // 1. 単音テスト
    print('🎼 単音テスト実行中...');
    final singleToneResults = await _benchmarkSingleTones();
    allResults.addAll(singleToneResults);
    
    // 2. 楽器別テスト
    print('🎹 楽器別テスト実行中...');
    final instrumentResults = await _benchmarkInstruments();
    allResults.addAll(instrumentResults);
    
    // 3. オクターブ別統計計算
    final octaveStats = _calculateOctaveStats(allResults);
    
    final summary = BenchmarkSummary(
      timestamp: DateTime.now(),
      testDirectory: testDirectory,
      totalFiles: allResults.length,
      iterations: iterations,
      octaveStats: octaveStats,
      allResults: allResults,
    );
    
    // 4. 結果出力
    await _outputResults(summary);
    _printSummary(summary);
    
    return summary;
  }
  
  /// 単音テストベンチマーク
  Future<List<BenchmarkResult>> _benchmarkSingleTones() async {
    final results = <BenchmarkResult>[];
    final singleTonesDir = Directory('$testDirectory/single_tones');
    
    if (!await singleTonesDir.exists()) {
      print('❌ 単音テストディレクトリが見つかりません: $testDirectory/single_tones');
      return results;
    }
    
    final files = await singleTonesDir.list().where((f) => f.path.endsWith('.wav')).toList();
    
    for (final file in files) {
      final fileName = file.path.split('/').last;
      final expectedFreq = _extractFrequencyFromFileName(fileName);
      final noteName = _extractNoteNameFromFileName(fileName);
      
      if (expectedFreq == null || noteName == null) {
        print('⚠️  ファイル名から周波数を抽出できませんでした: $fileName');
        continue;
      }
      
      print('  🎵 テスト中: $noteName (${expectedFreq.toStringAsFixed(2)}Hz)');
      
      // 複数回実行してベンチマーク
      final iterationResults = <BenchmarkResult>[];
      for (int i = 0; i < iterations; i++) {
        final result = await _runSingleBenchmark(file.path, fileName, noteName, expectedFreq);
        iterationResults.add(result);
      }
      
      // 平均結果を計算
      final avgResult = _calculateAverageResult(iterationResults);
      results.add(avgResult);
      
      print('    ✓ 平均誤差: ${avgResult.errorHz.toStringAsFixed(3)}Hz (${avgResult.errorPercent.toStringAsFixed(2)}%)');
    }
    
    return results;
  }
  
  /// 楽器別テストベンチマーク
  Future<List<BenchmarkResult>> _benchmarkInstruments() async {
    final results = <BenchmarkResult>[];
    final instrumentsDir = Directory('$testDirectory/instruments');
    
    if (!await instrumentsDir.exists()) {
      print('❌ 楽器テストディレクトリが見つかりません: $testDirectory/instruments');
      return results;
    }
    
    // 楽器ディレクトリを走査
    final instrumentTypes = await instrumentsDir.list().where((d) => d is Directory).toList();
    
    for (final instrumentDir in instrumentTypes) {
      final instrumentName = instrumentDir.path.split('/').last;
      print('  🎻 $instrumentName テスト中...');
      
      final files = await Directory(instrumentDir.path).list()
          .where((f) => f.path.endsWith('.wav')).toList();
      
      for (final file in files) {
        final fileName = file.path.split('/').last;
        final noteName = _extractNoteNameFromInstrumentFile(fileName);
        final expectedFreq = _getNoteFrequency(noteName);
        
        if (expectedFreq == null || noteName == null) {
          print('    ⚠️  楽器ファイルから情報を抽出できませんでした: $fileName');
          continue;
        }
        
        // 楽器別ベンチマーク実行
        final iterationResults = <BenchmarkResult>[];
        for (int i = 0; i < min(iterations ~/ 5, 100); i++) { // 楽器テストは回数を制限
          final result = await _runSingleBenchmark(
            file.path, 
            '${instrumentName}_$fileName', 
            noteName, 
            expectedFreq
          );
          iterationResults.add(result);
        }
        
        final avgResult = _calculateAverageResult(iterationResults);
        results.add(avgResult);
        
        print('    ✓ $noteName: ${avgResult.errorHz.toStringAsFixed(3)}Hz誤差');
      }
    }
    
    return results;
  }
  
  /// 単一ベンチマーク実行
  Future<BenchmarkResult> _runSingleBenchmark(
    String filePath, 
    String fileName, 
    String noteName, 
    double expectedFreq
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // ピッチ検出実行
      final detectedFreq = await pitchDetector.detectPitchFromFile(filePath);
      
      stopwatch.stop();
      
      if (detectedFreq != null) {
        final errorHz = detectedFreq - expectedFreq;
        final errorPercent = (errorHz / expectedFreq) * 100;
        final isSuccessful = errorHz.abs() <= 2.0; // ±2Hz以内を成功とする
        
        return BenchmarkResult(
          fileName: fileName,
          noteName: noteName,
          expectedFrequency: expectedFreq,
          detectedFrequency: detectedFreq,
          errorHz: errorHz,
          errorPercent: errorPercent,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          isSuccessful: isSuccessful,
        );
      } else {
        return BenchmarkResult(
          fileName: fileName,
          noteName: noteName,
          expectedFrequency: expectedFreq,
          detectedFrequency: 0.0,
          errorHz: expectedFreq,
          errorPercent: 100.0,
          processingTimeMs: stopwatch.elapsedMilliseconds,
          isSuccessful: false,
        );
      }
    } catch (e) {
      stopwatch.stop();
      print('    ❌ エラー: $e');
      
      return BenchmarkResult(
        fileName: fileName,
        noteName: noteName,
        expectedFrequency: expectedFreq,
        detectedFrequency: 0.0,
        errorHz: expectedFreq,
        errorPercent: 100.0,
        processingTimeMs: stopwatch.elapsedMilliseconds,
        isSuccessful: false,
      );
    }
  }
  
  /// 複数回実行結果の平均計算
  BenchmarkResult _calculateAverageResult(List<BenchmarkResult> results) {
    if (results.isEmpty) {
      throw ArgumentError('結果リストが空です');
    }
    
    final successfulResults = results.where((r) => r.isSuccessful).toList();
    
    if (successfulResults.isEmpty) {
      return results.first; // 全て失敗の場合は最初の結果を返す
    }
    
    final avgDetectedFreq = successfulResults
        .map((r) => r.detectedFrequency)
        .reduce((a, b) => a + b) / successfulResults.length;
    
    final avgProcessingTime = results
        .map((r) => r.processingTimeMs)
        .reduce((a, b) => a + b) ~/ results.length;
    
    final first = results.first;
    final errorHz = avgDetectedFreq - first.expectedFrequency;
    final errorPercent = (errorHz / first.expectedFrequency) * 100;
    
    return BenchmarkResult(
      fileName: first.fileName,
      noteName: first.noteName,
      expectedFrequency: first.expectedFrequency,
      detectedFrequency: avgDetectedFreq,
      errorHz: errorHz,
      errorPercent: errorPercent,
      processingTimeMs: avgProcessingTime,
      isSuccessful: errorHz.abs() <= 2.0,
    );
  }
  
  /// オクターブ別統計計算
  List<OctaveStats> _calculateOctaveStats(List<BenchmarkResult> allResults) {
    final c2ToC3 = allResults.where((r) => 
        r.expectedFrequency >= 65.0 && r.expectedFrequency < 131.0).toList();
    final c3ToC4 = allResults.where((r) => 
        r.expectedFrequency >= 131.0 && r.expectedFrequency <= 262.0).toList();
    
    return [
      OctaveStats('C2-C3 (低音域)', c2ToC3),
      OctaveStats('C3-C4 (中音域)', c3ToC4),
    ];
  }
  
  /// 結果出力
  Future<void> _outputResults(BenchmarkSummary summary) async {
    final outputDir = Directory('verification_results');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    
    final timestamp = summary.timestamp.toIso8601String().replaceAll(':', '-');
    final outputFile = File('verification_results/c2_c4_benchmark_$timestamp.json');
    
    final jsonStr = JsonEncoder.withIndent('  ').convert(summary.toJson());
    await outputFile.writeAsString(jsonStr);
    
    print('📊 詳細結果出力: ${outputFile.path}');
  }
  
  /// サマリー表示
  void _printSummary(BenchmarkSummary summary) {
    print('');
    print('📈 === ベンチマーク結果サマリー ===');
    print('⏱️  実行時間: ${DateTime.now().difference(summary.timestamp).inSeconds}秒');
    print('📁 テストファイル数: ${summary.totalFiles}');
    print('🔄 総実行回数: ${summary.totalFiles * summary.iterations}');
    print('');
    print('🎯 全体統計:');
    print('  • 平均誤差: ${summary.overallAverageError.toStringAsFixed(3)}Hz');
    print('  • 成功率: ${(summary.overallSuccessRate * 100).toStringAsFixed(1)}%');
    print('  • 平均処理時間: ${summary.overallProcessingTime.toStringAsFixed(1)}ms');
    print('');
    
    for (final octave in summary.octaveStats) {
      print('🎵 ${octave.octaveName}:');
      print('  • サンプル数: ${octave.results.length}');
      print('  • 平均誤差: ${octave.averageError.toStringAsFixed(3)}Hz (${octave.averageErrorPercent.toStringAsFixed(2)}%)');
      print('  • 最大誤差: ${octave.maxError.toStringAsFixed(3)}Hz');
      print('  • 標準偏差: ${octave.standardDeviation.toStringAsFixed(3)}Hz');
      print('  • 成功率: ${(octave.successRate * 100).toStringAsFixed(1)}%');
      print('  • 平均処理時間: ${octave.averageProcessingTime.toStringAsFixed(1)}ms');
      print('');
    }
    
    // 成功指標チェック
    print('✅ 成功指標チェック:');
    final precisionTarget = summary.overallAverageError <= 1.0;
    final stabilityTarget = summary.octaveStats.every((s) => s.standardDeviation < 0.5);
    final speedTarget = summary.overallProcessingTime <= 100.0;
    final successRateTarget = summary.overallSuccessRate >= 0.9;
    
    print('  • 精度目標 (±1Hz以内): ${precisionTarget ? '✅ 達成' : '❌ 未達成'} (${summary.overallAverageError.toStringAsFixed(3)}Hz)');
    print('  • 安定性目標 (σ<0.5Hz): ${stabilityTarget ? '✅ 達成' : '❌ 未達成'}');
    print('  • 速度目標 (<100ms): ${speedTarget ? '✅ 達成' : '❌ 未達成'} (${summary.overallProcessingTime.toStringAsFixed(1)}ms)');
    print('  • 成功率目標 (>90%): ${successRateTarget ? '✅ 達成' : '❌ 未達成'} (${(summary.overallSuccessRate * 100).toStringAsFixed(1)}%)');
  }
  
  /// ファイル名から周波数抽出
  double? _extractFrequencyFromFileName(String fileName) {
    final regex = RegExp(r'(\d+\.\d+)Hz');
    final match = regex.firstMatch(fileName);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }
  
  /// ファイル名から音階名抽出
  String? _extractNoteNameFromFileName(String fileName) {
    final regex = RegExp(r'^([A-G]#?[0-9])_');
    final match = regex.firstMatch(fileName);
    return match?.group(1);
  }
  
  /// 楽器ファイル名から音階名抽出
  String? _extractNoteNameFromInstrumentFile(String fileName) {
    final regex = RegExp(r'^([A-G]#?[0-9])_');
    final match = regex.firstMatch(fileName);
    return match?.group(1);
  }
  
  /// 音階名から周波数取得
  double? _getNoteFrequency(String? noteName) {
    if (noteName == null) return null;
    
    final noteMap = {
      'C2': 65.41, 'C#2': 69.30, 'D2': 73.42, 'D#2': 77.78, 'E2': 82.41, 'F2': 87.31,
      'F#2': 92.50, 'G2': 98.00, 'G#2': 103.83, 'A2': 110.00, 'A#2': 116.54, 'B2': 123.47,
      'C3': 130.81, 'C#3': 138.59, 'D3': 146.83, 'D#3': 155.56, 'E3': 164.81, 'F3': 174.61,
      'F#3': 185.00, 'G3': 196.00, 'G#3': 207.65, 'A3': 220.00, 'A#3': 233.08, 'B3': 246.94,
      'C4': 261.63,
    };
    
    return noteMap[noteName];
  }
}

/// コマンドライン引数解析
class CliArgs {
  final String testDirectory;
  final int iterations;
  final bool verbose;
  
  CliArgs({
    required this.testDirectory,
    required this.iterations,
    required this.verbose,
  });
  
  static CliArgs parse(List<String> args) {
    String testDirectory = 'test_audio_c2_c4';
    int iterations = 100;
    bool verbose = false;
    
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--test-dir':
          if (i + 1 < args.length) testDirectory = args[++i];
          break;
        case '--iterations':
          if (i + 1 < args.length) iterations = int.tryParse(args[++i]) ?? 100;
          break;
        case '--verbose':
          verbose = true;
          break;
        case '--help':
          _printHelp();
          exit(0);
      }
    }
    
    return CliArgs(testDirectory: testDirectory, iterations: iterations, verbose: verbose);
  }
  
  static void _printHelp() {
    print('''
C2～C4マルチオクターブベンチマークツール

使用法:
  dart tools/benchmark/multi_octave_benchmark.dart [オプション]

オプション:
  --test-dir <dir>     テストディレクトリ (デフォルト: test_audio_c2_c4)
  --iterations <num>   各ファイルの実行回数 (デフォルト: 100)
  --verbose            詳細出力
  --help               このヘルプを表示

例:
  dart tools/benchmark/multi_octave_benchmark.dart
  dart tools/benchmark/multi_octave_benchmark.dart --iterations 1000 --verbose
''');
  }
}

/// メイン実行
Future<void> main(List<String> args) async {
  final config = CliArgs.parse(args);
  
  print('🎯 C2～C4マルチオクターブベンチマークツール');
  print('');
  
  final benchmark = MultiOctaveBenchmark(
    testDirectory: config.testDirectory,
    iterations: config.iterations,
  );
  
  try {
    await benchmark.runFullBenchmark();
    print('');
    print('🎉 ベンチマーク完了！');
    
  } catch (e) {
    print('❌ エラー: $e');
    exit(1);
  }
}
