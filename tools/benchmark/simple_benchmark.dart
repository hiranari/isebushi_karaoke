#!/usr/bin/env dart
/// シンプルなC2～C4音域ベンチマークツール
/// 
/// 機能:
/// - 生成されたテスト音源のファイル名解析による期待値設定
/// - 音源ファイル統計解析
/// - ベンチマーク結果JSON出力
/// 
/// 使用例:
/// ```bash
/// dart tools/benchmark/simple_benchmark.dart
/// dart tools/benchmark/simple_benchmark.dart --test-dir test_audio_c2_c4
/// ```

import 'dart:io';
import 'dart:convert';
import 'dart:math';

/// ベンチマーク結果データクラス
class BenchmarkResult {
  final String fileName;
  final String noteName;
  final double expectedFrequency;
  final String category;
  final String filePath;
  final int fileSizeBytes;
  
  BenchmarkResult({
    required this.fileName,
    required this.noteName,
    required this.expectedFrequency,
    required this.category,
    required this.filePath,
    required this.fileSizeBytes,
  });
  
  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'noteName': noteName,
    'expectedFrequency': expectedFrequency,
    'category': category,
    'filePath': filePath,
    'fileSizeBytes': fileSizeBytes,
  };
}

/// オクターブ別統計データ
class OctaveStats {
  final String octaveName;
  final List<BenchmarkResult> results;
  
  OctaveStats(this.octaveName, this.results);
  
  double get frequencyRangeMin => results.isEmpty ? 0.0 : 
      results.map((r) => r.expectedFrequency).reduce(min);
  
  double get frequencyRangeMax => results.isEmpty ? 0.0 : 
      results.map((r) => r.expectedFrequency).reduce(max);
  
  double get averageFrequency => results.isEmpty ? 0.0 : 
      results.map((r) => r.expectedFrequency).reduce((a, b) => a + b) / results.length;
  
  int get totalFileSize => results.isEmpty ? 0 : 
      results.map((r) => r.fileSizeBytes).reduce((a, b) => a + b);
  
  Map<String, int> get categoryCount {
    final counts = <String, int>{};
    for (final result in results) {
      counts[result.category] = (counts[result.category] ?? 0) + 1;
    }
    return counts;
  }
  
  Map<String, dynamic> toJson() => {
    'octaveName': octaveName,
    'sampleCount': results.length,
    'frequencyRangeMin': frequencyRangeMin,
    'frequencyRangeMax': frequencyRangeMax,
    'averageFrequency': averageFrequency,
    'totalFileSizeBytes': totalFileSize,
    'categoryBreakdown': categoryCount,
  };
}

/// 総合ベンチマーク統計
class BenchmarkSummary {
  final DateTime timestamp;
  final String testDirectory;
  final int totalFiles;
  final List<OctaveStats> octaveStats;
  final List<BenchmarkResult> allResults;
  
  BenchmarkSummary({
    required this.timestamp,
    required this.testDirectory,
    required this.totalFiles,
    required this.octaveStats,
    required this.allResults,
  });
  
  double get overallFrequencyRange => allResults.isEmpty ? 0.0 : 
      allResults.map((r) => r.expectedFrequency).reduce(max) - 
      allResults.map((r) => r.expectedFrequency).reduce(min);
  
  int get totalFileSize => allResults.isEmpty ? 0 : 
      allResults.map((r) => r.fileSizeBytes).reduce((a, b) => a + b);
  
  Map<String, int> get categoryBreakdown {
    final counts = <String, int>{};
    for (final result in allResults) {
      counts[result.category] = (counts[result.category] ?? 0) + 1;
    }
    return counts;
  }
  
  Map<String, dynamic> toJson() => {
    'summary': {
      'timestamp': timestamp.toIso8601String(),
      'testDirectory': testDirectory,
      'totalFiles': totalFiles,
      'overallFrequencyRangeHz': overallFrequencyRange,
      'totalFileSizeMB': (totalFileSize / (1024 * 1024)).toStringAsFixed(2),
      'categoryBreakdown': categoryBreakdown,
    },
    'octaveStatistics': octaveStats.map((s) => s.toJson()).toList(),
    'detailedResults': allResults.map((r) => r.toJson()).toList(),
  };
}

/// シンプルベンチマーククラス
class SimpleBenchmark {
  final String testDirectory;
  
  SimpleBenchmark({required this.testDirectory});
  
