import 'dart:math' as math;
import '../models/song_result.dart';

/// Phase 3: 多角的スコアリングサービス
/// 
/// 単一責任の原則に従い、スコアリングロジックのみを担当します。
/// ピッチ精度(70%)、安定性(20%)、タイミング(10%)の重み付きスコアを算出し、
/// 詳細な分析結果を提供します。
class ScoringService {
  // スコアリング定数
  static const double PITCH_ACCURACY_WEIGHT = 0.7;
  static const double STABILITY_WEIGHT = 0.2;
  static const double TIMING_WEIGHT = 0.1;
  
  // 精度判定閾値
  static const double PITCH_ACCURACY_THRESHOLD_CENTS = 50.0; // セント単位
  static const double TIMING_ACCURACY_THRESHOLD_SEC = 0.2;   // 秒単位
  static const double STABILITY_THRESHOLD_CENTS = 30.0;      // セント単位

  /// 歌唱データから総合的なスコアを算出
  /// 
  /// [referencePitches] 基準ピッチデータ(Hz)
  /// [recordedPitches] 録音ピッチデータ(Hz)
  /// [songTitle] 楽曲タイトル
  /// [recordingTimestamps] 録音時のタイムスタンプ(オプション)
  /// 戻り値: 詳細なスコアリング結果
  static SongResult calculateComprehensiveScore({
    required List<double> referencePitches,
    required List<double> recordedPitches, 
    required String songTitle,
    List<double>? recordingTimestamps,
  }) {
    // データの前処理
    final processedData = _preprocessPitchData(referencePitches, recordedPitches);
    final refPitches = processedData['reference'] as List<double>;
    final recPitches = processedData['recorded'] as List<double>;
    
    // 各分析の実行
    final pitchAnalysis = _analyzePitchAccuracy(refPitches, recPitches);
    final stabilityAnalysis = _analyzeStability(recPitches);
    final timingAnalysis = _analyzeTiming(refPitches, recPitches, recordingTimestamps);
    
    // スコア内訳の計算
    final scoreBreakdown = ScoreBreakdown(
      pitchAccuracyScore: _calculatePitchAccuracyScore(pitchAnalysis),
      stabilityScore: _calculateStabilityScore(stabilityAnalysis),
      timingScore: _calculateTimingScore(timingAnalysis),
    );
    
    return SongResult(
      songTitle: songTitle,
      timestamp: DateTime.now(),
      totalScore: scoreBreakdown.totalScore,
      scoreBreakdown: scoreBreakdown,
      pitchAnalysis: pitchAnalysis,
      timingAnalysis: timingAnalysis,
      stabilityAnalysis: stabilityAnalysis,
      feedback: [], // フィードバックサービスで生成
    );
  }

  /// ピッチデータの前処理
  /// 長さを揃えて、無効なデータを除去
  static Map<String, List<double>> _preprocessPitchData(
    List<double> reference,
    List<double> recorded,
  ) {
    final minLength = math.min(reference.length, recorded.length);
    
    final processedRef = <double>[];
    final processedRec = <double>[];
    
    for (int i = 0; i < minLength; i++) {
      final refPitch = reference[i];
      final recPitch = recorded[i];
      
      // 両方とも有効なピッチの場合のみ追加
      if (refPitch > 0 && recPitch > 0) {
        processedRef.add(refPitch);
        processedRec.add(recPitch);
      }
    }
    
    return {
      'reference': processedRef,
      'recorded': processedRec,
    };
  }

  /// ピッチ精度の分析
  static PitchAnalysis _analyzePitchAccuracy(
    List<double> referencePitches,
    List<double> recordedPitches,
  ) {
    final pitchPoints = <PitchPoint>[];
    final deviations = <double>[];
    int correctNotes = 0;
    
    for (int i = 0; i < referencePitches.length; i++) {
      final refPitch = referencePitches[i];
      final recPitch = recordedPitches[i];
      
      // セント単位でのずれを計算
      final deviationCents = _calculateCentsDeviation(refPitch, recPitch);
      deviations.add(deviationCents);
      
      // 正確性の判定
      if (deviationCents.abs() <= PITCH_ACCURACY_THRESHOLD_CENTS) {
        correctNotes++;
      }
      
      pitchPoints.add(PitchPoint(
        timestamp: i * 0.1, // TODO: 実際のタイムスタンプを使用
        referencePitch: refPitch,
        recordedPitch: recPitch,
        deviation: deviationCents,
      ));
    }
    
    final averageDeviation = deviations.isEmpty ? 0.0 :
        deviations.reduce((a, b) => a + b) / deviations.length;
    final maxDeviation = deviations.isEmpty ? 0.0 :
        deviations.reduce(math.max);
    
    return PitchAnalysis(
      averageDeviation: averageDeviation,
      maxDeviation: maxDeviation,
      correctNotes: correctNotes,
      totalNotes: referencePitches.length,
      pitchPoints: pitchPoints,
      deviationHistory: deviations,
    );
  }

