/// Phase 3: 改善提案クラス
/// 
/// 歌唱技術向上のための具体的な提案を管理します
class ImprovementSuggestion {
  final String category;
  final String title;
  final String description;
  final int priority;
  final String specificAdvice;

  const ImprovementSuggestion({
    required this.category,
    required this.title,
    required this.description,
    required this.priority,
    required this.specificAdvice,
  });

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'priority': priority,
      'specificAdvice': specificAdvice,
    };
  }

  factory ImprovementSuggestion.fromJson(Map<String, dynamic> json) {
    return ImprovementSuggestion(
      category: json['category'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      specificAdvice: json['specificAdvice'],
    );
  }
}

/// 改善ポイントクラス
class ImprovementPoint {
  final String description;
  final String category;
  final int priority;

  const ImprovementPoint({
    required this.description,
    required this.category,
    required this.priority,
  });

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'category': category,
      'priority': priority,
    };
  }

  factory ImprovementPoint.fromJson(Map<String, dynamic> json) {
    return ImprovementPoint(
      description: json['description'],
      category: json['category'],
      priority: json['priority'],
    );
  }
}

/// 詳細分析クラス
class DetailedAnalysis {
  final Map<String, dynamic> pitchAnalysis;
  final Map<String, dynamic> timingAnalysis;
  final Map<String, dynamic> stabilityAnalysis;
  final Map<String, double> sectionScores;

  const DetailedAnalysis({
    required this.pitchAnalysis,
    required this.timingAnalysis,
    required this.stabilityAnalysis,
    required this.sectionScores,
  });

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'pitchAnalysis': pitchAnalysis,
      'timingAnalysis': timingAnalysis,
      'stabilityAnalysis': stabilityAnalysis,
      'sectionScores': sectionScores,
    };
  }

  factory DetailedAnalysis.fromJson(Map<String, dynamic> json) {
    return DetailedAnalysis(
      pitchAnalysis: Map<String, dynamic>.from(json['pitchAnalysis'] ?? {}),
      timingAnalysis: Map<String, dynamic>.from(json['timingAnalysis'] ?? {}),
      stabilityAnalysis: Map<String, dynamic>.from(json['stabilityAnalysis'] ?? {}),
      sectionScores: Map<String, double>.from(json['sectionScores'] ?? {}),
    );
  }
}

/// 分析統計クラス
class AnalysisStatistics {
  final double averageScore;
  final double bestSection;
  final double worstSection;
  final Map<String, double> categoryAverages;

  const AnalysisStatistics({
    required this.averageScore,
    required this.bestSection,
    required this.worstSection,
    required this.categoryAverages,
  });

  /// JSON変換
  Map<String, dynamic> toJson() {
    return {
      'averageScore': averageScore,
      'bestSection': bestSection,
      'worstSection': worstSection,
      'categoryAverages': categoryAverages,
    };
  }

  factory AnalysisStatistics.fromJson(Map<String, dynamic> json) {
    return AnalysisStatistics(
      averageScore: json['averageScore'].toDouble(),
      bestSection: json['bestSection'].toDouble(),
      worstSection: json['worstSection'].toDouble(),
      categoryAverages: Map<String, double>.from(json['categoryAverages'] ?? {}),
    );
  }
}
