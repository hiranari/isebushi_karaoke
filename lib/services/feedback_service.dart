import '../models/song_result.dart';

/// Phase 3: フィードバック・改善提案を担当するサービスクラス
/// 
/// 単一責任原則: フィードバック生成のみに専念
/// 拡張性: 新しいフィードバックロジックの追加が容易
class FeedbackService {
  /// 包括的なフィードバックデータの生成
  /// 
  /// [scoreBreakdown] スコア内訳
  /// [analysisData] 詳細分析結果
  /// 戻り値: FeedbackData フィードバック・改善提案
  static FeedbackData generateFeedback({
    required ScoreBreakdown scoreBreakdown,
    required AnalysisData analysisData,
  }) {
    // 強みの分析
    final strengths = _identifyStrengths(scoreBreakdown, analysisData);
    
    // 改善ポイントの特定
    final improvementPoints = _identifyImprovementPoints(scoreBreakdown, analysisData);
    
    // 具体的なアドバイスの生成
    final actionableAdvice = _generateActionableAdvice(scoreBreakdown, analysisData);
    
    // 練習推奨エリアの提案
    final practiceAreas = _recommendPracticeAreas(scoreBreakdown, analysisData);

    return FeedbackData(
      strengths: strengths,
      improvementPoints: improvementPoints,
      actionableAdvice: actionableAdvice,
      practiceAreas: practiceAreas,
    );
  }

  /// 強みの分析
  static List<String> _identifyStrengths(
    ScoreBreakdown scoreBreakdown,
    AnalysisData analysisData,
  ) {
    final strengths = <String>[];

    // 音程精度の強み
    if (scoreBreakdown.pitchAccuracy >= 85.0) {
      strengths.add('音程精度が非常に優秀です');
    } else if (scoreBreakdown.pitchAccuracy >= 75.0) {
      strengths.add('音程の正確性が良好です');
    }

    // 安定性の強み
    if (scoreBreakdown.stability >= 85.0) {
      strengths.add('音程が非常に安定しています');
    } else if (scoreBreakdown.stability >= 75.0) {
      strengths.add('歌声の安定感があります');
    }

    // タイミングの強み
    if (scoreBreakdown.timing >= 85.0) {
      strengths.add('タイミングが非常に正確です');
    } else if (scoreBreakdown.timing >= 75.0) {
      strengths.add('リズム感が良好です');
    }

    // 統計情報からの強み
    if (analysisData.statistics.accuracyRate >= 0.8) {
      strengths.add('全体的な音程の一致率が高いです');
    }

    if (strengths.isEmpty) {
      strengths.add('歌唱に取り組む姿勢が素晴らしいです');
    }

    return strengths;
  }

  /// 改善ポイントの特定
  static List<ImprovementPoint> _identifyImprovementPoints(
    ScoreBreakdown scoreBreakdown,
    AnalysisData analysisData,
  ) {
    final improvementPoints = <ImprovementPoint>[];

    // 音程精度の改善ポイント
    if (scoreBreakdown.pitchAccuracy < 70.0) {
      improvementPoints.add(ImprovementPoint(
        category: 'pitch',
        description: '音程の正確性を向上させる必要があります',
        severity: scoreBreakdown.pitchAccuracy / 100.0,
      ));
    }

    // 安定性の改善ポイント
    if (scoreBreakdown.stability < 70.0) {
      improvementPoints.add(ImprovementPoint(
        category: 'stability',
        description: '音程の安定性を高める練習が必要です',
        severity: scoreBreakdown.stability / 100.0,
      ));
    }

    // タイミングの改善ポイント
    if (scoreBreakdown.timing < 70.0) {
      improvementPoints.add(ImprovementPoint(
        category: 'timing',
        description: 'リズムとタイミングの向上が期待されます',
        severity: scoreBreakdown.timing / 100.0,
      ));
    }

    // 特定時間帯の問題分析
    _analyzeTimeSpecificIssues(analysisData, improvementPoints);

    return improvementPoints;
  }

  /// 特定時間帯の問題分析
  static void _analyzeTimeSpecificIssues(
    AnalysisData analysisData,
    List<ImprovementPoint> improvementPoints,
  ) {
    // 安定性の時間的変化を分析
    final stabilityOverTime = analysisData.stabilityOverTime;
    if (stabilityOverTime.isNotEmpty) {
      for (int i = 0; i < stabilityOverTime.length; i++) {
        if (stabilityOverTime[i] < 50.0) {
          final timestamp = Duration(
            milliseconds: (i * 100).toInt(), // 仮定: 100msごとのデータ
          );
          improvementPoints.add(ImprovementPoint(
            category: 'stability',
            description: '${_formatDuration(timestamp)}付近で音程が不安定です',
            severity: stabilityOverTime[i] / 100.0,
            timestamp: timestamp,
          ));
        }
      }
    }

    // タイミングポイントの分析
    final lowTimingPoints = analysisData.timingPoints
        .where((tp) => tp.timingAccuracy < 0.5)
        .toList();
    
    for (final point in lowTimingPoints.take(3)) { // 最大3つまで
      improvementPoints.add(ImprovementPoint(
        category: 'timing',
        description: '${_formatDuration(point.timestamp)}でタイミングのずれがあります',
        severity: point.timingAccuracy,
        timestamp: point.timestamp,
      ));
    }
  }

