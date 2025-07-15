/// 歌唱結果の総合データモデル
/// Phase 3で追加: 多角的評価指標による詳細スコアリング
class SongResult {
  final String songTitle;
  final DateTime recordedAt;
  final List<double> recordedPitches;
  final List<double> referencePitches;
  final ComprehensiveScore comprehensiveScore;
  final DetailedAnalysis detailedAnalysis;
  final List<ImprovementSuggestion> improvementSuggestions;

  const SongResult({
    required this.songTitle,
    required this.recordedAt,
    required this.recordedPitches,
    required this.referencePitches,
    required this.comprehensiveScore,
    required this.detailedAnalysis,
    required this.improvementSuggestions,
  });

  /// JSONからSongResultを生成
  factory SongResult.fromJson(Map<String, dynamic> json) {
    return SongResult(
      songTitle: json['songTitle'],
      recordedAt: DateTime.parse(json['recordedAt']),
      recordedPitches: List<double>.from(json['recordedPitches']),
      referencePitches: List<double>.from(json['referencePitches']),
      comprehensiveScore: ComprehensiveScore.fromJson(json['comprehensiveScore']),
      detailedAnalysis: DetailedAnalysis.fromJson(json['detailedAnalysis']),
      improvementSuggestions: (json['improvementSuggestions'] as List)
          .map((s) => ImprovementSuggestion.fromJson(s))
          .toList(),
    );
  }

  /// SongResultをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'songTitle': songTitle,
      'recordedAt': recordedAt.toIso8601String(),
      'recordedPitches': recordedPitches,
      'referencePitches': referencePitches,
      'comprehensiveScore': comprehensiveScore.toJson(),
      'detailedAnalysis': detailedAnalysis.toJson(),
      'improvementSuggestions': improvementSuggestions.map((s) => s.toJson()).toList(),
    };
  }
}

/// 総合スコア（音程精度70% + 安定性20% + タイミング10%）
class ComprehensiveScore {
  final double overall; // 0-100の総合スコア
  final double pitchAccuracy; // 音程精度スコア（0-100）
  final double stability; // 安定性スコア（0-100）
  final double timing; // タイミングスコア（0-100）

  // 重み配分
  static const double PITCH_WEIGHT = 0.7;
  static const double STABILITY_WEIGHT = 0.2;
  static const double TIMING_WEIGHT = 0.1;

  const ComprehensiveScore({
    required this.overall,
    required this.pitchAccuracy,
    required this.stability,
    required this.timing,
  });

  /// 各スコアから総合スコアを計算
  factory ComprehensiveScore.calculate({
    required double pitchAccuracy,
    required double stability,
    required double timing,
  }) {
    final overall = (pitchAccuracy * PITCH_WEIGHT) +
        (stability * STABILITY_WEIGHT) +
        (timing * TIMING_WEIGHT);

    return ComprehensiveScore(
      overall: overall,
      pitchAccuracy: pitchAccuracy,
      stability: stability,
      timing: timing,
    );
  }

  factory ComprehensiveScore.fromJson(Map<String, dynamic> json) {
    return ComprehensiveScore(
      overall: json['overall'].toDouble(),
      pitchAccuracy: json['pitchAccuracy'].toDouble(),
      stability: json['stability'].toDouble(),
      timing: json['timing'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall': overall,
      'pitchAccuracy': pitchAccuracy,
      'stability': stability,
      'timing': timing,
    };
  }
}

/// 詳細分析結果
class DetailedAnalysis {
  final List<PitchPoint> pitchGraph; // 音程グラフ用データ
  final Map<String, double> statistics; // 統計情報
  final List<String> strengths; // 良かった点
  final List<String> weaknesses; // 改善点

  const DetailedAnalysis({
    required this.pitchGraph,
    required this.statistics,
    required this.strengths,
    required this.weaknesses,
  });

  factory DetailedAnalysis.fromJson(Map<String, dynamic> json) {
    return DetailedAnalysis(
      pitchGraph: (json['pitchGraph'] as List)
          .map((p) => PitchPoint.fromJson(p))
          .toList(),
      statistics: Map<String, double>.from(json['statistics']),
      strengths: List<String>.from(json['strengths']),
      weaknesses: List<String>.from(json['weaknesses']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pitchGraph': pitchGraph.map((p) => p.toJson()).toList(),
      'statistics': statistics,
      'strengths': strengths,
      'weaknesses': weaknesses,
    };
  }
}

/// 音程グラフの1ポイント
class PitchPoint {
  final double timeSeconds;
  final double? recordedPitch;
  final double? referencePitch;
  final double? difference; // セント単位での差

  const PitchPoint({
    required this.timeSeconds,
    this.recordedPitch,
    this.referencePitch,
    this.difference,
  });

  factory PitchPoint.fromJson(Map<String, dynamic> json) {
    return PitchPoint(
      timeSeconds: json['timeSeconds'].toDouble(),
      recordedPitch: json['recordedPitch']?.toDouble(),
      referencePitch: json['referencePitch']?.toDouble(),
      difference: json['difference']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timeSeconds': timeSeconds,
      'recordedPitch': recordedPitch,
      'referencePitch': referencePitch,
      'difference': difference,
    };
  }
}

/// 改善提案
class ImprovementSuggestion {
  final String category; // 'pitch', 'stability', 'timing'
  final String title;
  final String description;
  final int priority; // 1-3, 1が最重要

  const ImprovementSuggestion({
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
  });

  factory ImprovementSuggestion.fromJson(Map<String, dynamic> json) {
    return ImprovementSuggestion(
      category: json['category'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
    };
  }
}