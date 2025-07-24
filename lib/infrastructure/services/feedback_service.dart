import 'dart:math' as math;
import '../../domain/models/song_result.dart';

/// Phase 3: フィードバック生成サービス
/// 
/// 単一責任の原則に従い、歌唱結果から具体的で実行可能な
/// 改善アドバイスを生成することに特化したサービスです。
class FeedbackService {
  /// 歌唱結果から包括的なフィードバックを生成
  /// 
  /// [songResult] 分析済みの歌唱結果
  /// 戻り値: 実行可能なアドバイスのリスト
  static List<String> generateFeedback(SongResult songResult) {
    final feedback = <String>[];
    
    // ピッチ精度のフィードバック
    feedback.addAll(_generatePitchFeedback(songResult.pitchAnalysis));
    
    // 安定性のフィードバック
    feedback.addAll(_generateStabilityFeedback(songResult.stabilityAnalysis));
    
    // タイミングのフィードバック
    feedback.addAll(_generateTimingFeedback(songResult.timingAnalysis));
    
    // 総合的なフィードバック
    feedback.addAll(_generateOverallFeedback(songResult));
    
    return feedback;
  }

  /// 後方互換性のためのメソッド - スコア内訳とデータからフィードバック生成
  static Map<String, List<String>> generateComprehensiveFeedback({
    required ScoreBreakdown scoreBreakdown,
    required Map<String, dynamic> analysisData,
  }) {
    final Map<String, List<String>> result = {
      'strengths': <String>[],
      'actionableAdvice': <String>[],
      'improvementPoints': <String>[],
      'practiceAreas': <String>[],
    };
    
    // スコアに基づくフィードバック生成
    if (scoreBreakdown.pitchAccuracyScore >= 80) {
      result['strengths']!.add('音程精度が優秀です');
    } else {
      result['improvementPoints']!.add('音程精度の向上');
      result['practiceAreas']!.add('音程練習');
    }
    
    if (scoreBreakdown.stabilityScore >= 80) {
      result['strengths']!.add('音程が安定しています');
    } else {
      result['improvementPoints']!.add('音程安定性の向上');
      result['practiceAreas']!.add('ロングトーン練習');
    }
    
    if (scoreBreakdown.timingScore >= 80) {
      result['strengths']!.add('タイミングが良好です');
    } else {
      result['improvementPoints']!.add('タイミングの調整');
      result['practiceAreas']!.add('リズム練習');
    }
    
    // 実行可能なアドバイス
    result['actionableAdvice']!.addAll([
      '定期的な練習を続けましょう',
      '楽器と合わせて歌ってみてください',
      '録音を聞き返して客観的に評価しましょう',
    ]);
    
    return result;
  }

  /// ピッチ精度に関するフィードバック生成
  static List<String> _generatePitchFeedback(PitchAnalysis analysis) {
    final feedback = <String>[];
    
    // 正確性に基づくアドバイス
    if (analysis.accuracyRatio < 0.5) {
      feedback.add('🎵 音程の正確性を向上させましょう');
      feedback.add('💡 楽器と一緒に歌って、正しい音程を確認してみてください');
      feedback.add('🔧 音階練習を取り入れることをお勧めします');
    } else if (analysis.accuracyRatio < 0.7) {
      feedback.add('🎵 音程はかなり良好ですが、さらなる向上が期待できます');
      feedback.add('💡 特に難しい音程変化の部分を重点的に練習してみてください');
    } else if (analysis.accuracyRatio < 0.9) {
      feedback.add('🎵 音程の精度は高レベルです！');
      feedback.add('💡 細かな音程の微調整に注力すると、さらに完璧に近づけます');
    } else {
      feedback.add('🎵 素晴らしい音程精度です！');
      feedback.add('🌟 この精度を維持し続けることが大切です');
    }
    
    // 平均ずれに基づくアドバイス
    if (analysis.averageDeviation.abs() > 30) {
      feedback.add('🔧 全体的に音程が${analysis.averageDeviation > 0 ? "高め" : "低め"}の傾向があります');
      feedback.add('💡 基準音を意識して、音程を${analysis.averageDeviation > 0 ? "少し低く" : "少し高く"}調整してみてください');
    }
    
    // 最大ずれに基づくアドバイス
    if (analysis.maxDeviation.abs() > 100) {
      feedback.add('⚠️ 一部で大きな音程のずれが見られます');
      feedback.add('💡 歌詞の特定の部分で音程が不安定になっている可能性があります');
      feedback.add('🔧 問題のある箇所を特定し、部分練習を行うことをお勧めします');
    }
    
    return feedback;
  }

