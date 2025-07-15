import 'dart:math' as math;
import '../models/song_result.dart';

/// スコア計算を担当するサービスクラス
/// Phase 3: 多角的評価指標による詳細スコアリング
class ScoringService {
  // 音程精度評価のしきい値（Hz）
  static const double PERFECT_PITCH_THRESHOLD = 10.0; // 完璧とみなす範囲
  static const double GOOD_PITCH_THRESHOLD = 30.0; // 良いとみなす範囲
  static const double ACCEPTABLE_PITCH_THRESHOLD = 50.0; // 許容範囲

  // 安定性評価のしきい値
  static const double STABLE_VARIATION_THRESHOLD = 20.0; // 安定とみなす変動幅（Hz）
  static const double UNSTABLE_VARIATION_THRESHOLD = 50.0; // 不安定とみなす変動幅（Hz）

  // タイミング評価のしきい値
  static const double PERFECT_TIMING_THRESHOLD = 0.1; // 完璧なタイミング（秒）
  static const double GOOD_TIMING_THRESHOLD = 0.3; // 良いタイミング（秒）

  /// 総合スコアを計算
  static ComprehensiveScore calculateComprehensiveScore({
    required List<double> recordedPitches,
    required List<double> referencePitches,
  }) {
    final pitchAccuracy = _calculatePitchAccuracyScore(recordedPitches, referencePitches);
    final stability = _calculateStabilityScore(recordedPitches);
    final timing = _calculateTimingScore(recordedPitches, referencePitches);

    return ComprehensiveScore.calculate(
      pitchAccuracy: pitchAccuracy,
      stability: stability,
      timing: timing,
    );
  }

  /// 音程精度スコアを計算（70%の重み）
  static double _calculatePitchAccuracyScore(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    if (recordedPitches.isEmpty || referencePitches.isEmpty) return 0.0;

    final minLength = math.min(recordedPitches.length, referencePitches.length);
    double totalScore = 0.0;
    int validCount = 0;

    for (int i = 0; i < minLength; i++) {
      final recorded = recordedPitches[i];
      final reference = referencePitches[i];

      // 無効なピッチ（0Hz以下）はスキップ
      if (recorded <= 0 || reference <= 0) continue;

      final difference = (recorded - reference).abs();
      double pointScore = 0.0;

      if (difference <= PERFECT_PITCH_THRESHOLD) {
        pointScore = 100.0; // 完璧
      } else if (difference <= GOOD_PITCH_THRESHOLD) {
        // 線形補間でスコア計算
        pointScore = 100.0 - (difference - PERFECT_PITCH_THRESHOLD) / 
                    (GOOD_PITCH_THRESHOLD - PERFECT_PITCH_THRESHOLD) * 20.0;
      } else if (difference <= ACCEPTABLE_PITCH_THRESHOLD) {
        // 許容範囲内
        pointScore = 80.0 - (difference - GOOD_PITCH_THRESHOLD) / 
                    (ACCEPTABLE_PITCH_THRESHOLD - GOOD_PITCH_THRESHOLD) * 50.0;
      } else {
        // 許容範囲外
        pointScore = math.max(0.0, 30.0 - (difference - ACCEPTABLE_PITCH_THRESHOLD) * 0.5);
      }

      totalScore += pointScore;
      validCount++;
    }

    return validCount > 0 ? totalScore / validCount : 0.0;
  }

