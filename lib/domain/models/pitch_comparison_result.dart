/// ピッチ比較結果を格納するデータモデル
class PitchComparisonResult {
  final double overallScore;
  final List<double> centDifferences;
  final List<AlignedPitchPair> alignedPitches;
  final PitchStabilityAnalysis stabilityAnalysis;
  final VibratoAnalysis vibratoAnalysis;
  final TimingAccuracyAnalysis timingAnalysis;
  final DateTime analyzedAt;

  const PitchComparisonResult({
    required this.overallScore,
    required this.centDifferences,
    required this.alignedPitches,
    required this.stabilityAnalysis,
    required this.vibratoAnalysis,
    required this.timingAnalysis,
    required this.analyzedAt,
  });

  /// JSONからPitchComparisonResultを生成
  factory PitchComparisonResult.fromJson(Map<String, dynamic> json) {
    return PitchComparisonResult(
      overallScore: json['overallScore'].toDouble(),
      centDifferences: List<double>.from(json['centDifferences']),
      alignedPitches: (json['alignedPitches'] as List)
          .map((item) => AlignedPitchPair.fromJson(item))
          .toList(),
      stabilityAnalysis: PitchStabilityAnalysis.fromJson(json['stabilityAnalysis']),
      vibratoAnalysis: VibratoAnalysis.fromJson(json['vibratoAnalysis']),
      timingAnalysis: TimingAccuracyAnalysis.fromJson(json['timingAnalysis']),
      analyzedAt: DateTime.parse(json['analyzedAt']),
    );
  }

  /// PitchComparisonResultをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'centDifferences': centDifferences,
      'alignedPitches': alignedPitches.map((pair) => pair.toJson()).toList(),
      'stabilityAnalysis': stabilityAnalysis.toJson(),
      'vibratoAnalysis': vibratoAnalysis.toJson(),
      'timingAnalysis': timingAnalysis.toJson(),
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  /// 統計サマリーを取得
  Map<String, dynamic> getSummary() {
    final validCentDiffs = centDifferences.where((diff) => diff.isFinite).toList();
    
    return {
      'overallScore': overallScore,
      'averageCentDifference': validCentDiffs.isEmpty 
          ? 0.0 
          : validCentDiffs.reduce((a, b) => a + b) / validCentDiffs.length,
      'maxCentDifference': validCentDiffs.isEmpty 
          ? 0.0 
          : validCentDiffs.reduce((a, b) => a > b ? a : b),
      'pitchStabilityScore': stabilityAnalysis.stabilityScore,
      'vibratoDetected': vibratoAnalysis.vibratoDetected,
      'timingAccuracyScore': timingAnalysis.accuracyScore,
      'alignedPitchCount': alignedPitches.length,
    };
  }
}

/// DTWアルゴリズムで時間同期されたピッチペア
class AlignedPitchPair {
  final double referencePitch;
  final double singingPitch;
  final double centDifference;
  final int referenceIndex;
  final int singingIndex;
  final double alignmentCost;

  const AlignedPitchPair({
    required this.referencePitch,
    required this.singingPitch,
    required this.centDifference,
    required this.referenceIndex,
    required this.singingIndex,
    required this.alignmentCost,
  });

  factory AlignedPitchPair.fromJson(Map<String, dynamic> json) {
    return AlignedPitchPair(
      referencePitch: json['referencePitch'].toDouble(),
      singingPitch: json['singingPitch'].toDouble(),
      centDifference: json['centDifference'].toDouble(),
      referenceIndex: json['referenceIndex'],
      singingIndex: json['singingIndex'],
      alignmentCost: json['alignmentCost'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referencePitch': referencePitch,
      'singingPitch': singingPitch,
      'centDifference': centDifference,
      'referenceIndex': referenceIndex,
      'singingIndex': singingIndex,
      'alignmentCost': alignmentCost,
    };
  }
}

/// ピッチ安定性分析結果
class PitchStabilityAnalysis {
  final double stabilityScore;
  final double pitchVariance;
  final double averageDeviation;
  final List<PitchStabilitySegment> segments;
  final int unstableRegionCount;

  const PitchStabilityAnalysis({
    required this.stabilityScore,
    required this.pitchVariance,
    required this.averageDeviation,
    required this.segments,
    required this.unstableRegionCount,
  });

  factory PitchStabilityAnalysis.fromJson(Map<String, dynamic> json) {
    return PitchStabilityAnalysis(
      stabilityScore: json['stabilityScore'].toDouble(),
      pitchVariance: json['pitchVariance'].toDouble(),
      averageDeviation: json['averageDeviation'].toDouble(),
      segments: (json['segments'] as List)
          .map((item) => PitchStabilitySegment.fromJson(item))
          .toList(),
      unstableRegionCount: json['unstableRegionCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stabilityScore': stabilityScore,
      'pitchVariance': pitchVariance,
      'averageDeviation': averageDeviation,
      'segments': segments.map((seg) => seg.toJson()).toList(),
      'unstableRegionCount': unstableRegionCount,
    };
  }
}

/// ピッチ安定性セグメント
class PitchStabilitySegment {
  final int startIndex;
  final int endIndex;
  final double stabilityScore;
  final bool isStable;