  /// 安定性に関するフィードバック生成
  static List<String> _generateStabilityFeedback(StabilityAnalysis analysis) {
    final feedback = <String>[];
    
    // 安定性比率に基づくアドバイス
    if (analysis.stabilityRatio < 0.6) {
      feedback.add('🌊 音程の安定性を向上させる必要があります');
      feedback.add('💡 腹式呼吸を意識して、声の震えを抑制してみてください');
      feedback.add('🔧 ロングトーンの練習で、安定した発声を身につけましょう');
    } else if (analysis.stabilityRatio < 0.8) {
      feedback.add('🌊 音程の安定性は良好ですが、さらなる改善の余地があります');
      feedback.add('💡 息の流れを一定に保つことを意識してみてください');
    } else {
      feedback.add('🌊 音程が非常に安定しています！');
      feedback.add('🌟 この安定性は素晴らしいレベルです');
    }
    
    // 変動量に基づくアドバイス
    if (analysis.averageVariation > 25) {
      feedback.add('🔧 音程の変動が大きめです');
      feedback.add('💡 声の震えを抑えるため、リラックスした状態で歌うことを心がけてください');
      feedback.add('🔧 支える筋肉を意識して、声を安定させる練習を行いましょう');
    }
    
    return feedback;
  }

  /// タイミングに関するフィードバック生成
  static List<String> _generateTimingFeedback(TimingAnalysis analysis) {
    final feedback = <String>[];
    
    // 実際のタイミング分析に基づく詳細フィードバック
    if (analysis.timingAccuracy < 0.7) {
      feedback.add('⏰ タイミングの改善が必要です');
      feedback.add('💡 伴奏をよく聞いて、リズムに合わせることを意識してください');
      feedback.add('🔧 メトロノームを使った練習をお勧めします');
      
      // 詳細な分析結果に基づく具体的アドバイス
      if (analysis.earlyNotes > analysis.lateNotes) {
        feedback.add('📊 早めに歌い始める傾向があります');
        feedback.add('💡 伴奏のタイミングを意識して、少し待ってから歌い始めてみてください');
      } else if (analysis.lateNotes > analysis.earlyNotes) {
        feedback.add('📊 遅れ気味に歌い始める傾向があります');
        feedback.add('💡 歌詞を事前に覚えて、より素早く反応できるようにしましょう');
      }
      
      if (analysis.maxLatency.abs() > 0.5) {
        feedback.add('⚠️ 大きなタイミングのずれが発生しています');
        feedback.add('🔧 特定の部分で大幅に遅れているか早すぎる可能性があります');
        feedback.add('💡 問題の箇所を特定し、その部分を重点的に練習してください');
      }
      
    } else if (analysis.timingAccuracy < 0.9) {
      feedback.add('⏰ タイミングは良好です');
      feedback.add('💡 より正確なタイミングを目指してみてください');
      
      if (analysis.averageLatency.abs() > 0.1) {
        feedback.add('📊 平均的に${analysis.averageLatency > 0 ? "遅れ" : "早め"}の傾向があります');
        feedback.add('💡 この傾向を意識して調整することで、さらに向上できます');
      }
      
    } else {
      feedback.add('⏰ 優れたタイミング感です！');
      feedback.add('🌟 この正確なタイミングを維持し続けることが重要です');
      
      if (analysis.averageLatency.abs() < 0.05) {
        feedback.add('🎯 極めて正確なタイミングです。プロレベルの精度をお持ちです');
      }
    }
    
    return feedback;
  }