  /// 安定性の分析
  static StabilityAnalysis _analyzeStability(List<double> recordedPitches) {
    if (recordedPitches.length < 2) {
      return const StabilityAnalysis(
        averageVariation: 0.0,
        maxVariation: 0.0,
        stableNotes: 0,
        unstableNotes: 0,
        variationHistory: [],
      );
    }
    
    final variations = <double>[];
    int stableNotes = 0;
    int unstableNotes = 0;
    
    // 隣接するピッチ間の変動を分析
    for (int i = 1; i < recordedPitches.length; i++) {
      final variation = _calculateCentsDeviation(
        recordedPitches[i - 1],
        recordedPitches[i],
      ).abs();
      
      variations.add(variation);
      
      if (variation <= STABILITY_THRESHOLD_CENTS) {
        stableNotes++;
      } else {
        unstableNotes++;
      }
    }
    
    final averageVariation = variations.isEmpty ? 0.0 :
        variations.reduce((a, b) => a + b) / variations.length;
    final maxVariation = variations.isEmpty ? 0.0 :
        variations.reduce(math.max);
    
    return StabilityAnalysis(
      averageVariation: averageVariation,
      maxVariation: maxVariation,
      stableNotes: stableNotes,
      unstableNotes: unstableNotes,
      variationHistory: variations,
    );
  }

  /// タイミングの分析
  static TimingAnalysis _analyzeTiming(
    List<double> referencePitches,
    List<double> recordedPitches,
    List<double>? recordingTimestamps,
  ) {
    // TODO: 実際のタイミング分析を実装
    // 現在は基本的な実装のみ
    
    final latencyHistory = <double>[];
    int earlyNotes = 0;
    int lateNotes = 0;
    int onTimeNotes = recordedPitches.length;
    
    // 簡易的なタイミング分析（今後改善予定）
    for (int i = 0; i < recordedPitches.length; i++) {
      latencyHistory.add(0.0); // プレースホルダー
    }
    
    return TimingAnalysis(
      averageLatency: 0.0,
      maxLatency: 0.0,
      earlyNotes: earlyNotes,
      lateNotes: lateNotes,
      onTimeNotes: onTimeNotes,
      latencyHistory: latencyHistory,
    );
  }

  /// ピッチ精度スコアの計算（0-100）
  static double _calculatePitchAccuracyScore(PitchAnalysis analysis) {
    if (analysis.totalNotes == 0) return 0.0;
    
    // 基本正確性スコア
    final accuracyScore = analysis.accuracyRatio * 100;
    
    // 平均ずれによる減点
    final deviationPenalty = math.min(
      analysis.averageDeviation / PITCH_ACCURACY_THRESHOLD_CENTS * 20,
      20.0,
    );
    
    return math.max(0.0, accuracyScore - deviationPenalty);
  }

  /// 安定性スコアの計算（0-100）
  static double _calculateStabilityScore(StabilityAnalysis analysis) {
    final totalNotes = analysis.stableNotes + analysis.unstableNotes;
    if (totalNotes == 0) return 100.0;
    
    // 基本安定性スコア
    final stabilityScore = analysis.stabilityRatio * 100;
    
    // 平均変動による減点
    final variationPenalty = math.min(
      analysis.averageVariation / STABILITY_THRESHOLD_CENTS * 15,
      15.0,
    );
    
    return math.max(0.0, stabilityScore - variationPenalty);
  }

  /// タイミングスコアの計算（0-100）
  static double _calculateTimingScore(TimingAnalysis analysis) {
    // TODO: 実際のタイミングスコア計算を実装
    // 現在は基本値を返す
    return 85.0; // プレースホルダー
  }

  /// セント単位での音程のずれを計算
  /// 
  /// [referencePitch] 基準ピッチ(Hz)
  /// [recordedPitch] 録音ピッチ(Hz)
  /// 戻り値: ずれ（セント単位）
  static double _calculateCentsDeviation(double referencePitch, double recordedPitch) {
    if (referencePitch <= 0 || recordedPitch <= 0) return 0.0;
    
    // セント = 1200 * log2(f2/f1)
    return 1200 * (math.log(recordedPitch / referencePitch) / math.ln2);
  }

  /// スコアのグレード判定
  static String getScoreGrade(double score) {
    if (score >= 95) return 'S';
    if (score >= 90) return 'A+';
    if (score >= 85) return 'A';
    if (score >= 80) return 'B+';
    if (score >= 75) return 'B';
    if (score >= 70) return 'C+';
    if (score >= 65) return 'C';
    if (score >= 60) return 'D+';
    if (score >= 55) return 'D';
    return 'F';
  }
}