  /// 安定性スコアを計算（20%の重み）
  static double _calculateStabilityScore(List<double> recordedPitches) {
    if (recordedPitches.length < 2) return 0.0;

    final validPitches = recordedPitches.where((p) => p > 0).toList();
    if (validPitches.length < 2) return 0.0;

    // 連続する音程の変動を分析
    List<double> variations = [];
    for (int i = 1; i < validPitches.length; i++) {
      final variation = (validPitches[i] - validPitches[i - 1]).abs();
      variations.add(variation);
    }

    // 平均変動幅を計算
    final averageVariation = variations.reduce((a, b) => a + b) / variations.length;

    // 安定性スコアを計算
    double stabilityScore = 0.0;
    if (averageVariation <= STABLE_VARIATION_THRESHOLD) {
      stabilityScore = 100.0;
    } else if (averageVariation <= UNSTABLE_VARIATION_THRESHOLD) {
      stabilityScore = 100.0 - (averageVariation - STABLE_VARIATION_THRESHOLD) / 
                      (UNSTABLE_VARIATION_THRESHOLD - STABLE_VARIATION_THRESHOLD) * 70.0;
    } else {
      stabilityScore = math.max(0.0, 30.0 - (averageVariation - UNSTABLE_VARIATION_THRESHOLD) * 0.3);
    }

    return stabilityScore;
  }

  /// タイミングスコアを計算（10%の重み）
  static double _calculateTimingScore(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    if (recordedPitches.isEmpty || referencePitches.isEmpty) return 0.0;

    // 簡易的なタイミング評価：長さの一致度で判定
    final recordedLength = recordedPitches.length;
    final referenceLength = referencePitches.length;
    
    final lengthDifference = (recordedLength - referenceLength).abs();
    final maxLength = math.max(recordedLength, referenceLength);
    
    if (maxLength == 0) return 0.0;
    
    final timingAccuracy = 1.0 - (lengthDifference / maxLength);
    
    // より詳細なタイミング分析（音程変化点の検出）
    final recordedChanges = _detectPitchChanges(recordedPitches);
    final referenceChanges = _detectPitchChanges(referencePitches);
    
    final changeTimingScore = _compareChangeTimings(recordedChanges, referenceChanges);
    
    // 長さ一致度50%、変化タイミング50%で重み付け
    return (timingAccuracy * 50.0) + (changeTimingScore * 50.0);
  }

  /// 音程変化点を検出
  static List<int> _detectPitchChanges(List<double> pitches) {
    List<int> changes = [];
    const double changeThreshold = 20.0; // Hz

    for (int i = 1; i < pitches.length; i++) {
      if (pitches[i] > 0 && pitches[i - 1] > 0) {
        final difference = (pitches[i] - pitches[i - 1]).abs();
        if (difference > changeThreshold) {
          changes.add(i);
        }
      }
    }

    return changes;
  }

  /// 変化タイミングの一致度を比較
  static double _compareChangeTimings(List<int> recorded, List<int> reference) {
    if (recorded.isEmpty && reference.isEmpty) return 100.0;
    if (recorded.isEmpty || reference.isEmpty) return 0.0;

    int matches = 0;
    const int toleranceFrames = 3; // 許容誤差フレーム数

    for (final refChange in reference) {
      for (final recChange in recorded) {
        if ((recChange - refChange).abs() <= toleranceFrames) {
          matches++;
          break;
        }
      }
    }

    final maxChanges = math.max(recorded.length, reference.length);
    return maxChanges > 0 ? (matches / maxChanges) * 100.0 : 0.0;
  }

  /// セント単位での音程差を計算
  static double calculateCentDifference(double pitch1, double pitch2) {
    if (pitch1 <= 0 || pitch2 <= 0) return 0.0;
    return 1200.0 * (math.log(pitch2 / pitch1) / math.ln2);
  }

  /// スコアのランク判定
  static String getScoreRank(double score) {
    if (score >= 90) return 'S';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'E';
  }

  /// スコアに基づくコメント生成
  static String getScoreComment(double score) {
    if (score >= 90) return '素晴らしい歌唱です！';
    if (score >= 80) return 'とても上手に歌えています！';
    if (score >= 70) return '良い調子です！';
    if (score >= 60) return 'もう少し練習してみましょう';
    if (score >= 50) return '基本を見直してみましょう';
    return '一緒に頑張りましょう！';
  }
}