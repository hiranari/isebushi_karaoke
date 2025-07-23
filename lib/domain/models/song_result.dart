import 'dart:math' as math;

/// Phase 3: 歌唱結果の包括的データモデル
/// 
/// 単一責任の原則に従い、歌唱結果の全ての情報を管理します。
/// スコア、分析データ、フィードバックを構造化して保持し、
/// UI層から分離されたデータアクセスを提供します。
class SongResult {
  final String songTitle;
  final DateTime timestamp;
  final double totalScore;
  final ScoreBreakdown scoreBreakdown;
  final PitchAnalysis pitchAnalysis;
  final TimingAnalysis timingAnalysis;
  final StabilityAnalysis stabilityAnalysis;
  final List<String> feedback;

  SongResult({
    required this.songTitle,
    required this.timestamp,
    required this.totalScore,
    required this.scoreBreakdown,
    required this.pitchAnalysis,
    required this.timingAnalysis,
    required this.stabilityAnalysis,
    required this.feedback,
  });

  /// JSON変換用
  Map<String, dynamic> toJson() {
    return {
      'songTitle': songTitle,
      'timestamp': timestamp.toIso8601String(),
      'totalScore': totalScore,
      'scoreBreakdown': scoreBreakdown.toJson(),
      'pitchAnalysis': pitchAnalysis.toJson(),
      'timingAnalysis': timingAnalysis.toJson(),
      'stabilityAnalysis': stabilityAnalysis.toJson(),
      'feedback': feedback,
    };
  }

  factory SongResult.fromJson(Map<String, dynamic> json) {
    return SongResult(
      songTitle: json['songTitle'],
      timestamp: DateTime.parse(json['timestamp']),
      totalScore: json['totalScore'].toDouble(),
      scoreBreakdown: ScoreBreakdown.fromJson(json['scoreBreakdown']),
      pitchAnalysis: PitchAnalysis.fromJson(json['pitchAnalysis']),
      timingAnalysis: TimingAnalysis.fromJson(json['timingAnalysis']),
      stabilityAnalysis: StabilityAnalysis.fromJson(json['stabilityAnalysis']),
      feedback: List<String>.from(json['feedback']),
    );
  }

  // 後方互換性のためのアクセサー
  double get pitchAccuracy => scoreBreakdown.pitchAccuracyScore;
  double get stability => scoreBreakdown.stabilityScore;
  double get timing => scoreBreakdown.timingScore;
  double get overall => totalScore;
  
  String get scoreLevel {
    if (totalScore >= 95) return 'S';
    if (totalScore >= 85) return 'A';
    if (totalScore >= 75) return 'B';
    if (totalScore >= 65) return 'C';
    if (totalScore >= 55) return 'D';
    return 'F';
  }
  
  bool get isExcellent => totalScore >= 85;
  DateTime get recordedAt => timestamp;
}

/// スコア内訳（総合スコアの構成要素）
class ScoreBreakdown {
  final double pitchAccuracyScore;  // 70%重み
  final double stabilityScore;      // 20%重み  
  final double timingScore;         // 10%重み
  final double pitchAccuracyWeight;
  final double stabilityWeight;
  final double timingWeight;
  final DateTime calculatedAt;

