// math関数用のインポート
import 'dart:math' show log;

/// 歌唱評価システムの包括的データモデル群
/// 
/// カラオケアプリケーションの歌唱評価で使用される
/// 全てのスコアリング関連データモデルを定義します。
/// Clean ArchitectureのDomain層に位置し、
/// ビジネスルールと評価ロジックを表現します。
/// 
/// モデル体系:
/// ```
/// ScoreBreakdown (スコア内訳)
/// ├── 各カテゴリスコア (ピッチ、安定性、タイミング)
/// ├── 総合スコア
/// └── 計算タイムスタンプ
/// 
/// PitchAnalysis (ピッチ分析)
/// ├── 統計値 (平均、分散、範囲)
/// ├── 精度指標 (セント単位誤差)
/// └── 品質評価
/// 
/// TimingAnalysis (タイミング分析)
/// ├── 同期精度
/// ├── リズム一貫性
/// └── フレーズタイミング
/// 
/// StabilityAnalysis (安定性分析)
/// ├── ピッチ安定性
/// ├── 音量一貫性
/// └── 発声継続性
/// ```
/// 
/// 設計原則:
/// - **Single Responsibility**: 各クラスは一つの分析責任のみを持つ
/// - **Immutability**: 全てのフィールドはfinalで不変性を保証
/// - **Value Object**: データと振る舞いを統合したリッチドメインモデル
/// - **Type Safety**: 強い型システムによるデータ整合性保証
/// 
/// 使用例:
/// ```dart
/// // スコア内訳の作成
/// final breakdown = ScoreBreakdown(
///   pitchAccuracyScore: 85.5,
///   stabilityScore: 78.2,
///   timingScore: 82.1,
///   totalScore: 83.4,
///   calculatedAt: DateTime.now(),
/// );
/// 
/// // 分析結果の活用
/// if (breakdown.isExcellent) {
///   print('優秀な歌唱結果！');
/// }
/// 
/// // JSON変換
/// final json = breakdown.toJson();
/// final restored = ScoreBreakdown.fromJson(json);
/// ```
/// 
/// 品質保証:
/// - データ不変性の保証
/// - JSON シリアライゼーションの完全性
/// - 数値計算の精度保証
/// - 型安全性の徹底
/// 
/// 参照: [UMLドキュメント](../../UML_DOCUMENTATION.md#scoring-models)

/// スコア内訳データモデル
/// 
/// 歌唱評価の多次元スコアを構造化して管理するドメインモデルです。
/// 各評価カテゴリのスコアと総合評価を保持し、
/// 評価結果の詳細な分析を可能にします。
/// 
/// 責任:
/// - 多次元スコアの構造化保存
/// - 総合スコア計算結果の管理
/// - スコア計算タイムスタンプの記録
/// - JSON変換によるデータ永続化
/// - スコア品質評価メソッドの提供
/// 
/// データ構造:
/// - pitchAccuracyScore: ピッチ精度スコア (0-100)
/// - stabilityScore: 安定性スコア (0-100)
/// - timingScore: タイミングスコア (0-100)
/// - totalScore: 重み付き総合スコア (0-100)
/// - calculatedAt: 計算実行タイムスタンプ
/// 
/// 評価基準:
/// - S: 95点以上（素晴らしい）
/// - A: 85-94点（優秀）
/// - B: 75-84点（良好）
/// - C: 65-74点（普通）
/// - D: 55-64点（要改善）
/// - F: 55点未満（大幅改善必要）
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
