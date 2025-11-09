/// ピッチ検証結果データクラス
/// 
/// 基準ピッチ検証の包括的な結果を格納
/// JSON形式での入出力に対応
class PitchVerificationResult {
  /// 検証対象のWAVファイルパス
  final String wavFilePath;
  
  /// 分析実行日時
  final DateTime analyzedAt;
  
  /// 抽出されたピッチデータ（Hz）
  final List<double> pitches;
  
  /// ピッチデータの統計情報
  final PitchStatistics statistics;
  
  /// キャッシュから読み込まれたかどうか
  final bool fromCache;
  
  /// 他のピッチデータとの比較結果（オプション）
  final ComparisonStats? comparison;

  const PitchVerificationResult({
    required this.wavFilePath,
    required this.analyzedAt,
    required this.pitches,
    required this.statistics,
    required this.fromCache,
    this.comparison,
  });

  /// JSON形式にシリアライズ
  Map<String, dynamic> toJson() {
    return {
      'wavFilePath': wavFilePath,
      'analyzedAt': analyzedAt.toIso8601String(),
      'pitches': pitches,
      'statistics': statistics.toJson(),
      'fromCache': fromCache,
      'comparison': comparison?.toJson(),
    };
  }

  /// JSONからデシリアライズ
  factory PitchVerificationResult.fromJson(Map<String, dynamic> json) {
    return PitchVerificationResult(
      wavFilePath: json['wavFilePath'] as String,
      analyzedAt: DateTime.parse(json['analyzedAt'] as String),
      pitches: (json['pitches'] as List<dynamic>).cast<double>(),
      statistics: PitchStatistics.fromJson(json['statistics'] as Map<String, dynamic>),
      fromCache: json['fromCache'] as bool,
      comparison: json['comparison'] != null 
          ? ComparisonStats.fromJson(json['comparison'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 見やすい文字列表現
  @override
  String toString() {
    return 'PitchVerificationResult(file: $wavFilePath, pitches: ${pitches.length}, fromCache: $fromCache)';
  }
}

/// ピッチデータの統計情報
class PitchStatistics {
  /// 総ピッチ数
  final int totalCount;
  
  /// 有効ピッチ数（0Hz以外）
  final int validCount;
  
  /// 無効ピッチ数（0Hz）
  final int invalidCount;
  
  /// 有効率（%）
  final double validRate;
  
  /// 最小ピッチ（Hz）
  final double minPitch;
  
  /// 最大ピッチ（Hz）
  final double maxPitch;
  
  /// 平均ピッチ（Hz）
  final double avgPitch;
  
  /// ピッチ範囲（Hz）
  final double pitchRange;
  
  /// 期待範囲内かどうか（C4-C5: 261.63-523.25Hz）
  final bool isInExpectedRange;
  
  /// 最初の10個のピッチ
  final List<double> firstTen;
  
  /// 最後の10個のピッチ
  final List<double> lastTen;

  const PitchStatistics({
    required this.totalCount,
    required this.validCount,
    required this.invalidCount,
    required this.validRate,
    required this.minPitch,
    required this.maxPitch,
    required this.avgPitch,
    required this.pitchRange,
    required this.isInExpectedRange,
    required this.firstTen,
    required this.lastTen,
  });

  /// JSON形式にシリアライズ
  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'validCount': validCount,
      'invalidCount': invalidCount,
      'validRate': validRate,
      'minPitch': minPitch,
      'maxPitch': maxPitch,
      'avgPitch': avgPitch,
      'pitchRange': pitchRange,
      'isInExpectedRange': isInExpectedRange,
      'firstTen': firstTen,
      'lastTen': lastTen,
    };
  }

  /// JSONからデシリアライズ
  factory PitchStatistics.fromJson(Map<String, dynamic> json) {
    return PitchStatistics(
      totalCount: json['totalCount'] as int,
      validCount: json['validCount'] as int,
      invalidCount: json['invalidCount'] as int,
      validRate: (json['validRate'] as num).toDouble(),
      minPitch: (json['minPitch'] as num).toDouble(),
      maxPitch: (json['maxPitch'] as num).toDouble(),
      avgPitch: (json['avgPitch'] as num).toDouble(),
      pitchRange: (json['pitchRange'] as num).toDouble(),
      isInExpectedRange: json['isInExpectedRange'] as bool,
      firstTen: (json['firstTen'] as List<dynamic>).cast<double>(),
      lastTen: (json['lastTen'] as List<dynamic>).cast<double>(),
    );
  }
}

/// ピッチデータ比較統計
class ComparisonStats {
  /// 類似度（0.0-1.0）
  final double similarity;
  
  /// 二乗平均平方根誤差（RMSE）
  final double rmse;
  
  /// 相関係数（-1.0 to 1.0）
  final double correlation;
  
  /// ピッチ差分リスト
  final List<double> differences;
  
  /// 比較結果サマリー
  final String comparisonSummary;

  const ComparisonStats({
    required this.similarity,
    required this.rmse,
    required this.correlation,
    required this.differences,
    required this.comparisonSummary,
  });

  /// JSON形式にシリアライズ
  Map<String, dynamic> toJson() {
    return {
      'similarity': similarity,
      'rmse': rmse,
      'correlation': correlation,
      'differences': differences,
      'comparisonSummary': comparisonSummary,
    };
  }

  /// JSONからデシリアライズ
  factory ComparisonStats.fromJson(Map<String, dynamic> json) {
    return ComparisonStats(
      similarity: (json['similarity'] as num).toDouble(),
      rmse: (json['rmse'] as num).toDouble(),
      correlation: (json['correlation'] as num).toDouble(),
      differences: (json['differences'] as List<dynamic>).cast<double>(),
      comparisonSummary: json['comparisonSummary'] as String,
    );
  }
}
