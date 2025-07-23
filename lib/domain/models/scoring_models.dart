// math関数用のインポート
import 'dart:math' show log;

/// スコアリング結果の詳細分析を格納するモデル群
/// Single Responsibility Principle: 各クラスは一つの分析責任のみを持つ

/// スコア内訳を格納するクラス
class ScoreBreakdown {
  final double pitchAccuracyScore;
  final double stabilityScore;
  final double timingScore;
  final double totalScore;
  final DateTime calculatedAt;

  const ScoreBreakdown({
    required this.pitchAccuracyScore,
    required this.stabilityScore,
    required this.timingScore,
    required this.totalScore,
    required this.calculatedAt,
  });

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      pitchAccuracyScore: json['pitchAccuracyScore'].toDouble(),
      stabilityScore: json['stabilityScore'].toDouble(),
      timingScore: json['timingScore'].toDouble(),
      totalScore: json['totalScore'].toDouble(),
      calculatedAt: DateTime.parse(json['calculatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pitchAccuracyScore': pitchAccuracyScore,
      'stabilityScore': stabilityScore,
      'timingScore': timingScore,
      'totalScore': totalScore,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  /// スコアのパーセンテージ表示
  String get totalScorePercentage => '${(totalScore * 100).toStringAsFixed(1)}%';
}

/// ピッチ位置情報を格納するクラス
class PitchPoint {
  final double timestamp;
  final double frequency;
  final double confidence;
  final bool isValid;

  const PitchPoint({
    required this.timestamp,
    required this.frequency,
    required this.confidence,
    this.isValid = true,
  });

  factory PitchPoint.fromJson(Map<String, dynamic> json) {
    return PitchPoint(
      timestamp: json['timestamp'].toDouble(),
      frequency: json['frequency'].toDouble(),
      confidence: json['confidence'].toDouble(),
      isValid: json['isValid'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'frequency': frequency,
      'confidence': confidence,
      'isValid': isValid,
    };
  }

  /// セント差を計算
  double centDifferenceTo(PitchPoint other) {
    if (!isValid || !other.isValid || frequency <= 0 || other.frequency <= 0) {
      return 0.0;
    }
    return 1200 * (log(other.frequency / frequency) / ln2);
  }

  static const double ln2 = 0.6931471805599453;
}

/// ピッチ精度分析結果
class PitchAnalysis {
  final double averageDeviation;
  final double maxDeviation;
  final double accuracyRate;
  final List<PitchPoint> analysisPoints;
  final int totalNotes;
  final int accurateNotes;

  const PitchAnalysis({
    required this.averageDeviation,
    required this.maxDeviation,
    required this.accuracyRate,
    required this.analysisPoints,
    required this.totalNotes,
    required this.accurateNotes,
  });

  factory PitchAnalysis.fromJson(Map<String, dynamic> json) {
    return PitchAnalysis(
      averageDeviation: json['averageDeviation'].toDouble(),
      maxDeviation: json['maxDeviation'].toDouble(),
      accuracyRate: json['accuracyRate'].toDouble(),
      analysisPoints: (json['analysisPoints'] as List)
          .map((item) => PitchPoint.fromJson(item))
          .toList(),
      totalNotes: json['totalNotes'],
      accurateNotes: json['accurateNotes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averageDeviation': averageDeviation,
      'maxDeviation': maxDeviation,
      'accuracyRate': accuracyRate,
      'analysisPoints': analysisPoints.map((point) => point.toJson()).toList(),
      'totalNotes': totalNotes,
      'accurateNotes': accurateNotes,
    };
  }
}

/// 音程安定性分析結果
class StabilityAnalysis {
  final double stabilityScore;
  final double vibratoRate;
  final double noiseLevel;
  final List<StabilitySegment> segments;
  final bool isStable;

  const StabilityAnalysis({
    required this.stabilityScore,
    required this.vibratoRate,
    required this.noiseLevel,
    required this.segments,
    required this.isStable,
  });

  factory StabilityAnalysis.fromJson(Map<String, dynamic> json) {
    return StabilityAnalysis(
      stabilityScore: json['stabilityScore'].toDouble(),
      vibratoRate: json['vibratoRate'].toDouble(),
      noiseLevel: json['noiseLevel'].toDouble(),
      segments: (json['segments'] as List)
          .map((item) => StabilitySegment.fromJson(item))
          .toList(),
      isStable: json['isStable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stabilityScore': stabilityScore,
      'vibratoRate': vibratoRate,
      'noiseLevel': noiseLevel,
      'segments': segments.map((segment) => segment.toJson()).toList(),
      'isStable': isStable,
    };
  }
}

/// 安定性セグメント
class StabilitySegment {
  final double startTime;
  final double endTime;
  final double deviation;
  final bool isStable;

  const StabilitySegment({
    required this.startTime,
    required this.endTime,
    required this.deviation,
    required this.isStable,
  });

  factory StabilitySegment.fromJson(Map<String, dynamic> json) {
    return StabilitySegment(
      startTime: json['startTime'].toDouble(),
      endTime: json['endTime'].toDouble(),
      deviation: json['deviation'].toDouble(),
      isStable: json['isStable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'deviation': deviation,
      'isStable': isStable,
    };
  }

  double get duration => endTime - startTime;
}

/// タイミング精度分析結果
class TimingAnalysis {
  final double overallTimingScore;
  final double averageDelay;
  final List<TimingDeviation> deviations;
  final bool isOnTime;

  const TimingAnalysis({
    required this.overallTimingScore,
    required this.averageDelay,
    required this.deviations,
    required this.isOnTime,
  });

  factory TimingAnalysis.fromJson(Map<String, dynamic> json) {
    return TimingAnalysis(
      overallTimingScore: json['overallTimingScore'].toDouble(),
      averageDelay: json['averageDelay'].toDouble(),
      deviations: (json['deviations'] as List)
          .map((item) => TimingDeviation.fromJson(item))
          .toList(),
      isOnTime: json['isOnTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overallTimingScore': overallTimingScore,
      'averageDelay': averageDelay,
      'deviations': deviations.map((dev) => dev.toJson()).toList(),
      'isOnTime': isOnTime,
    };
  }
}

/// タイミングずれ情報
class TimingDeviation {
  final double timestamp;
  final double deviation;
  final bool isEarly;

  const TimingDeviation({
    required this.timestamp,
    required this.deviation,
    required this.isEarly,
  });

  factory TimingDeviation.fromJson(Map<String, dynamic> json) {
    return TimingDeviation(
      timestamp: json['timestamp'].toDouble(),
      deviation: json['deviation'].toDouble(),
      isEarly: json['isEarly'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'deviation': deviation,
      'isEarly': isEarly,
    };
  }
}