  ScoreBreakdown({
    required this.pitchAccuracyScore,
    required this.stabilityScore,
    required this.timingScore,
    this.pitchAccuracyWeight = 0.7,
    this.stabilityWeight = 0.2,
    this.timingWeight = 0.1,
    DateTime? calculatedAt,
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  /// 重み付き総合スコアを計算
  double get totalScore {
    return pitchAccuracyScore * pitchAccuracyWeight +
           stabilityScore * stabilityWeight +
           timingScore * timingWeight;
  }

  Map<String, dynamic> toJson() {
    return {
      'pitchAccuracyScore': pitchAccuracyScore,
      'stabilityScore': stabilityScore,
      'timingScore': timingScore,
      'pitchAccuracyWeight': pitchAccuracyWeight,
      'stabilityWeight': stabilityWeight,
      'timingWeight': timingWeight,
      'calculatedAt': calculatedAt.toIso8601String(),
    };
  }

  factory ScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return ScoreBreakdown(
      pitchAccuracyScore: json['pitchAccuracyScore'].toDouble(),
      stabilityScore: json['stabilityScore'].toDouble(),
      timingScore: json['timingScore'].toDouble(),
      pitchAccuracyWeight: json['pitchAccuracyWeight']?.toDouble() ?? 0.7,
      stabilityWeight: json['stabilityWeight']?.toDouble() ?? 0.2,
      timingWeight: json['timingWeight']?.toDouble() ?? 0.1,
      calculatedAt: json['calculatedAt'] != null 
          ? DateTime.parse(json['calculatedAt'])
          : DateTime.now(),
    );
  }

  // 後方互換性のためのアクセサー
  double get pitchAccuracy => pitchAccuracyScore;
  double get stability => stabilityScore;
  double get timing => timingScore;
  
  /// スコアのパーセンテージ表示
  String get totalScorePercentage => '${(totalScore * 100).toStringAsFixed(1)}%';
}

/// ピッチ精度分析結果
class PitchAnalysis {
  final double averageDeviation;        // 平均音程のずれ (セント)
  final double maxDeviation;            // 最大音程のずれ
  final int correctNotes;               // 正確な音程の数
  final int totalNotes;                 // 総音程数
  final List<PitchPoint> pitchPoints;   // 時系列ピッチデータ
  final List<double> deviationHistory;  // ずれの履歴

  const PitchAnalysis({
    required this.averageDeviation,
    required this.maxDeviation,
    required this.correctNotes,
    required this.totalNotes,
    required this.pitchPoints,
    required this.deviationHistory,
  });

  /// 正確性の割合
  double get accuracyRatio => totalNotes > 0 ? correctNotes / totalNotes : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'averageDeviation': averageDeviation,
      'maxDeviation': maxDeviation,
      'correctNotes': correctNotes,
      'totalNotes': totalNotes,
      'pitchPoints': pitchPoints.map((p) => p.toJson()).toList(),
      'deviationHistory': deviationHistory,
    };
  }

  factory PitchAnalysis.fromJson(Map<String, dynamic> json) {
    return PitchAnalysis(
      averageDeviation: json['averageDeviation'].toDouble(),
      maxDeviation: json['maxDeviation'].toDouble(),
      correctNotes: json['correctNotes'],
      totalNotes: json['totalNotes'],
      pitchPoints: (json['pitchPoints'] as List)
          .map((p) => PitchPoint.fromJson(p))
          .toList(),
      deviationHistory: List<double>.from(json['deviationHistory']),
    );
  }
}

/// 個別のピッチポイント
class PitchPoint {
  final double timestamp;      // 時間(秒)
  final double referencePitch; // 基準ピッチ(Hz)
  final double recordedPitch;  // 録音ピッチ(Hz)
  final double deviation;      // ずれ(セント)

  const PitchPoint({
    required this.timestamp,
    required this.referencePitch,
    required this.recordedPitch,
    required this.deviation,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'referencePitch': referencePitch,
      'recordedPitch': recordedPitch,
      'deviation': deviation,
    };
  }

  factory PitchPoint.fromJson(Map<String, dynamic> json) {
    return PitchPoint(
      timestamp: json['timestamp'].toDouble(),
      referencePitch: json['referencePitch'].toDouble(),
      recordedPitch: json['recordedPitch'].toDouble(),
      deviation: json['deviation'].toDouble(),
    );
  }

  // 後方互換性のためのアクセサー
  double get timeSeconds => timestamp;
}

/// タイミング分析結果
class TimingAnalysis {
  final double averageLatency;     // 平均遅延(秒)
  final double maxLatency;         // 最大遅延
  final int earlyNotes;            // 早すぎる音程数
  final int lateNotes;             // 遅すぎる音程数
  final int onTimeNotes;           // タイミング良好な音程数
  final List<double> latencyHistory; // 遅延履歴

  const TimingAnalysis({
    required this.averageLatency,
    required this.maxLatency,
    required this.earlyNotes,
    required this.lateNotes,
    required this.onTimeNotes,
    required this.latencyHistory,
  });

