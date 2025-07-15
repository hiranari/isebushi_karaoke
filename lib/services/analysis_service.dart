import 'dart:math' as math;
import '../models/song_result.dart';

/// Phase 3: 詳細分析を担当するサービスクラス
/// 
/// 単一責任原則: 分析ロジックのみに専念
/// 分離原則: スコアリングとは独立した分析処理
class AnalysisService {
  /// 包括的な分析を実行
  /// 
  /// [recordedPitches] 録音されたピッチデータ
  /// [referencePitches] 基準ピッチデータ
  /// [songDuration] 楽曲の総時間
  /// 戻り値: AnalysisData 詳細分析結果
  static AnalysisData performDetailedAnalysis({
    required List<double> recordedPitches,
    required List<double> referencePitches,
    required Duration songDuration,
  }) {
    // ピッチ差分計算
    final pitchDifferences = _calculatePitchDifferences(recordedPitches, referencePitches);
    
    // 安定性分析
    final pitchVariance = _calculatePitchVariance(recordedPitches);
    final stabilityOverTime = _calculateStabilityOverTime(recordedPitches);
    
    // タイミング分析
    final timingPoints = _analyzeTimingPoints(recordedPitches, referencePitches, songDuration);
    final averageTimingAccuracy = _calculateAverageTimingAccuracy(timingPoints);
    
    // 統計情報
    final statistics = _generateStatistics(recordedPitches, referencePitches, pitchDifferences);

    return AnalysisData(
      recordedPitches: recordedPitches,
      referencePitches: referencePitches,
      pitchDifferences: pitchDifferences,
      pitchVariance: pitchVariance,
      stabilityOverTime: stabilityOverTime,
      timingPoints: timingPoints,
      averageTimingAccuracy: averageTimingAccuracy,
      statistics: statistics,
    );
  }

  /// ピッチ差分の計算
  static List<double> _calculatePitchDifferences(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    final differences = <double>[];
    final minLength = math.min(recordedPitches.length, referencePitches.length);

    for (int i = 0; i < minLength; i++) {
      final recorded = recordedPitches[i];
      final reference = referencePitches[i];

      if (recorded > 0 && reference > 0) {
        differences.add(recorded - reference);
      } else {
        differences.add(0.0); // 無音部分
      }
    }

    return differences;
  }

  /// ピッチ分散の計算
  static double _calculatePitchVariance(List<double> recordedPitches) {
    final validPitches = recordedPitches.where((p) => p > 0).toList();
    if (validPitches.length < 2) return 0.0;

    final mean = validPitches.reduce((a, b) => a + b) / validPitches.length;
    final variance = validPitches
        .map((p) => math.pow(p - mean, 2))
        .reduce((a, b) => a + b) / validPitches.length;

    return variance;
  }

  /// 時間経過に伴う安定性の変化を分析
  static List<double> _calculateStabilityOverTime(List<double> recordedPitches) {
    const int windowSize = 10; // 10フレームの移動窓
    final stabilityScores = <double>[];

    for (int i = 0; i < recordedPitches.length - windowSize + 1; i++) {
      final window = recordedPitches.sublist(i, i + windowSize);
      final validPitches = window.where((p) => p > 0).toList();

      if (validPitches.length >= 3) {
        final mean = validPitches.reduce((a, b) => a + b) / validPitches.length;
        final variance = validPitches
            .map((p) => math.pow(p - mean, 2))
            .reduce((a, b) => a + b) / validPitches.length;
        
        final standardDeviation = math.sqrt(variance);
        // 安定性スコア: 標準偏差が小さいほど高スコア (0-100)
        final stabilityScore = math.max(0.0, 100.0 - standardDeviation * 3);
        stabilityScores.add(stabilityScore);
      } else {
        stabilityScores.add(0.0);
      }
    }

    return stabilityScores;
  }

