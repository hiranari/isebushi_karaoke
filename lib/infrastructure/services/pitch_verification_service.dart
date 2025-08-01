import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;
import '../../domain/interfaces/i_pitch_verification_service.dart';
import '../../domain/interfaces/i_logger.dart';
import '../../domain/models/pitch_verification_result.dart';
import 'pitch_detection_service.dart';
import 'cache_service.dart';

/// ピッチ検証サービス実装
/// 
/// 基準ピッチデータの検証、統計分析、JSON出力を実装
/// カラオケ画面とツールの共通ロジックを提供
class PitchVerificationService implements IPitchVerificationService {
  final PitchDetectionService _pitchDetectionService;
  final ILogger _logger;

  PitchVerificationService({
    required PitchDetectionService pitchDetectionService,
    required ILogger logger,
  }) : _pitchDetectionService = pitchDetectionService,
       _logger = logger;

  /// サービス初期化
  void initialize() {
    _pitchDetectionService.initialize();
  }

  @override
  Future<PitchVerificationResult> verifyPitchData(
    String wavFilePath, {
    bool useCache = true,
  }) async {
    final pitches = await extractReferencePitches(
      wavFilePath,
      useCache: useCache,
    );

    // キャッシュ確認
    final cachedResult = useCache 
        ? await CacheService.loadFromCache(wavFilePath)
        : null;
    
    final statistics = _calculateStatistics(pitches);
    
    return PitchVerificationResult(
      wavFilePath: wavFilePath,
      analyzedAt: cachedResult?.createdAt ?? DateTime.now(),
      pitches: pitches,
      statistics: statistics,
      fromCache: cachedResult != null,
    );
  }

  @override
  Future<List<double>> extractReferencePitches(
    String wavFilePath, {
    bool useCache = true,
  }) async {
    // キャッシュチェック
    if (useCache) {
      final cachedResult = await CacheService.loadFromCache(wavFilePath);
      if (cachedResult != null) {
        return cachedResult.pitches;
      }
    }

    // 新規解析
    final analysisResult = await _pitchDetectionService.extractPitchFromAudio(
      sourcePath: wavFilePath,
      isAsset: true,
    );

    // キャッシュに保存
    if (useCache) {
      await CacheService.saveToCache(wavFilePath, analysisResult);
    }

    return analysisResult.pitches;
  }

  @override
  Future<void> exportToJson(
    PitchVerificationResult result,
    String outputPath,
  ) async {
    // 出力ディレクトリ確保
    await _ensureOutputDirectory(outputPath);
    
    // JSON形式でファイル出力
    final file = File(outputPath);
    final jsonString = _formatJsonOutput(result.toJson());
    await file.writeAsString(jsonString);
  }

  @override
  ComparisonStats compareWithReference(
    List<double> pitches,
    List<double> referencePitches,
  ) {
    if (pitches.isEmpty || referencePitches.isEmpty) {
      return const ComparisonStats(
        similarity: 0.0,
        rmse: double.infinity,
        correlation: 0.0,
        differences: [],
        comparisonSummary: 'データが不足しています',
      );
    }

    // 長さを合わせる（短い方に揃える）
    final minLength = math.min(pitches.length, referencePitches.length);
    final pitch1 = pitches.take(minLength).toList();
    final pitch2 = referencePitches.take(minLength).toList();

    // 差分計算
    final differences = <double>[];
    for (int i = 0; i < minLength; i++) {
      differences.add((pitch1[i] - pitch2[i]).abs());
    }

    // RMSE計算
    final squaredDiffs = differences.map((d) => d * d);
    final rmse = math.sqrt(squaredDiffs.reduce((a, b) => a + b) / minLength);

    // 相関係数計算
    final correlation = _calculateCorrelation(pitch1, pitch2);

    // 類似度計算（RMSEベース、0-1スケール）
    final maxPitch = math.max(
      pitch1.reduce(math.max),
      pitch2.reduce(math.max),
    );
    final similarity = math.max(0.0, 1.0 - (rmse / maxPitch));

    // サマリー生成
    final summary = _generateComparisonSummary(similarity, rmse, correlation);

    return ComparisonStats(
      similarity: similarity,
      rmse: rmse,
      correlation: correlation,
      differences: differences,
      comparisonSummary: summary,
    );
  }

