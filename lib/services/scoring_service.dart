import 'dart:math' as math;
import '../models/song_result.dart';

/// Phase 3: 多面的スコアリングを担当するサービスクラス
/// 
/// 単一責任原則: スコア計算のみに専念
/// 拡張性: 新しい評価指標の追加が容易
/// テスト容易性: 純粋な関数で構成
class ScoringService {
  // Phase 3 要件: 重み設定
  static const double PITCH_ACCURACY_WEIGHT = 0.7; // 70%
  static const double STABILITY_WEIGHT = 0.2;      // 20%
  static const double TIMING_WEIGHT = 0.1;         // 10%
  
  // スコア計算の閾値
  static const double PITCH_TOLERANCE_HZ = 30.0;
  static const double EXCELLENT_THRESHOLD = 90.0;
  static const double GOOD_THRESHOLD = 75.0;

  /// 総合スコアの計算
  /// 
  /// [recordedPitches] 録音されたピッチデータ
  /// [referencePitches] 基準ピッチデータ  
  /// [timingAccuracies] タイミング精度データ
  /// 戻り値: ScoreBreakdown 詳細スコア内訳
  static ScoreBreakdown calculateScore({
    required List<double> recordedPitches,
    required List<double> referencePitches,
    required List<double> timingAccuracies,
  }) {
    // 音程精度スコア計算 (70%)
    final pitchAccuracy = _calculatePitchAccuracy(recordedPitches, referencePitches);
    
    // 安定性スコア計算 (20%)
    final stability = _calculateStability(recordedPitches);
    
    // タイミングスコア計算 (10%)
    final timing = _calculateTiming(timingAccuracies);

    return ScoreBreakdown(
      pitchAccuracy: pitchAccuracy,
      stability: stability,
      timing: timing,
    );
  }

  /// 音程精度スコアの計算
  /// 
  /// Phase 2の高精度比較システムを活用し、
  /// セント単位での細かい精度評価を実装
  static double _calculatePitchAccuracy(
    List<double> recordedPitches,
    List<double> referencePitches,
  ) {
    if (recordedPitches.isEmpty || referencePitches.isEmpty) return 0.0;

    final minLength = math.min(recordedPitches.length, referencePitches.length);
    if (minLength == 0) return 0.0;

    double totalAccuracy = 0.0;
    int validNotes = 0;

    for (int i = 0; i < minLength; i++) {
      final recorded = recordedPitches[i];
      final reference = referencePitches[i];

      // 無音部分はスキップ
      if (recorded <= 0 || reference <= 0) continue;

      // セント単位での差分計算
      final centDifference = _pitchToCents(recorded) - _pitchToCents(reference);
      final absCentDiff = centDifference.abs();

      // 精度計算: 100セント以内で満点、それ以上は減点
      double noteAccuracy;
      if (absCentDiff <= 50) {
        noteAccuracy = 100.0; // 50セント以内は満点
      } else if (absCentDiff <= 100) {
        noteAccuracy = 100.0 - (absCentDiff - 50); // 50-100セントは線形減点
      } else if (absCentDiff <= 200) {
        noteAccuracy = 50.0 - ((absCentDiff - 100) * 0.5); // 100-200セントはさらに減点
      } else {
        noteAccuracy = 0.0; // 200セント以上は0点
      }

      totalAccuracy += noteAccuracy;
      validNotes++;
    }

    return validNotes > 0 ? totalAccuracy / validNotes : 0.0;
  }

  /// 安定性スコアの計算
  /// 
  /// 音程の変動の少なさを評価
  static double _calculateStability(List<double> recordedPitches) {
    if (recordedPitches.length < 2) return 100.0;

    final validPitches = recordedPitches.where((p) => p > 0).toList();
    if (validPitches.length < 2) return 100.0;

    // 音程の分散を計算
    final mean = validPitches.reduce((a, b) => a + b) / validPitches.length;
    final variance = validPitches
        .map((p) => math.pow(p - mean, 2))
        .reduce((a, b) => a + b) / validPitches.length;
    
    final standardDeviation = math.sqrt(variance);

    // 標準偏差が小さいほど高スコア
    // 10Hz以下の変動で満点、30Hz以上で0点
    if (standardDeviation <= 10) {
      return 100.0;
    } else if (standardDeviation <= 30) {
      return 100.0 - ((standardDeviation - 10) * 5); // 線形減点
    } else {
      return 0.0;
    }
  }

  /// タイミングスコアの計算
  static double _calculateTiming(List<double> timingAccuracies) {
    if (timingAccuracies.isEmpty) return 0.0;

    final averageAccuracy = timingAccuracies.reduce((a, b) => a + b) / timingAccuracies.length;
    return averageAccuracy * 100.0; // 0.0-1.0を0-100に変換
  }

  /// ピッチをセント値に変換
  /// 
  /// [frequencyHz] 周波数 (Hz)
  /// 戻り値: セント値 (A4=440Hzを基準とした相対値)
  static double _pitchToCents(double frequencyHz) {
    if (frequencyHz <= 0) return 0.0;
    
    // A4 = 440Hz を基準 (MIDI note 69)
    const double a4Frequency = 440.0;
    return 1200.0 * (math.log(frequencyHz / a4Frequency) / math.ln2);
  }

  /// スコアレベルの判定
  static String getScoreLevel(double totalScore) {
    if (totalScore >= EXCELLENT_THRESHOLD) return '優秀';
    if (totalScore >= GOOD_THRESHOLD) return '良好';
    if (totalScore >= 60.0) return '標準';
    return '要練習';
  }

  /// スコア向上のための推奨重点エリア
  static String getRecommendedFocus(ScoreBreakdown breakdown) {
    final scores = [
      ('音程精度', breakdown.pitchAccuracy),
      ('安定性', breakdown.stability),
      ('タイミング', breakdown.timing),
    ];

    // 最もスコアの低い項目を特定
    scores.sort((a, b) => a.$2.compareTo(b.$2));
    
    return scores.first.$1;
  }
}