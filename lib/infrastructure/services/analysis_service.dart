import 'dart:math' as math;
import '../../domain/models/comprehensive_score.dart';
import '../../domain/models/improvement_suggestion.dart';
import 'scoring_service.dart';

/// 詳細分析を担当するサービスクラス
/// Phase 3: 歌唱データの詳細解析とグラフ用データ生成
class AnalysisService {
  // 分析用定数
  static const double frameDurationSeconds = 0.032; // 約32ms（16kHz/512サンプル）
  static const int smoothingWindow = 3; // スムージング用ウィンドウサイズ

  /// ピッチ精度の分析
  Map<String, dynamic> analyzePitchAccuracy(
    List<double> referencePitches,
    List<double> recordedPitches,
  ) {
    return _analyzePitchAccuracy(recordedPitches, referencePitches);
  }

  /// 安定性の分析
  Map<String, dynamic> analyzeStability(List<double> pitches) {
    return _analyzeStability(pitches);
  }

  /// タイミングの分析
  Map<String, dynamic> analyzeTiming(
    List<double> referencePitches,
    List<double> recordedPitches,
  ) {
    return _analyzeTimingAccuracy(recordedPitches, referencePitches);
  }

  /// 音質の分析
  Map<String, dynamic> analyzeAudioQuality(List<int> audioData) {
    // シンプルな音質分析を実装
    if (audioData.isEmpty) return {'quality': 0.0, 'clarity': 0.0, 'noiseLevel': 100.0};
    
    const quality = 75.0; // デフォルト値
    const clarity = 80.0; // デフォルト値
    const noiseLevel = 20.0; // デフォルト値
    
    return {
      'quality': quality,
      'clarity': clarity,
      'noiseLevel': noiseLevel,
    };
  }

  /// 詳細分析を実行
  static DetailedAnalysis performDetailedAnalysis({
    required List<double> recordedPitches,
    required List<double> referencePitches,
    required ComprehensiveScore score,
  }) {
    final pitchAnalysis = _analyzePitchAccuracy(recordedPitches, referencePitches);
    final timingAnalysis = _analyzeTimingAccuracy(recordedPitches, referencePitches);
    final stabilityAnalysis = _analyzeStability(recordedPitches);
    final sectionScores = _calculateSectionScores(recordedPitches, referencePitches);

    return DetailedAnalysis(
      pitchAnalysis: pitchAnalysis,
      timingAnalysis: timingAnalysis,
      stabilityAnalysis: stabilityAnalysis,
      sectionScores: sectionScores,
    );
  }

  /// 音程精度の分析
  static Map<String, dynamic> _analyzePitchAccuracy(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    final differences = <double>[];
    final validPoints = <Map<String, double>>[];

    final maxLength = math.max(recordedPitches.length, referencePitches.length);
    
    for (int i = 0; i < maxLength; i++) {
      final timeSeconds = i * frameDurationSeconds;
      final recordedPitch = i < recordedPitches.length ? recordedPitches[i] : null;
      final referencePitch = i < referencePitches.length ? referencePitches[i] : null;
      
      if (recordedPitch != null && referencePitch != null && 
          recordedPitch > 0 && referencePitch > 0) {
        final difference = ScoringService.calculateCentDifference(referencePitch, recordedPitch);
        differences.add(difference.abs());
        
        validPoints.add({
          'timestamp': timeSeconds,
          'recordedPitch': recordedPitch,
          'referencePitch': referencePitch,
          'deviation': difference,
        });
      }
    }

    final meanError = differences.isNotEmpty 
        ? differences.reduce((a, b) => a + b) / differences.length 
        : 0.0;
    
    final perfectCount = differences.where((d) => d < 20).length;
    final perfectRatio = differences.isNotEmpty ? perfectCount / differences.length : 0.0;

    return {
      'validPoints': validPoints,
      'meanAbsoluteError': meanError,
      'perfectPitchRatio': perfectRatio,
      'totalPoints': maxLength,
      'validPointsCount': validPoints.length,
    };
  }

