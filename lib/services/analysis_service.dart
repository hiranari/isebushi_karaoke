import 'dart:math' as math;
import '../models/song_result.dart';
import 'scoring_service.dart';

/// 詳細分析を担当するサービスクラス
/// Phase 3: 歌唱データの詳細解析とグラフ用データ生成
class AnalysisService {
  // 分析用定数
  static const double FRAME_DURATION_SECONDS = 0.032; // 約32ms（16kHz/512サンプル）
  static const int SMOOTHING_WINDOW = 3; // スムージング用ウィンドウサイズ

  /// 詳細分析を実行
  static DetailedAnalysis performDetailedAnalysis({
    required List<double> recordedPitches,
    required List<double> referencePitches,
    required ComprehensiveScore score,
  }) {
    final pitchGraph = _generatePitchGraph(recordedPitches, referencePitches);
    final statistics = _calculateStatistics(recordedPitches, referencePitches);
    final strengths = _identifyStrengths(score, statistics);
    final weaknesses = _identifyWeaknesses(score, statistics);

    return DetailedAnalysis(
      pitchGraph: pitchGraph,
      statistics: statistics,
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }

  /// 音程グラフ用データを生成
  static List<PitchPoint> _generatePitchGraph(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    final maxLength = math.max(recordedPitches.length, referencePitches.length);
    List<PitchPoint> points = [];

    for (int i = 0; i < maxLength; i++) {
      final timeSeconds = i * FRAME_DURATION_SECONDS;
      final recordedPitch = i < recordedPitches.length ? recordedPitches[i] : null;
      final referencePitch = i < referencePitches.length ? referencePitches[i] : null;
      
      double? difference;
      if (recordedPitch != null && referencePitch != null && 
          recordedPitch > 0 && referencePitch > 0) {
        difference = ScoringService.calculateCentDifference(referencePitch, recordedPitch);
      }

      points.add(PitchPoint(
        timeSeconds: timeSeconds,
        recordedPitch: recordedPitch,
        referencePitch: referencePitch,
        difference: difference,
      ));
    }

    return points;
  }

  /// 統計情報を計算
  static Map<String, double> _calculateStatistics(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    Map<String, double> stats = {};

    // 基本統計
    final validRecorded = recordedPitches.where((p) => p > 0).toList();
    final validReference = referencePitches.where((p) => p > 0).toList();

    if (validRecorded.isNotEmpty) {
      stats['recordedAverage'] = validRecorded.reduce((a, b) => a + b) / validRecorded.length;
      stats['recordedMin'] = validRecorded.reduce(math.min);
      stats['recordedMax'] = validRecorded.reduce(math.max);
      stats['recordedRange'] = stats['recordedMax']! - stats['recordedMin']!;
    }

    if (validReference.isNotEmpty) {
      stats['referenceAverage'] = validReference.reduce((a, b) => a + b) / validReference.length;
      stats['referenceMin'] = validReference.reduce(math.min);
      stats['referenceMax'] = validReference.reduce(math.max);
      stats['referenceRange'] = stats['referenceMax']! - stats['referenceMin']!;
    }

    // カバレッジ統計
    stats['pitchCoverage'] = validRecorded.length / recordedPitches.length;
    stats['songCoverage'] = recordedPitches.length / referencePitches.length;

    // 精度統計
    if (validRecorded.isNotEmpty && validReference.isNotEmpty) {
      final minLength = math.min(validRecorded.length, validReference.length);
      double totalAbsError = 0.0;
      double totalSquaredError = 0.0;
      int perfectCount = 0;
      int goodCount = 0;

      for (int i = 0; i < minLength; i++) {
        final error = (validRecorded[i] - validReference[i]).abs();
        totalAbsError += error;
        totalSquaredError += error * error;

        if (error <= ScoringService.PERFECT_PITCH_THRESHOLD) perfectCount++;
        if (error <= ScoringService.GOOD_PITCH_THRESHOLD) goodCount++;
      }

      stats['meanAbsoluteError'] = totalAbsError / minLength;
      stats['rootMeanSquaredError'] = math.sqrt(totalSquaredError / minLength);
      stats['perfectPitchRatio'] = perfectCount / minLength;
      stats['goodPitchRatio'] = goodCount / minLength;
    }

    // 安定性統計
    if (validRecorded.length > 1) {
      List<double> variations = [];
      for (int i = 1; i < validRecorded.length; i++) {
        variations.add((validRecorded[i] - validRecorded[i - 1]).abs());
      }
      stats['averageVariation'] = variations.reduce((a, b) => a + b) / variations.length;
      stats['maxVariation'] = variations.reduce(math.max);
    }

    return stats;
  }

  /// 強みを特定
  static List<String> _identifyStrengths(
    ComprehensiveScore score,
    Map<String, double> statistics,
  ) {
    List<String> strengths = [];

    // 音程精度の強み
    if (score.pitchAccuracy >= 85) {
      strengths.add('音程の精度が非常に高いです');
    } else if (score.pitchAccuracy >= 70) {
      strengths.add('音程が安定しています');
    }

    // 完璧な音程の割合
    final perfectRatio = statistics['perfectPitchRatio'] ?? 0.0;
    if (perfectRatio >= 0.7) {
      strengths.add('正確な音程で歌えている部分が多いです');
    }

    // 安定性の強み
    if (score.stability >= 80) {
      strengths.add('音程が非常に安定しています');
    } else if (score.stability >= 65) {
      strengths.add('ブレが少なく歌えています');
    }

    // タイミングの強み
    if (score.timing >= 80) {
      strengths.add('タイミングが正確です');
    }

    // カバレッジの強み
    final coverage = statistics['songCoverage'] ?? 0.0;
    if (coverage >= 0.9) {
      strengths.add('楽曲全体を通して歌えています');
    }

    // 音域の強み
    final recordedRange = statistics['recordedRange'] ?? 0.0;
    final referenceRange = statistics['referenceRange'] ?? 0.0;
    if (recordedRange >= referenceRange * 0.8) {
      strengths.add('幅広い音域で歌えています');
    }

    if (strengths.isEmpty) {
      strengths.add('歌唱にチャレンジする気持ちが素晴らしいです');
    }

    return strengths;
  }

  /// 弱点・改善点を特定
  static List<String> _identifyWeaknesses(
    ComprehensiveScore score,
    Map<String, double> statistics,
  ) {
    List<String> weaknesses = [];

    // 音程精度の弱点
    if (score.pitchAccuracy < 60) {
      weaknesses.add('音程の精度に改善の余地があります');
    }

    final meanError = statistics['meanAbsoluteError'] ?? 0.0;
    if (meanError > ScoringService.GOOD_PITCH_THRESHOLD) {
      weaknesses.add('基準音程からのズレが大きい傾向があります');
    }

    // 安定性の弱点
    if (score.stability < 60) {
      weaknesses.add('音程の安定性を改善しましょう');
    }

    final avgVariation = statistics['averageVariation'] ?? 0.0;
    if (avgVariation > ScoringService.UNSTABLE_VARIATION_THRESHOLD) {
      weaknesses.add('音程の変動が大きすぎます');
    }

    // タイミングの弱点
    if (score.timing < 60) {
      weaknesses.add('タイミングの調整が必要です');
    }

    // カバレッジの弱点
    final coverage = statistics['songCoverage'] ?? 0.0;
    if (coverage < 0.7) {
      weaknesses.add('楽曲の後半部分も歌ってみましょう');
    }

    final pitchCoverage = statistics['pitchCoverage'] ?? 0.0;
    if (pitchCoverage < 0.6) {
      weaknesses.add('声を出せていない部分が多くあります');
    }

    return weaknesses;
  }

  /// グラフ表示用にデータをスムージング
  static List<PitchPoint> smoothPitchGraph(List<PitchPoint> originalPoints) {
    if (originalPoints.length <= SMOOTHING_WINDOW) return originalPoints;

    List<PitchPoint> smoothedPoints = [];

    for (int i = 0; i < originalPoints.length; i++) {
      final start = math.max(0, i - SMOOTHING_WINDOW ~/ 2);
      final end = math.min(originalPoints.length - 1, i + SMOOTHING_WINDOW ~/ 2);

      double recordedSum = 0.0;
      double referenceSum = 0.0;
      int recordedCount = 0;
      int referenceCount = 0;

      for (int j = start; j <= end; j++) {
        final point = originalPoints[j];
        if (point.recordedPitch != null && point.recordedPitch! > 0) {
          recordedSum += point.recordedPitch!;
          recordedCount++;
        }
        if (point.referencePitch != null && point.referencePitch! > 0) {
          referenceSum += point.referencePitch!;
          referenceCount++;
        }
      }

      final recordedAvg = recordedCount > 0 ? recordedSum / recordedCount : null;
      final referenceAvg = referenceCount > 0 ? referenceSum / referenceCount : null;

      double? difference;
      if (recordedAvg != null && referenceAvg != null) {
        difference = ScoringService.calculateCentDifference(referenceAvg, recordedAvg);
      }

      smoothedPoints.add(PitchPoint(
        timeSeconds: originalPoints[i].timeSeconds,
        recordedPitch: recordedAvg,
        referencePitch: referenceAvg,
        difference: difference,
      ));
    }

    return smoothedPoints;
  }
}