  /// タイミング分析ポイントの生成
  static List<TimingPoint> _analyzeTimingPoints(
    List<double> recordedPitches,
    List<double> referencePitches,
    Duration songDuration,
  ) {
    final timingPoints = <TimingPoint>[];
    final minLength = math.min(recordedPitches.length, referencePitches.length);
    
    if (minLength == 0) return timingPoints;

    final intervalMs = songDuration.inMilliseconds / minLength;

    for (int i = 0; i < minLength; i++) {
      final timestamp = Duration(milliseconds: (i * intervalMs).round());
      final recorded = recordedPitches[i];
      final reference = referencePitches[i];

      // タイミング精度の計算
      double timingAccuracy = 1.0;
      if (recorded > 0 && reference > 0) {
        // 音程変化の検出と同期評価
        timingAccuracy = _calculateNoteTimingAccuracy(
          recordedPitches, referencePitches, i
        );
      } else if (recorded <= 0 && reference <= 0) {
        timingAccuracy = 1.0; // 両方とも無音なら完璧
      } else {
        timingAccuracy = 0.0; // 片方だけ音が出ているならタイミングずれ
      }

      timingPoints.add(TimingPoint(
        timestamp: timestamp,
        expectedPitch: reference,
        actualPitch: recorded,
        timingAccuracy: timingAccuracy,
      ));
    }

    return timingPoints;
  }

  /// 個別ノートのタイミング精度計算
  static double _calculateNoteTimingAccuracy(
    List<double> recordedPitches,
    List<double> referencePitches,
    int index,
  ) {
    // 前後のフレームを見て音程変化のタイミングを評価
    const int lookAround = 3;
    final start = math.max(0, index - lookAround);
    final end = math.min(recordedPitches.length, index + lookAround + 1);

    // 基準と録音の音程変化パターンを比較
    final referencePattern = _extractPattern(referencePitches, start, end);
    final recordedPattern = _extractPattern(recordedPitches, start, end);

    // パターンの類似度をタイミング精度として使用
    return _calculatePatternSimilarity(referencePattern, recordedPattern);
  }

  /// 音程変化パターンの抽出
  static List<double> _extractPattern(List<double> pitches, int start, int end) {
    final pattern = <double>[];
    for (int i = start; i < end - 1; i++) {
      if (i + 1 < pitches.length) {
        final current = pitches[i];
        final next = pitches[i + 1];
        if (current > 0 && next > 0) {
          pattern.add(next - current); // 音程変化量
        } else {
          pattern.add(0.0);
        }
      }
    }
    return pattern;
  }

  /// パターン類似度の計算
  static double _calculatePatternSimilarity(List<double> pattern1, List<double> pattern2) {
    if (pattern1.isEmpty || pattern2.isEmpty) return 0.0;
    
    final minLength = math.min(pattern1.length, pattern2.length);
    double similarity = 0.0;

    for (int i = 0; i < minLength; i++) {
      final diff = (pattern1[i] - pattern2[i]).abs();
      // 差が少ないほど高い類似度
      similarity += math.max(0.0, 1.0 - (diff / 50.0)); // 50Hz差で類似度0
    }

    return minLength > 0 ? similarity / minLength : 0.0;
  }

  /// 平均タイミング精度の計算
  static double _calculateAverageTimingAccuracy(List<TimingPoint> timingPoints) {
    if (timingPoints.isEmpty) return 0.0;

    final totalAccuracy = timingPoints
        .map((tp) => tp.timingAccuracy)
        .reduce((a, b) => a + b);

    return totalAccuracy / timingPoints.length;
  }

  /// 統計情報の生成
  static AnalysisStatistics _generateStatistics(
    List<double> recordedPitches,
    List<double> referencePitches,
    List<double> pitchDifferences,
  ) {
    final minLength = math.min(recordedPitches.length, referencePitches.length);
    int totalNotes = 0;
    int accurateNotes = 0;
    final validDifferences = <double>[];

    for (int i = 0; i < minLength; i++) {
      if (recordedPitches[i] > 0 && referencePitches[i] > 0) {
        totalNotes++;
        final diff = pitchDifferences[i].abs();
        validDifferences.add(diff);
        
        if (diff <= 30.0) { // 30Hz以内で正確とみなす
          accurateNotes++;
        }
      }
    }

    final accuracyRate = totalNotes > 0 ? accurateNotes / totalNotes : 0.0;
    
    double averageDiff = 0.0;
    double maxDiff = 0.0;
    double minDiff = 0.0;

    if (validDifferences.isNotEmpty) {
      averageDiff = validDifferences.reduce((a, b) => a + b) / validDifferences.length;
      maxDiff = validDifferences.reduce(math.max);
      minDiff = validDifferences.reduce(math.min);
    }

    return AnalysisStatistics(
      totalNotes: totalNotes,
      accurateNotes: accurateNotes,
      accuracyRate: accuracyRate,
      averagePitchDifference: averageDiff,
      maxPitchDifference: maxDiff,
      minPitchDifference: minDiff,
    );
  }
}