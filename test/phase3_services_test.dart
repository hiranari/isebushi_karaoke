import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/services/scoring_service.dart';
import 'package:isebushi_karaoke/services/analysis_service.dart';
import 'package:isebushi_karaoke/services/feedback_service.dart';

void main() {
  group('Phase 3 Services Tests', () {
    late List<double> testRecordedPitches;
    late List<double> testReferencePitches;
    late List<double> testTimingAccuracies;

    setUp(() {
      // テストデータの準備
      testReferencePitches = [440.0, 493.9, 523.3, 587.3, 659.3, 440.0];
      testRecordedPitches = [438.0, 495.0, 520.0, 590.0, 660.0, 442.0];
      testTimingAccuracies = [0.9, 0.8, 0.7, 0.9, 0.8, 0.6];
    });

    test('ScoringService calculates scores correctly', () {
      final scoreBreakdown = ScoringService.calculateScore(
        recordedPitches: testRecordedPitches,
        referencePitches: testReferencePitches,
        timingAccuracies: testTimingAccuracies,
      );

      // スコアが0-100の範囲内であることを確認
      expect(scoreBreakdown.pitchAccuracy, greaterThanOrEqualTo(0.0));
      expect(scoreBreakdown.pitchAccuracy, lessThanOrEqualTo(100.0));
      expect(scoreBreakdown.stability, greaterThanOrEqualTo(0.0));
      expect(scoreBreakdown.stability, lessThanOrEqualTo(100.0));
      expect(scoreBreakdown.timing, greaterThanOrEqualTo(0.0));
      expect(scoreBreakdown.timing, lessThanOrEqualTo(100.0));

      // 重み付きスコアが計算されることを確認
      expect(scoreBreakdown.totalWeightedScore, greaterThan(0.0));
      
      // 重み計算の検証
      final expectedWeighted = 
          scoreBreakdown.pitchAccuracy * 0.7 +
          scoreBreakdown.stability * 0.2 +
          scoreBreakdown.timing * 0.1;
      expect(scoreBreakdown.totalWeightedScore, closeTo(expectedWeighted, 0.01));
    });

    test('AnalysisService performs detailed analysis', () {
      final analysisData = AnalysisService.performDetailedAnalysis(
        recordedPitches: testRecordedPitches,
        referencePitches: testReferencePitches,
        songDuration: const Duration(seconds: 30),
      );

      // 分析データが正しく生成されることを確認
      expect(analysisData.recordedPitches, equals(testRecordedPitches));
      expect(analysisData.referencePitches, equals(testReferencePitches));
      expect(analysisData.pitchDifferences.length, greaterThan(0));
      expect(analysisData.timingPoints.length, greaterThan(0));
      expect(analysisData.statistics.totalNotes, greaterThan(0));
      expect(analysisData.averageTimingAccuracy, greaterThanOrEqualTo(0.0));
      expect(analysisData.averageTimingAccuracy, lessThanOrEqualTo(1.0));
    });

    test('FeedbackService generates appropriate feedback', () {
      // まずスコアと分析データを生成
      final scoreBreakdown = ScoringService.calculateScore(
        recordedPitches: testRecordedPitches,
        referencePitches: testReferencePitches,
        timingAccuracies: testTimingAccuracies,
      );

      final analysisData = AnalysisService.performDetailedAnalysis(
        recordedPitches: testRecordedPitches,
        referencePitches: testReferencePitches,
        songDuration: const Duration(seconds: 30),
      );

      // フィードバックを生成
      final feedbackData = FeedbackService.generateFeedback(
        scoreBreakdown: scoreBreakdown,
        analysisData: analysisData,
      );

      // フィードバックデータが生成されることを確認
      expect(feedbackData.strengths, isNotEmpty);
      expect(feedbackData.actionableAdvice, isNotEmpty);
      
      // 改善ポイントまたは練習エリアのいずれかが提案されることを確認
      expect(
        feedbackData.improvementPoints.isNotEmpty || 
        feedbackData.practiceAreas.isNotEmpty, 
        isTrue
      );
    });

    test('Empty input handling', () {
      // 空のデータでのエラーハンドリングテスト
      final scoreBreakdown = ScoringService.calculateScore(
        recordedPitches: [],
        referencePitches: [],
        timingAccuracies: [],
      );

      expect(scoreBreakdown.pitchAccuracy, equals(0.0));
      expect(scoreBreakdown.stability, equals(100.0)); // 空の場合は安定とみなす
      expect(scoreBreakdown.timing, equals(0.0));
    });

    test('Score level determination', () {
      expect(ScoringService.getScoreLevel(95.0), equals('優秀'));
      expect(ScoringService.getScoreLevel(80.0), equals('良好'));
      expect(ScoringService.getScoreLevel(65.0), equals('標準'));
      expect(ScoringService.getScoreLevel(45.0), equals('要練習'));
    });
  });
}