  /// ピッチデータの統計情報を計算
  PitchStatistics _calculateStatistics(List<double> pitches) {
    if (pitches.isEmpty) {
      return const PitchStatistics(
        totalCount: 0,
        validCount: 0,
        invalidCount: 0,
        validRate: 0.0,
        minPitch: 0.0,
        maxPitch: 0.0,
        avgPitch: 0.0,
        pitchRange: 0.0,
        isInExpectedRange: false,
        firstTen: [],
        lastTen: [],
      );
    }

    final validPitches = pitches.where((p) => p > 0).toList();
    final invalidCount = pitches.length - validPitches.length;
    final validRate = (validPitches.length / pitches.length) * 100;

    double minPitch = 0.0;
    double maxPitch = 0.0;
    double avgPitch = 0.0;

    if (validPitches.isNotEmpty) {
      minPitch = validPitches.reduce(math.min);
      maxPitch = validPitches.reduce(math.max);
      avgPitch = validPitches.reduce((a, b) => a + b) / validPitches.length;
    }

    final pitchRange = maxPitch - minPitch;
    final isInExpectedRange = _isInExpectedRange(minPitch, maxPitch);

    // 最初と最後の10個を取得
    final firstTen = pitches.take(math.min(10, pitches.length)).toList();
    final lastTen = pitches.length > 10
        ? pitches.skip(pitches.length - 10).toList()
        : pitches;

    return PitchStatistics(
      totalCount: pitches.length,
      validCount: validPitches.length,
      invalidCount: invalidCount,
      validRate: validRate,
      minPitch: minPitch,
      maxPitch: maxPitch,
      avgPitch: avgPitch,
      pitchRange: pitchRange,
      isInExpectedRange: isInExpectedRange,
      firstTen: firstTen,
      lastTen: lastTen,
    );
  }

  /// 期待範囲内かどうかを判定（C4-C5: 261.63-523.25Hz）
  bool _isInExpectedRange(double minPitch, double maxPitch) {
    const expectedMin = 261.63; // C4 ド
    const expectedMax = 523.25; // C5 ド
    const tolerance = 0.1; // 10%の許容誤差

    return minPitch >= expectedMin * (1 - tolerance) &&
           maxPitch <= expectedMax * (1 + tolerance);
  }

  /// 出力ディレクトリを確保
  Future<void> _ensureOutputDirectory(String outputPath) async {
    final file = File(outputPath);
    final directory = file.parent;
    
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  /// JSON出力のフォーマット
  String _formatJsonOutput(Map<String, dynamic> json) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(json);
  }

  /// 相関係数を計算
  double _calculateCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.isEmpty) return 0.0;

    final n = x.length;
    final sumX = x.reduce((a, b) => a + b);
    final sumY = y.reduce((a, b) => a + b);
    final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
    final sumX2 = x.map((v) => v * v).reduce((a, b) => a + b);
    final sumY2 = y.map((v) => v * v).reduce((a, b) => a + b);

    final numerator = n * sumXY - sumX * sumY;
    final denominator = math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY));

    return denominator != 0 ? numerator / denominator : 0.0;
  }

  /// 比較結果のサマリーを生成
  String _generateComparisonSummary(double similarity, double rmse, double correlation) {
    if (similarity > 0.9) {
      return '非常に高い類似度';
    } else if (similarity > 0.7) {
      return '高い類似度';
    } else if (similarity > 0.5) {
      return '中程度の類似度';
    } else if (similarity > 0.3) {
      return '低い類似度';
    } else {
      return '非常に低い類似度';
    }
  }
}