  /// 総合的なフィードバック生成
  static List<String> _generateOverallFeedback(SongResult songResult) {
    final feedback = <String>[];
    final totalScore = songResult.totalScore;
    
    // 総合スコアに基づく全体評価
    if (totalScore >= 90) {
      feedback.add('🎉 素晴らしい歌唱です！プロレベルの実力をお持ちです');
      feedback.add('🌟 この調子で他の楽曲にもチャレンジしてみてください');
    } else if (totalScore >= 80) {
      feedback.add('👏 とても上手に歌えています！');
      feedback.add('💪 細かな調整で、さらに上のレベルを目指せます');
    } else if (totalScore >= 70) {
      feedback.add('😊 良い歌唱です！基本的な技術は身についています');
      feedback.add('📈 継続的な練習で確実に向上していきます');
    } else if (totalScore >= 60) {
      feedback.add('🎵 基礎は固まってきています');
      feedback.add('📚 基本的な発声練習から見直してみることをお勧めします');
    } else {
      feedback.add('🌱 これから伸びしろがたくさんあります！');
      feedback.add('📖 基礎練習を重視して、徐々にレベルアップしていきましょう');
    }
    
    // スコア内訳に基づく重点アドバイス
    final breakdown = songResult.scoreBreakdown;
    final weakestArea = _identifyWeakestArea(breakdown);
    
    switch (weakestArea) {
      case 'pitch':
        feedback.add('🎯 今回は特に音程の練習に重点を置くことをお勧めします');
        break;
      case 'stability':
        feedback.add('🎯 今回は特に音程の安定性向上に重点を置くことをお勧めします');
        break;
      case 'timing':
        feedback.add('🎯 今回は特にタイミングの練習に重点を置くことをお勧めします');
        break;
    }
    
    return feedback;
  }

  /// 最も弱い分野を特定
  static String _identifyWeakestArea(ScoreBreakdown breakdown) {
    final scores = {
      'pitch': breakdown.pitchAccuracyScore,
      'stability': breakdown.stabilityScore,
      'timing': breakdown.timingScore,
    };
    
    return scores.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  /// 練習メニューの提案
  static List<String> suggestPracticeRoutine(SongResult songResult) {
    final suggestions = <String>[];
    final breakdown = songResult.scoreBreakdown;
    
    // 音程精度向上のための練習メニュー
    if (breakdown.pitchAccuracyScore < 75) {
      suggestions.add('🎼 音階練習: ド・レ・ミ・ファ・ソ・ラ・シ・ドを正確に歌う');
      suggestions.add('🎹 楽器との合わせ練習: ピアノやアプリと一緒に歌う');
      suggestions.add('👂 聴音練習: 基準音を聞いて同じ音程で歌う');
    }
    
    // 安定性向上のための練習メニュー
    if (breakdown.stabilityScore < 75) {
      suggestions.add('🫁 腹式呼吸練習: 正しい呼吸法をマスターする');
      suggestions.add('🎵 ロングトーン練習: 同じ音程を長時間安定して保つ');
      suggestions.add('💪 体幹強化: 歌唱に必要な筋肉を鍛える');
    }
    
    // タイミング向上のための練習メニュー
    if (breakdown.timingScore < 75) {
      suggestions.add('🥁 メトロノーム練習: 正確なリズム感を身につける');
      suggestions.add('🎤 歌詞読み練習: 歌詞のリズムを正確に把握する');
      suggestions.add('👂 伴奏との合わせ練習: 楽器の音をよく聞いて歌う');
    }
    
    return suggestions;
  }

  /// 次回の目標設定の提案
  static Map<String, dynamic> suggestNextGoals(SongResult songResult) {
    final currentScore = songResult.totalScore;
    final breakdown = songResult.scoreBreakdown;
    
    // 実現可能な目標スコアを設定
    final targetScore = _calculateRealisticTarget(currentScore);
    
    // 各分野の目標を設定
    final pitchTarget = math.min(100.0, breakdown.pitchAccuracyScore + 5.0);
    final stabilityTarget = math.min(100.0, breakdown.stabilityScore + 5.0);
    final timingTarget = math.min(100.0, breakdown.timingScore + 5.0);
    
    return {
      'totalScoreTarget': targetScore,
      'pitchAccuracyTarget': pitchTarget,
      'stabilityTarget': stabilityTarget,
      'timingTarget': timingTarget,
      'message': '次回は総合スコア${targetScore.toStringAsFixed(1)}点を目指しましょう！',
    };
  }

  /// 実現可能な目標スコアを計算
  static double _calculateRealisticTarget(double currentScore) {
    if (currentScore < 60) return currentScore + 10;
    if (currentScore < 75) return currentScore + 7;
    if (currentScore < 85) return currentScore + 5;
    if (currentScore < 95) return currentScore + 3;
    return math.min(100.0, currentScore + 1);
  }
}