  /// タイミング精度の分析
  static Map<String, dynamic> _analyzeTimingAccuracy(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    // 歌唱カバレッジの計算
    final recordedDuration = recordedPitches.length * frameDurationSeconds;
    final referenceDuration = referencePitches.length * frameDurationSeconds;
    final coverage = referenceDuration > 0 ? recordedDuration / referenceDuration : 0.0;

    // 歌唱開始・終了タイミングの分析
    final recordedStart = _findFirstValidPitch(recordedPitches);
    final recordedEnd = _findLastValidPitch(recordedPitches);
    final referenceStart = _findFirstValidPitch(referencePitches);
    final referenceEnd = _findLastValidPitch(referencePitches);

    final startTiming = recordedStart != null && referenceStart != null 
        ? (recordedStart - referenceStart) * frameDurationSeconds
        : 0.0;
    
    final endTiming = recordedEnd != null && referenceEnd != null 
        ? (recordedEnd - referenceEnd) * frameDurationSeconds
        : 0.0;

    return {
      'songCoverage': coverage,
      'startTimingOffset': startTiming,
      'endTimingOffset': endTiming,
      'recordedDuration': recordedDuration,
      'referenceDuration': referenceDuration,
    };
  }

  /// 安定性の分析
  static Map<String, dynamic> _analyzeStability(List<double> recordedPitches) {
    final variations = <double>[];
    
    for (int i = 1; i < recordedPitches.length; i++) {
      if (recordedPitches[i] > 0 && recordedPitches[i - 1] > 0) {
        final variation = (recordedPitches[i] - recordedPitches[i - 1]).abs();
        variations.add(variation);
      }
    }

    final averageVariation = variations.isNotEmpty 
        ? variations.reduce((a, b) => a + b) / variations.length 
        : 0.0;
    
    final maxVariation = variations.isNotEmpty ? variations.reduce(math.max) : 0.0;

    return {
      'averageVariation': averageVariation,
      'maxVariation': maxVariation,
      'stabilityPoints': variations.length,
      'variations': variations,
    };
  }

  /// セクション別スコアの計算
  static Map<String, double> _calculateSectionScores(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    final sectionSize = math.max(1, recordedPitches.length ~/ 4); // 4分割
    final scores = <String, double>{};

    for (int section = 0; section < 4; section++) {
      final start = section * sectionSize;
      final end = math.min(recordedPitches.length, (section + 1) * sectionSize);
      
      if (start < recordedPitches.length) {
        final sectionRecorded = recordedPitches.sublist(start, end);
        final sectionReference = referencePitches.length > start 
            ? referencePitches.sublist(start, math.min(referencePitches.length, end))
            : <double>[];

        final sectionScore = _calculateSectionScore(sectionRecorded, sectionReference);
        scores['section${section + 1}'] = sectionScore;
      } else {
        scores['section${section + 1}'] = 0.0;
      }
    }

    return scores;
  }

  /// 単一セクションのスコア計算
  static double _calculateSectionScore(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    if (recordedPitches.isEmpty || referencePitches.isEmpty) return 0.0;

    double totalScore = 0.0;
    int validCount = 0;

    final maxLength = math.max(recordedPitches.length, referencePitches.length);
    
    for (int i = 0; i < maxLength; i++) {
      if (i < recordedPitches.length && i < referencePitches.length &&
          recordedPitches[i] > 0 && referencePitches[i] > 0) {
        final difference = ScoringService.calculateCentDifference(
          referencePitches[i], 
          recordedPitches[i]
        );
        final score = math.max(0.0, 100.0 - difference.abs());
        totalScore += score;
        validCount++;
      }
    }

    return validCount > 0 ? totalScore / validCount : 0.0;
  }

  /// 最初の有効なピッチのインデックスを検索
  static int? _findFirstValidPitch(List<double> pitches) {
    for (int i = 0; i < pitches.length; i++) {
      if (pitches[i] > 0) return i;
    }
    return null;
  }

  /// 最後の有効なピッチのインデックスを検索
  static int? _findLastValidPitch(List<double> pitches) {
    for (int i = pitches.length - 1; i >= 0; i--) {
      if (pitches[i] > 0) return i;
    }
    return null;
  }

  /// 統計情報の計算（後方互換性のため）
  static Map<String, double> calculateStatistics({
    required List<double> recordedPitches,
    required List<double> referencePitches,
  }) {
    final pitchAnalysis = _analyzePitchAccuracy(recordedPitches, referencePitches);
    final timingAnalysis = _analyzeTimingAccuracy(recordedPitches, referencePitches);
    final stabilityAnalysis = _analyzeStability(recordedPitches);

    return {
      'meanAbsoluteError': pitchAnalysis['meanAbsoluteError'] ?? 0.0,
      'perfectPitchRatio': pitchAnalysis['perfectPitchRatio'] ?? 0.0,
      'songCoverage': timingAnalysis['songCoverage'] ?? 0.0,
      'averageVariation': stabilityAnalysis['averageVariation'] ?? 0.0,
      'maxVariation': stabilityAnalysis['maxVariation'] ?? 0.0,
    };
  }
}