  /// タイミング正確性の割合
  double get timingAccuracy {
    final total = earlyNotes + lateNotes + onTimeNotes;
    return total > 0 ? onTimeNotes / total : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'averageLatency': averageLatency,
      'maxLatency': maxLatency,
      'earlyNotes': earlyNotes,
      'lateNotes': lateNotes,
      'onTimeNotes': onTimeNotes,
      'latencyHistory': latencyHistory,
    };
  }

  factory TimingAnalysis.fromJson(Map<String, dynamic> json) {
    return TimingAnalysis(
      averageLatency: json['averageLatency'].toDouble(),
      maxLatency: json['maxLatency'].toDouble(),
      earlyNotes: json['earlyNotes'],
      lateNotes: json['lateNotes'],
      onTimeNotes: json['onTimeNotes'],
      latencyHistory: List<double>.from(json['latencyHistory']),
    );
  }

  /// ScoringServiceで期待されるプロパティ
  double get overallTimingScore => timingAccuracy;
  double get averageDelay => averageLatency;
  bool get isOnTime => timingAccuracy > 0.8;
  List<TimingDeviation> get deviations => _generateDeviations();

  List<TimingDeviation> _generateDeviations() {
    final deviations = <TimingDeviation>[];
    for (int i = 0; i < latencyHistory.length; i++) {
      final deviation = latencyHistory[i];
      if (deviation.abs() > 0.1) { // 100ms以上のずれを記録
        deviations.add(TimingDeviation(
          timestamp: i * 0.1, // 100msごと
          deviation: deviation.abs(),
          isEarly: deviation < 0,
        ));
      }
    }
    return deviations;
  }
}

/// 安定性分析結果
class StabilityAnalysis {
  final double averageVariation;   // 平均変動量(セント)
  final double maxVariation;       // 最大変動量
  final int stableNotes;          // 安定した音程数
  final int unstableNotes;        // 不安定な音程数
  final List<double> variationHistory; // 変動履歴

  const StabilityAnalysis({
    required this.averageVariation,
    required this.maxVariation,
    required this.stableNotes,
    required this.unstableNotes,
    required this.variationHistory,
  });

  /// 安定性の割合
  double get stabilityRatio {
    final total = stableNotes + unstableNotes;
    return total > 0 ? stableNotes / total : 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'averageVariation': averageVariation,
      'maxVariation': maxVariation,
      'stableNotes': stableNotes,
      'unstableNotes': unstableNotes,
      'variationHistory': variationHistory,
    };
  }

  factory StabilityAnalysis.fromJson(Map<String, dynamic> json) {
    return StabilityAnalysis(
      averageVariation: json['averageVariation'].toDouble(),
      maxVariation: json['maxVariation'].toDouble(),
      stableNotes: json['stableNotes'],
      unstableNotes: json['unstableNotes'],
      variationHistory: List<double>.from(json['variationHistory']),
    );
  }

  /// 安定性判定のプロパティ
  bool get isStable => averageVariation < 15.0; // 15セント以下で安定と判定
  double get stabilityScore => math.max(0.0, (20.0 - averageVariation) / 20.0);
  List<StabilitySegment> get segments => _generateSegments();

  List<StabilitySegment> _generateSegments() {
    final segments = <StabilitySegment>[];
    const segmentDuration = 2.0; // 2秒のセグメント
    
    for (int i = 0; i < variationHistory.length; i += (44100 * segmentDuration).round()) {
      final endIndex = math.min(i + (44100 * segmentDuration).round(), variationHistory.length);
      final segmentData = variationHistory.sublist(i, endIndex);
      final segmentVariation = segmentData.reduce((a, b) => a + b) / segmentData.length;
      
      segments.add(StabilitySegment(
        startTime: i / 44100.0,
        endTime: endIndex / 44100.0,
        deviation: segmentVariation,
        isStable: segmentVariation < 15.0,
      ));
    }
    
    return segments;
  }
}

/// 安定性セグメント情報
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

/// タイミングずれ詳細情報
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