  /// 具体的なアドバイスの生成
  static List<String> _generateActionableAdvice(
    ScoreBreakdown scoreBreakdown,
    AnalysisData analysisData,
  ) {
    final advice = <String>[];

    // 最も改善が必要な項目に基づいたアドバイス
    final lowestScore = [
      ('pitch', scoreBreakdown.pitchAccuracy),
      ('stability', scoreBreakdown.stability),
      ('timing', scoreBreakdown.timing),
    ]..sort((a, b) => a.$2.compareTo(b.$2));

    final weakestArea = lowestScore.first.$1;

    switch (weakestArea) {
      case 'pitch':
        advice.addAll(_getPitchAccuracyAdvice(scoreBreakdown.pitchAccuracy));
        break;
      case 'stability':
        advice.addAll(_getStabilityAdvice(scoreBreakdown.stability));
        break;
      case 'timing':
        advice.addAll(_getTimingAdvice(scoreBreakdown.timing));
        break;
    }

    // 統計情報に基づいた追加アドバイス
    if (analysisData.statistics.accuracyRate < 0.5) {
      advice.add('楽譜を見ながらゆっくりと正確な音程で練習してみてください');
    }

    if (analysisData.pitchVariance > 1000) {
      advice.add('息遣いを安定させ、一定の声量で歌うことを意識してみてください');
    }

    return advice;
  }

  /// 音程精度向上のアドバイス
  static List<String> _getPitchAccuracyAdvice(double pitchAccuracy) {
    if (pitchAccuracy < 50.0) {
      return [
        'ピアノで基準となる音程を確認してから歌い始めてみてください',
        'ゆっくりとしたテンポで正確な音程を意識して練習しましょう',
        '録音を聞き返して、自分の音程と基準音程の違いを確認してください',
      ];
    } else if (pitchAccuracy < 70.0) {
      return [
        '音程移行時により注意深く歌ってみてください',
        '楽器と一緒に歌って音程感覚を養いましょう',
      ];
    } else {
      return [
        '細かい音程の調整に注意して、さらなる精度向上を目指しましょう',
      ];
    }
  }

  /// 安定性向上のアドバイス
  static List<String> _getStabilityAdvice(double stability) {
    if (stability < 50.0) {
      return [
        '腹式呼吸を意識して、安定した息の流れで歌ってみてください',
        '姿勢を正して、リラックスした状態で発声練習をしましょう',
        '長く伸ばす音で安定した音程を保つ練習をしてください',
      ];
    } else if (stability < 70.0) {
      return [
        '息継ぎのタイミングを見直して、音程の安定性を保ちましょう',
        '体の力を抜いて、自然な発声を心がけてください',
      ];
    } else {
      return [
        '現在の安定性を維持しながら、表現力の向上に取り組みましょう',
      ];
    }
  }

  /// タイミング向上のアドバイス
  static List<String> _getTimingAdvice(double timing) {
    if (timing < 50.0) {
      return [
        'メトロノームを使って、正確なテンポ感覚を身につけましょう',
        '原曲をよく聞いて、歌詞とメロディーのタイミングを把握してください',
        'ゆっくりとしたテンポから始めて、徐々に速度を上げて練習しましょう',
      ];
    } else if (timing < 70.0) {
      return [
        '音程変化のタイミングをより正確に捉えて歌ってみてください',
        '楽曲の構造を理解して、フレーズの始まりと終わりを意識しましょう',
      ];
    } else {
      return [
        '現在のタイミング感を活かして、より自然な表現を目指しましょう',
      ];
    }
  }

  /// 練習推奨エリアの提案
  static List<PracticeArea> _recommendPracticeAreas(
    ScoreBreakdown scoreBreakdown,
    AnalysisData analysisData,
  ) {
    final practiceAreas = <PracticeArea>[];

    // 最も低いスコアの項目を重点練習エリアとして推奨
    if (scoreBreakdown.pitchAccuracy <= scoreBreakdown.stability && 
        scoreBreakdown.pitchAccuracy <= scoreBreakdown.timing) {
      practiceAreas.add(PracticeArea(
        title: '音程精度の向上',
        description: '正確な音程で歌うための基礎練習',
        exercises: [
          'スケール練習（ドレミファソファミレド）',
          'ピアノと一緒に歌う音程確認練習',
          '楽器なしでの音程記憶練習',
        ],
      ));
    }

    if (scoreBreakdown.stability <= scoreBreakdown.pitchAccuracy && 
        scoreBreakdown.stability <= scoreBreakdown.timing) {
      practiceAreas.add(PracticeArea(
        title: '音程安定性の向上',
        description: '安定した音程を維持するための練習',
        exercises: [
          'ロングトーン練習（5秒以上音程を保持）',
          '腹式呼吸法の練習',
          'リップロールでの発声練習',
        ],
      ));
    }

    if (scoreBreakdown.timing <= scoreBreakdown.pitchAccuracy && 
        scoreBreakdown.timing <= scoreBreakdown.stability) {
      practiceAreas.add(PracticeArea(
        title: 'リズム・タイミングの向上',
        description: '正確なタイミングで歌うための練習',
        exercises: [
          'メトロノームに合わせた歌唱練習',
          'リズムパターンの反復練習',
          '原曲に合わせたシャドーイング',
        ],
      ));
    }

    return practiceAreas;
  }

  /// 時間の書式化
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}