/// Phase 3: 歌唱結果を格納する包括的なデータモデル
/// 
/// 単一責任原則に従い、歌唱結果に関する全ての情報を管理
/// 拡張性とテスト容易性を考慮した設計
class SongResult {
  final String songTitle;
  final DateTime recordedAt;
  final Duration songDuration;
  
  // 総合スコア
  final double totalScore;
  
  // 個別スコア (Phase 3 要件: 70%, 20%, 10%)
  final ScoreBreakdown scoreBreakdown;
  
  // 詳細分析データ
  final AnalysisData analysisData;
  
  // フィードバック・改善提案
  final FeedbackData feedbackData;

  const SongResult({
    required this.songTitle,
    required this.recordedAt,
    required this.songDuration,
    required this.totalScore,
    required this.scoreBreakdown,
    required this.analysisData,
    required this.feedbackData,
  });

  /// スコアが優秀かどうかの判定
  bool get isExcellent => totalScore >= 90.0;
  
  /// スコアが良好かどうかの判定
  bool get isGood => totalScore >= 75.0;
  
  /// スコアレベルの文字列表現
  String get scoreLevel {
    if (isExcellent) return '優秀';
    if (isGood) return '良好';
    if (totalScore >= 60.0) return '標準';
    return '要練習';
  }
}

/// 個別スコアの内訳 (Phase 3 要件に対応)
class ScoreBreakdown {
  // 音程精度スコア (70%の重み)
  final double pitchAccuracy;
  final double pitchAccuracyWeighted;
  
  // 安定性スコア (20%の重み)  
  final double stability;
  final double stabilityWeighted;
  
  // タイミングスコア (10%の重み)
  final double timing;
  final double timingWeighted;

  const ScoreBreakdown({
    required this.pitchAccuracy,
    required this.stability,
    required this.timing,
  }) : pitchAccuracyWeighted = pitchAccuracy * 0.7,
       stabilityWeighted = stability * 0.2,
       timingWeighted = timing * 0.1;

  /// 重み付き総合スコアの計算
  double get totalWeightedScore => 
      pitchAccuracyWeighted + stabilityWeighted + timingWeighted;
}

/// 詳細分析データ
class AnalysisData {
  // ピッチ分析
  final List<double> recordedPitches;
  final List<double> referencePitches;
  final List<double> pitchDifferences;
  
  // 安定性分析
  final double pitchVariance;
  final List<double> stabilityOverTime;
  
  // タイミング分析
  final List<TimingPoint> timingPoints;
  final double averageTimingAccuracy;
  
  // 統計情報
  final AnalysisStatistics statistics;

  const AnalysisData({
    required this.recordedPitches,
    required this.referencePitches,
    required this.pitchDifferences,
    required this.pitchVariance,
    required this.stabilityOverTime,
    required this.timingPoints,
    required this.averageTimingAccuracy,
    required this.statistics,
  });
}

/// タイミング分析のデータポイント
class TimingPoint {
  final Duration timestamp;
  final double expectedPitch;
  final double actualPitch;
  final double timingAccuracy; // 0.0 - 1.0

  const TimingPoint({
    required this.timestamp,
    required this.expectedPitch,
    required this.actualPitch,
    required this.timingAccuracy,
  });
}

/// 統計情報
class AnalysisStatistics {
  final int totalNotes;
  final int accurateNotes;
  final double accuracyRate;
  final double averagePitchDifference;
  final double maxPitchDifference;
  final double minPitchDifference;

  const AnalysisStatistics({
    required this.totalNotes,
    required this.accurateNotes,
    required this.accuracyRate,
    required this.averagePitchDifference,
    required this.maxPitchDifference,
    required this.minPitchDifference,
  });
}

/// フィードバック・改善提案データ
class FeedbackData {
  // 強みの分析
  final List<String> strengths;
  
  // 改善ポイント
  final List<ImprovementPoint> improvementPoints;
  
  // 具体的なアドバイス
  final List<String> actionableAdvice;
  
  // 練習推奨エリア
  final List<PracticeArea> practiceAreas;

  const FeedbackData({
    required this.strengths,
    required this.improvementPoints,
    required this.actionableAdvice,
    required this.practiceAreas,
  });
}

/// 改善ポイント
class ImprovementPoint {
  final String category; // 'pitch', 'stability', 'timing'
  final String description;
  final double severity; // 0.0 - 1.0 (低い値ほど改善が必要)
  final Duration? timestamp; // 特定の時間帯の問題の場合

  const ImprovementPoint({
    required this.category,
    required this.description,
    required this.severity,
    this.timestamp,
  });
}

/// 練習推奨エリア
class PracticeArea {
  final String title;
  final String description;
  final List<String> exercises;
  final Duration? focusTimeRange;

  const PracticeArea({
    required this.title,
    required this.description,
    required this.exercises,
    this.focusTimeRange,
  });
}