  const PitchStabilitySegment({
    required this.startIndex,
    required this.endIndex,
    required this.stabilityScore,
    required this.isStable,
  });

  factory PitchStabilitySegment.fromJson(Map<String, dynamic> json) {
    return PitchStabilitySegment(
      startIndex: json['startIndex'],
      endIndex: json['endIndex'],
      stabilityScore: json['stabilityScore'].toDouble(),
      isStable: json['isStable'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startIndex': startIndex,
      'endIndex': endIndex,
      'stabilityScore': stabilityScore,
      'isStable': isStable,
    };
  }
}

/// ビブラート分析結果
class VibratoAnalysis {
  final bool vibratoDetected;
  final double vibratoRate;
  final double vibratoDepth;
  final List<VibratoSegment> vibratoSegments;
  final double vibratoRegularityScore;

  const VibratoAnalysis({
    required this.vibratoDetected,
    required this.vibratoRate,
    required this.vibratoDepth,
    required this.vibratoSegments,
    required this.vibratoRegularityScore,
  });

  factory VibratoAnalysis.fromJson(Map<String, dynamic> json) {
    return VibratoAnalysis(
      vibratoDetected: json['vibratoDetected'],
      vibratoRate: json['vibratoRate'].toDouble(),
      vibratoDepth: json['vibratoDepth'].toDouble(),
      vibratoSegments: (json['vibratoSegments'] as List)
          .map((item) => VibratoSegment.fromJson(item))
          .toList(),
      vibratoRegularityScore: json['vibratoRegularityScore'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vibratoDetected': vibratoDetected,
      'vibratoRate': vibratoRate,
      'vibratoDepth': vibratoDepth,
      'vibratoSegments': vibratoSegments.map((seg) => seg.toJson()).toList(),
      'vibratoRegularityScore': vibratoRegularityScore,
    };
  }
}

/// ビブラートセグメント
class VibratoSegment {
  final int startIndex;
  final int endIndex;
  final double rate;
  final double depth;
  final double regularityScore;

  const VibratoSegment({
    required this.startIndex,
    required this.endIndex,
    required this.rate,
    required this.depth,
    required this.regularityScore,
  });

  factory VibratoSegment.fromJson(Map<String, dynamic> json) {
    return VibratoSegment(
      startIndex: json['startIndex'],
      endIndex: json['endIndex'],
      rate: json['rate'].toDouble(),
      depth: json['depth'].toDouble(),
      regularityScore: json['regularityScore'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startIndex': startIndex,
      'endIndex': endIndex,
      'rate': rate,
      'depth': depth,
      'regularityScore': regularityScore,
    };
  }
}

/// タイミング精度分析結果
class TimingAccuracyAnalysis {
  final double accuracyScore;
  final double averageTimeOffset;
  final double maxTimeOffset;
  final List<TimingDeviation> timingDeviations;
  final int significantDelayCount;

  const TimingAccuracyAnalysis({
    required this.accuracyScore,
    required this.averageTimeOffset,
    required this.maxTimeOffset,
    required this.timingDeviations,
    required this.significantDelayCount,
  });

  factory TimingAccuracyAnalysis.fromJson(Map<String, dynamic> json) {
    return TimingAccuracyAnalysis(
      accuracyScore: json['accuracyScore'].toDouble(),
      averageTimeOffset: json['averageTimeOffset'].toDouble(),
      maxTimeOffset: json['maxTimeOffset'].toDouble(),
      timingDeviations: (json['timingDeviations'] as List)
          .map((item) => TimingDeviation.fromJson(item))
          .toList(),
      significantDelayCount: json['significantDelayCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accuracyScore': accuracyScore,
      'averageTimeOffset': averageTimeOffset,
      'maxTimeOffset': maxTimeOffset,
      'timingDeviations': timingDeviations.map((dev) => dev.toJson()).toList(),
      'significantDelayCount': significantDelayCount,
    };
  }
}

/// タイミングずれ情報
class TimingDeviation {
  final int referenceIndex;
  final int singingIndex;
  final double timeOffset;
  final bool isSignificant;

  const TimingDeviation({
    required this.referenceIndex,
    required this.singingIndex,
    required this.timeOffset,
    required this.isSignificant,
  });

  factory TimingDeviation.fromJson(Map<String, dynamic> json) {
    return TimingDeviation(
      referenceIndex: json['referenceIndex'],
      singingIndex: json['singingIndex'],
      timeOffset: json['timeOffset'].toDouble(),
      isSignificant: json['isSignificant'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'referenceIndex': referenceIndex,
      'singingIndex': singingIndex,
      'timeOffset': timeOffset,
      'isSignificant': isSignificant,
    };
  }
}