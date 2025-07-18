import 'dart:math' as math;
import '../models/song_result.dart';

/// Phase 3: 多角的スコアリングサービス
/// 
/// 単一責任の原則に従い、スコアリングロジックのみを担当します。
/// ピッチ精度(70%)、安定性(20%)、タイミング(10%)の重み付きスコアを算出し、
/// 詳細な分析結果を提供します。
class ScoringService {
  // スコアリング定数
  static const double pitchAccuracyWeight = 0.7;
  static const double stabilityWeight = 0.2;
  static const double timingWeight = 0.1;
  
  // 精度判定閾値
  static const double pitchAccuracyThresholdCents = 50.0; // セント単位
  static const double timingAccuracyThresholdSec = 0.2;   // 秒単位
  static const double stabilityThresholdCents = 30.0;      // セント単位

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
    // 空データの場合は空の分析結果を返す
    if (referencePitches.isEmpty || recordedPitches.isEmpty) {
      return const PitchAnalysis(
        averageDeviation: 0.0,
        maxDeviation: 0.0,
        correctNotes: 0,
        totalNotes: 0,
        pitchPoints: [],
        deviationHistory: [],
      );
    }
    
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
      if (deviationCents.abs() <= pitchAccuracyThresholdCents) {
        correctNotes++;
      }
      
      pitchPoints.add(PitchPoint(
        timestamp: _calculateActualTimestamp(i, referencePitches.length),
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
      
      if (variation <= stabilityThresholdCents) {
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
    // 空データの場合は空の分析結果を返す
    if (referencePitches.isEmpty || recordedPitches.isEmpty) {
      return const TimingAnalysis(
        averageLatency: 0.0,
        maxLatency: 0.0,
        earlyNotes: 0,
        lateNotes: 0,
        onTimeNotes: 0,
        latencyHistory: [],
      );
    }
    
    // 実際のタイミング分析を実装
    final latencyHistory = <double>[];
    int earlyNotes = 0;
    int lateNotes = 0;
    int onTimeNotes = 0;
    
    // 録音タイムスタンプがない場合は、一定間隔で推定
    final timestamps = recordingTimestamps ?? 
        List.generate(recordedPitches.length, (i) => _calculateActualTimestamp(i, recordedPitches.length));
    
    // 基準との時間差を計算
    for (int i = 0; i < math.min(referencePitches.length, recordedPitches.length); i++) {
      final expectedTime = _calculateActualTimestamp(i, referencePitches.length);
      final actualTime = i < timestamps.length ? timestamps[i] : expectedTime;
      
      final latency = actualTime - expectedTime;
      latencyHistory.add(latency);
      
      // タイミング精度の分類
      if (latency.abs() <= timingAccuracyThresholdSec) {
        onTimeNotes++;
      } else if (latency < 0) {
        earlyNotes++;
      } else {
        lateNotes++;
      }
    }
    
    final averageLatency = latencyHistory.isEmpty ? 0.0 :
        latencyHistory.reduce((a, b) => a + b) / latencyHistory.length;
    final maxLatency = latencyHistory.isEmpty ? 0.0 :
        latencyHistory.reduce((a, b) => a.abs() > b.abs() ? a : b);
    
    return TimingAnalysis(
      averageLatency: averageLatency,
      maxLatency: maxLatency,
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
      analysis.averageDeviation / pitchAccuracyThresholdCents * 20,
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
      analysis.averageVariation / stabilityThresholdCents * 15,
      15.0,
    );
    
    return math.max(0.0, stabilityScore - variationPenalty);
  }

  /// タイミングスコアの計算（0-100）
  static double _calculateTimingScore(TimingAnalysis analysis) {
    final totalNotes = analysis.earlyNotes + analysis.lateNotes + analysis.onTimeNotes;
    if (totalNotes == 0) return 0.0;
    
    // 正時性の基本スコア
    final accuracyScore = analysis.onTimeNotes / totalNotes * 100;
    
    // 平均遅延による減点
    final latencyPenalty = math.min(
      analysis.averageLatency.abs() / timingAccuracyThresholdSec * 25,
      25.0,
    );
    
    // 最大遅延による追加減点
    final maxLatencyPenalty = math.min(
      analysis.maxLatency.abs() / (timingAccuracyThresholdSec * 2) * 10,
      10.0,
    );
    
    return math.max(0.0, accuracyScore - latencyPenalty - maxLatencyPenalty);
  }

  /// 実際のタイムスタンプを計算
  /// 
  /// [index] ピッチデータのインデックス
  /// [totalLength] 全体の長さ
  /// 戻り値: 実際のタイムスタンプ（秒）
  static double _calculateActualTimestamp(int index, int totalLength) {
    // 一般的な楽曲の長さ（3-5分）を基準に計算
    const double averageSongDuration = 240.0; // 4分
    const double minInterval = 0.05; // 最小間隔50ms
    
    if (totalLength <= 1) return 0.0;
    
    // 線形補間でタイムスタンプを計算
    final interval = math.max(minInterval, averageSongDuration / totalLength);
    return index * interval;
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

  /// スコアランクを取得（後方互換性のため）
  static String getScoreRank(double score) {
    return getScoreGrade(score);
  }

  /// スコアレベルを取得（後方互換性のため）
  static String getScoreLevel(double score) {
    if (score >= 95) return 'S';
    if (score >= 85) return 'A';
    if (score >= 75) return 'B';
    if (score >= 65) return 'C';
    if (score >= 55) return 'D';
    return 'F';
  }

  /// スコアコメントを取得
  static String getScoreComment(double score) {
    if (score >= 95) return '素晴らしい歌唱です！';
    if (score >= 85) return 'とても上手です！';
    if (score >= 75) return '良い歌唱です！';
    if (score >= 65) return 'もう少し練習が必要です';
    if (score >= 55) return '練習を続けましょう';
    return '基礎から練習しましょう';
  }

  /// セント単位での音程のずれを計算（公開メソッド）
  static double calculateCentDifference(double referencePitch, double recordedPitch) {
    return _calculateCentsDeviation(referencePitch, recordedPitch);
  }

  /// 推奨フォーカスエリアを取得
  static List<String> getRecommendedFocus(ScoreBreakdown scoreBreakdown) {
    final focus = <String>[];
    
    if (scoreBreakdown.pitchAccuracyScore < 70) {
      focus.add('音程精度');
    }
    if (scoreBreakdown.stabilityScore < 70) {
      focus.add('音程安定性');
    }
    if (scoreBreakdown.timingScore < 70) {
      focus.add('タイミング');
    }
    
    return focus.isEmpty ? ['全体的なバランス'] : focus;
  }

  /// スコア計算メソッド（後方互換性のため）
  static SongResult calculateScore({
    required List<double> referencePitches,
    required List<double> recordedPitches,
    required String songTitle,
  }) {
    return calculateComprehensiveScore(
      referencePitches: referencePitches,
      recordedPitches: recordedPitches,
      songTitle: songTitle,
    );
  }

  // スコアリング定数（後方互換性のため）
  static const double perfectPitchThreshold = 20.0;
  static const double goodPitchThreshold = 50.0;
  static const double unstableVariationThreshold = 30.0;
}