  /// 全ベンチマーク実行
  Future<BenchmarkSummary> runFullBenchmark() async {
    print('🎯 C2～C4音域ファイル解析ベンチマーク開始');
    print('📁 テストディレクトリ: $testDirectory');
    print('');
    
    final allResults = <BenchmarkResult>[];
    
    // 1. 単音テスト解析
    print('🎼 単音テストファイル解析中...');
    final singleToneResults = await _analyzeSingleTones();
    allResults.addAll(singleToneResults);
    
    // 2. 音階テスト解析
    print('🎵 音階テストファイル解析中...');
    final scaleResults = await _analyzeScales();
    allResults.addAll(scaleResults);
    
    // 3. 楽器別テスト解析
    print('🎹 楽器別テストファイル解析中...');
    final instrumentResults = await _analyzeInstruments();
    allResults.addAll(instrumentResults);
    
    // 4. 動的テスト解析
    print('🌊 動的テストファイル解析中...');
    final dynamicResults = await _analyzeDynamic();
    allResults.addAll(dynamicResults);
    
    // 5. 特殊条件テスト解析
    print('⚙️ 特殊条件テストファイル解析中...');
    final conditionResults = await _analyzeConditions();
    allResults.addAll(conditionResults);
    
    // 6. オクターブ別統計計算
    final octaveStats = _calculateOctaveStats(allResults);
    
    final summary = BenchmarkSummary(
      timestamp: DateTime.now(),
      testDirectory: testDirectory,
      totalFiles: allResults.length,
      octaveStats: octaveStats,
      allResults: allResults,
    );
    
    // 7. 結果出力
    await _outputResults(summary);
    _printSummary(summary);
    
    return summary;
  }
  
  /// 単音テスト解析
  Future<List<BenchmarkResult>> _analyzeSingleTones() async {
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
      final fileSize = await File(file.path).length();
      
      if (expectedFreq == null || noteName == null) {
        print('⚠️  ファイル名から周波数を抽出できませんでした: $fileName');
        continue;
      }
      
      results.add(BenchmarkResult(
        fileName: fileName,
        noteName: noteName,
        expectedFrequency: expectedFreq,
        category: 'single_tone',
        filePath: file.path,
        fileSizeBytes: fileSize,
      ));
      
      print('  ✓ $noteName (${expectedFreq.toStringAsFixed(2)}Hz) - ${(fileSize/1024).toStringAsFixed(1)}KB');
    }
    
