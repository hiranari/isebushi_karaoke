/// Phase 3: 包括的スコアクラス
/// 
/// 歌唱パフォーマンスの全側面を評価する包括的なスコアリングシステム
class ComprehensiveScore {
  final double pitchAccuracy;
  final double stability;
  final double timing;
  final double overall;
  final String grade;
  final Map<String, double> weights;

  const ComprehensiveScore({
    required this.pitchAccuracy,
    required this.stability,
    required this.timing,
    required this.overall,
    required this.grade,
    this.weights = const {
      'pitchAccuracy': 0.7,
      'stability': 0.2,
      'timing': 0.1,
    },
  });

  /// スコアランクを取得
  String get scoreLevel {
    if (overall >= 95) return 'S';
    if (overall >= 85) return 'A';
    if (overall >= 75) return 'B';
    if (overall >= 65) return 'C';
    if (overall >= 55) return 'D';
    return 'F';
  }

  /// 優秀なスコアかどうか
  bool get isExcellent => overall >= 85;

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'pitchAccuracy': pitchAccuracy,
      'stability': stability,
      'timing': timing,
      'overall': overall,
      'grade': grade,
      'weights': weights,
    };
  }

  factory ComprehensiveScore.fromJson(Map<String, dynamic> json) {
    return ComprehensiveScore(
      pitchAccuracy: json['pitchAccuracy'].toDouble(),
      stability: json['stability'].toDouble(),
      timing: json['timing'].toDouble(),
      overall: json['overall'].toDouble(),
      grade: json['grade'],
      weights: Map<String, double>.from(json['weights'] ?? {}),
    );
  }
}
