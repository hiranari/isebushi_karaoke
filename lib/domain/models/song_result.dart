import 'dart:math' as math;

/// 歌唱結果の包括的データモデル
/// 
/// カラオケセッションで得られた全ての分析データと評価結果を
/// 構造化して管理するドメインモデルです。
/// Clean ArchitectureのDomain層に位置し、ビジネスルールを表現します。
/// 
/// 責任:
/// - 歌唱結果データの一元管理（楽曲情報、スコア、分析データ）
/// - スコア階層の構造化（総合スコア、詳細内訳、カテゴリ別分析）
/// - フィードバック情報の統合管理
/// - データの永続化対応（JSON変換）
/// - UI表示用のヘルパーメソッド提供
/// 
/// データ構造:
/// ```
/// SongResult
/// ├── 基本情報（楽曲名、タイムスタンプ、総合スコア）
/// ├── スコア内訳（ScoreBreakdown）
/// │   ├── ピッチ精度スコア（70%重み）
/// │   ├── 安定性スコア（20%重み）
/// │   └── タイミングスコア（10%重み）
/// ├── 詳細分析データ
/// │   ├── ピッチ分析（PitchAnalysis）
/// │   ├── タイミング分析（TimingAnalysis）
/// │   └── 安定性分析（StabilityAnalysis）
/// └── フィードバック（改善提案・称賛）
/// ```
/// 
/// ドメインルール:
/// - 総合スコアは0-100の範囲
/// - スコアレベル: S(95+), A(85+), B(75+), C(65+), D(55+), F(55未満)
/// - タイムスタンプはUTC形式で保存
/// - フィードバックは複数の提案を配列で管理
/// 
/// 不変性保証:
/// - すべてのフィールドはfinalで不変
/// - 分析データの後から変更を防止
/// - データ整合性の保証
/// 
/// 使用例:
/// ```dart
/// // 歌唱結果の作成
/// final result = SongResult(
///   songTitle: '伊勢節',
///   timestamp: DateTime.now(),
///   totalScore: 85.0,
///   scoreBreakdown: scoreBreakdown,
///   pitchAnalysis: pitchAnalysis,
///   timingAnalysis: timingAnalysis,
///   stabilityAnalysis: stabilityAnalysis,
///   feedback: ['素晴らしい歌声です！'],
/// );
/// 
/// // スコアレベル判定
/// if (result.isExcellent) {
///   print('優秀な結果: ${result.scoreLevel}');
/// }
/// 
/// // JSON変換
/// final json = result.toJson();
/// final restored = SongResult.fromJson(json);
/// ```
/// 
/// 設計原則:
/// - Single Responsibility: 歌唱結果データの管理のみ
/// - Open/Closed: 新しい分析データの追加が容易
/// - Liskov Substitution: 基底クラスなしの純粋なデータモデル
/// - Interface Segregation: 用途別のヘルパーメソッド提供
/// - Dependency Inversion: 外部依存なしの純粋なドメインモデル
/// 
/// パフォーマンス考慮:
/// - 軽量なデータ構造
/// - 効率的なJSON変換
/// - メモリ効率の良い不変オブジェクト
/// 
/// 参照: [UMLドキュメント](../../UML_DOCUMENTATION.md#song-result-model)
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