    return results;
  }
  
  /// 音階テスト解析
  Future<List<BenchmarkResult>> _analyzeScales() async {
    final results = <BenchmarkResult>[];
    final scalesDir = Directory('$testDirectory/scales');
    
    if (!await scalesDir.exists()) {
      print('❌ 音階テストディレクトリが見つかりません: $testDirectory/scales');
      return results;
    }
    
    final files = await scalesDir.list().where((f) => f.path.endsWith('.wav')).toList();
    
    for (final file in files) {
      final fileName = file.path.split('/').last;
      final fileSize = await File(file.path).length();
      
      // 音階ファイルからルート音を推定
      String rootNote = 'Unknown';
      double rootFreq = 0.0;
      
      if (fileName.contains('C2')) {
        rootNote = 'C2';
        rootFreq = 65.41;
      } else if (fileName.contains('C3')) {
        rootNote = 'C3';
        rootFreq = 130.81;
      }
      
      results.add(BenchmarkResult(
        fileName: fileName,
        noteName: rootNote,
        expectedFrequency: rootFreq,
        category: 'scale',
        filePath: file.path,
        fileSizeBytes: fileSize,
      ));
      
      print('  ✓ ${fileName.replaceAll('.wav', '')} - ${(fileSize/1024).toStringAsFixed(1)}KB');
    }
    
    return results;
  }
  
  /// 楽器別テスト解析
  Future<List<BenchmarkResult>> _analyzeInstruments() async {
    final results = <BenchmarkResult>[];
    final instrumentsDir = Directory('$testDirectory/instruments');
    
    if (!await instrumentsDir.exists()) {
      print('❌ 楽器テストディレクトリが見つかりません: $testDirectory/instruments');
      return results;
    }
    
    final instrumentTypes = await instrumentsDir.list().where((d) => d is Directory).toList();
    
    for (final instrumentDir in instrumentTypes) {
      final instrumentName = instrumentDir.path.split('/').last;
      print('  🎻 $instrumentName ファイル解析中...');
      
      final files = await Directory(instrumentDir.path).list()
          .where((f) => f.path.endsWith('.wav')).toList();
      
      for (final file in files) {
        final fileName = file.path.split('/').last;
        final noteName = _extractNoteNameFromInstrumentFile(fileName);
        final expectedFreq = _getNoteFrequency(noteName);
        final fileSize = await File(file.path).length();
        
        if (expectedFreq == null || noteName == null) {
          print('    ⚠️  楽器ファイルから情報を抽出できませんでした: $fileName');
          continue;
        }
        
        results.add(BenchmarkResult(
          fileName: fileName,
          noteName: noteName,
          expectedFrequency: expectedFreq,
          category: 'instrument_$instrumentName',
          filePath: file.path,
          fileSizeBytes: fileSize,
        ));
        
        print('    ✓ $noteName ($instrumentName) - ${(fileSize/1024).toStringAsFixed(1)}KB');
      }
    }
    
    return results;
  }
  
  /// 動的テスト解析
  Future<List<BenchmarkResult>> _analyzeDynamic() async {
    final results = <BenchmarkResult>[];
    final dynamicDir = Directory('$testDirectory/dynamic');
    
    if (!await dynamicDir.exists()) {
      print('❌ 動的テストディレクトリが見つかりません: $testDirectory/dynamic');
      return results;
    }
    
    final subDirs = await dynamicDir.list().where((d) => d is Directory).toList();
    
    for (final subDir in subDirs) {
      final subDirName = subDir.path.split('/').last;
      final files = await Directory(subDir.path).list()
          .where((f) => f.path.endsWith('.wav')).toList();
      
      for (final file in files) {
        final fileName = file.path.split('/').last;
        final fileSize = await File(file.path).length();
        
        // 動的テストファイルから基準周波数を推定
        String noteName = 'Dynamic';
        double baseFreq = 0.0;
        
        if (fileName.contains('C2')) {
          noteName = 'C2 Dynamic';
          baseFreq = 65.41;
        } else if (fileName.contains('C3')) {
          noteName = 'C3 Dynamic';
          baseFreq = 130.81;
        } else if (fileName.contains('C4')) {
          noteName = 'C4 Dynamic';
          baseFreq = 261.63;
        }
        
        results.add(BenchmarkResult(
          fileName: fileName,
          noteName: noteName,
          expectedFrequency: baseFreq,
          category: 'dynamic_$subDirName',
          filePath: file.path,
          fileSizeBytes: fileSize,
        ));
        
        print('  ✓ ${fileName.replaceAll('.wav', '')} - ${(fileSize/1024).toStringAsFixed(1)}KB');
      }
    }
    
    return results;
  }
  
  /// 特殊条件テスト解析
  Future<List<BenchmarkResult>> _analyzeConditions() async {
    final results = <BenchmarkResult>[];
    final conditionsDir = Directory('$testDirectory/conditions');
    
    if (!await conditionsDir.exists()) {
      print('❌ 特殊条件テストディレクトリが見つかりません: $testDirectory/conditions');
      return results;
    }
    
    final subDirs = await conditionsDir.list().where((d) => d is Directory).toList();
    
    for (final subDir in subDirs) {
      final subDirName = subDir.path.split('/').last;
      final files = await Directory(subDir.path).list()
          .where((f) => f.path.endsWith('.wav')).toList();
      
      for (final file in files) {
        final fileName = file.path.split('/').last;
        final fileSize = await File(file.path).length();
        
        // C3ベース (130.81Hz) と仮定
        results.add(BenchmarkResult(
          fileName: fileName,
          noteName: 'C3',
          expectedFrequency: 130.81,
          category: 'condition_$subDirName',
          filePath: file.path,
          fileSizeBytes: fileSize,
        ));
        
        print('  ✓ ${fileName.replaceAll('.wav', '')} - ${(fileSize/1024).toStringAsFixed(1)}KB');
      }
    }
    
    return results;
  }
  
  /// オクターブ別統計計算
  List<OctaveStats> _calculateOctaveStats(List<BenchmarkResult> allResults) {
    final c2ToC3 = allResults.where((r) => 
        r.expectedFrequency >= 65.0 && r.expectedFrequency < 131.0).toList();
    final c3ToC4 = allResults.where((r) => 
        r.expectedFrequency >= 131.0 && r.expectedFrequency <= 262.0).toList();
    final other = allResults.where((r) => 
        r.expectedFrequency == 0.0 || r.expectedFrequency > 262.0).toList();
    
    return [
      OctaveStats('C2-C3 (低音域)', c2ToC3),
      OctaveStats('C3-C4 (中音域)', c3ToC4),
      if (other.isNotEmpty) OctaveStats('その他', other),
    ];
  }
  
  /// 結果出力
  Future<void> _outputResults(BenchmarkSummary summary) async {
    final outputDir = Directory('verification_results');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    
    final timestamp = summary.timestamp.toIso8601String().replaceAll(':', '-');
    final outputFile = File('verification_results/c2_c4_file_analysis_$timestamp.json');
    
    final jsonStr = JsonEncoder.withIndent('  ').convert(summary.toJson());
    await outputFile.writeAsString(jsonStr);
    
    print('📊 詳細結果出力: ${outputFile.path}');
  }
  
  /// サマリー表示
  void _printSummary(BenchmarkSummary summary) {
    print('');
    print('📈 === ファイル解析結果サマリー ===');
    print('📁 解析ファイル数: ${summary.totalFiles}');
    print('📦 総ファイルサイズ: ${(summary.totalFileSize / (1024 * 1024)).toStringAsFixed(2)}MB');
    print('🎵 周波数範囲: ${summary.overallFrequencyRange.toStringAsFixed(1)}Hz');
    print('');
    
    print('📊 カテゴリ別内訳:');
    summary.categoryBreakdown.forEach((category, count) {
      print('  • $category: $count ファイル');
    });
    print('');
    
    for (final octave in summary.octaveStats) {
      print('🎵 ${octave.octaveName}:');
      print('  • ファイル数: ${octave.results.length}');
      print('  • 周波数範囲: ${octave.frequencyRangeMin.toStringAsFixed(1)}Hz - ${octave.frequencyRangeMax.toStringAsFixed(1)}Hz');
      print('  • 平均周波数: ${octave.averageFrequency.toStringAsFixed(1)}Hz');
      print('  • ファイルサイズ: ${(octave.totalFileSize / (1024 * 1024)).toStringAsFixed(2)}MB');
      print('  • カテゴリ内訳: ${octave.categoryCount}');
      print('');
    }
    
    print('✅ 検証準備完了！');
    print('📝 次のステップ:');
    print('  1. ピッチ検出サービスのFlutter非依存版作成');
    print('  2. 実際のピッチ検出精度測定実装');
    print('  3. 1000回反復ベンチマーク実行');
  }
  
  /// ファイル名から周波数抽出
  double? _extractFrequencyFromFileName(String fileName) {
    // 先にシャープ記号を含む音階名から周波数を取得
    final sharpRegex = RegExp(r'^([A-G]sharp[0-9])_');
    final sharpMatch = sharpRegex.firstMatch(fileName);
    if (sharpMatch != null) {
      final noteName = sharpMatch.group(1)!.replaceAll('sharp', '#');
      return _getNoteFrequency(noteName);
    }
    
    // 通常の周波数情報の抽出
    final regex = RegExp(r'(\d+\.\d+)Hz');
    final match = regex.firstMatch(fileName);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }
  
  /// ファイル名から音階名抽出
  String? _extractNoteNameFromFileName(String fileName) {
    // シャープ記号の処理を改善
    final sharpRegex = RegExp(r'^([A-G]sharp[0-9])_');
    final sharpMatch = sharpRegex.firstMatch(fileName);
    if (sharpMatch != null) {
      return sharpMatch.group(1)!.replaceAll('sharp', '#');
    }
    
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
  
  CliArgs({required this.testDirectory});
  
  static CliArgs parse(List<String> args) {
    String testDirectory = 'test_audio_c2_c4';
    
    for (int i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--test-dir':
          if (i + 1 < args.length) testDirectory = args[++i];
          break;
        case '--help':
          _printHelp();
          exit(0);
      }
    }
    
    return CliArgs(testDirectory: testDirectory);
  }
  
  static void _printHelp() {
    print('''
C2～C4音域ファイル解析ベンチマークツール

使用法:
  dart tools/benchmark/simple_benchmark.dart [オプション]

オプション:
  --test-dir <dir>     テストディレクトリ (デフォルト: test_audio_c2_c4)
  --help               このヘルプを表示

例:
  dart tools/benchmark/simple_benchmark.dart
  dart tools/benchmark/simple_benchmark.dart --test-dir my_test_audio
''');
  }
}

/// メイン実行
Future<void> main(List<String> args) async {
  final config = CliArgs.parse(args);
  
  print('🎯 C2～C4音域ファイル解析ベンチマークツール');
  print('');
  
  final benchmark = SimpleBenchmark(testDirectory: config.testDirectory);
  
  try {
    await benchmark.runFullBenchmark();
    print('');
    print('🎉 ファイル解析完了！');
    
  } catch (e) {
    print('❌ エラー: $e');
    exit(1);
  }
}
