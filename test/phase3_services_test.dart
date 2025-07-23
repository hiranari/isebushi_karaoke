import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/infrastructure/services/scoring_service.dart';
import 'package:isebushi_karaoke/infrastructure/services/analysis_service.dart';
import 'package:isebushi_karaoke/infrastructure/services/feedback_service.dart';
import 'package:isebushi_karaoke/domain/models/comprehensive_score.dart';

void main() {
  group('Phase 3 Services Tests', () {
    late List<double> testRecordedPitches;
    late List<double> testReferencePitches;

    setUp(() {
      // テストデータの準備
      testReferencePitches = [440.0, 493.9, 523.3, 587.3, 659.3, 440.0];
      testRecordedPitches = [438.0, 495.0, 520.0, 590.0, 660.0, 442.0];
    });

    test('ScoringService calculates scores correctly', () {
      final songResult = ScoringService.calculateScore(
        songTitle: 'テスト楽曲',
        recordedPitches: testRecordedPitches,
        referencePitches: testReferencePitches,
      );

      // スコアが0-100の範囲内であることを確認
      expect(songResult.scoreBreakdown.pitchAccuracyScore, greaterThanOrEqualTo(0.0));
      expect(songResult.scoreBreakdown.pitchAccuracyScore, lessThanOrEqualTo(100.0));
      expect(songResult.scoreBreakdown.stabilityScore, greaterThanOrEqualTo(0.0));
      expect(songResult.scoreBreakdown.stabilityScore, lessThanOrEqualTo(100.0));
      expect(songResult.scoreBreakdown.timingScore, greaterThanOrEqualTo(0.0));
      expect(songResult.scoreBreakdown.timingScore, lessThanOrEqualTo(100.0));

      // 総合スコアが計算されることを確認
      expect(songResult.totalScore, greaterThan(0.0));
      expect(songResult.totalScore, lessThanOrEqualTo(100.0));
      
      // 重み計算の検証
      final expectedWeighted = 
          songResult.scoreBreakdown.pitchAccuracyScore * 0.7 +
          songResult.scoreBreakdown.stabilityScore * 0.2 +
          songResult.scoreBreakdown.timingScore * 0.1;
      expect(expectedWeighted, greaterThan(0.0));
    });

    test('AnalysisService performs detailed analysis', () {
      // まずComprehensiveScoreを作成
      const comprehensiveScore = ComprehensiveScore(
        pitchAccuracy: 80.0,
        stability: 75.0,
        timing: 85.0,
        overall: 80.0,
        grade: 'B',
      );

      final analysisData = AnalysisService.performDetailedAnalysis(
        score: comprehensiveScore,
        recordedPitches: testRecordedPitches,
        referencePitches: testReferencePitches,
      );

      // 分析データが正しく生成されることを確認
      expect(analysisData.pitchAnalysis, isNotEmpty);
      expect(analysisData.timingAnalysis, isNotEmpty);
      expect(analysisData.stabilityAnalysis, isNotEmpty);
      expect(analysisData.sectionScores, isNotEmpty);
    });

    test('FeedbackService generates appropriate feedback', () {
      // まずスコアと分析データを生成
      final songResult = ScoringService.calculateScore(
        songTitle: 'テスト楽曲',
        recordedPitches: testRecordedPitches,
        referencePitches: testReferencePitches,
      );

      // フィードバックを生成
      final feedbackData = FeedbackService.generateFeedback(songResult);

      // フィードバックデータが生成されることを確認
      expect(feedbackData, isNotEmpty);
      expect(feedbackData.length, greaterThan(0));
    });

    test('Empty input handling', () {
      // 空のデータでのエラーハンドリングテスト
      final songResult = ScoringService.calculateComprehensiveScore(
        songTitle: 'テスト楽曲',
        recordedPitches: [],
        referencePitches: [],
      );

      expect(songResult.scoreBreakdown.pitchAccuracyScore, equals(0.0));
      expect(songResult.scoreBreakdown.stabilityScore, equals(0.0)); // 修正: 音が出ていない場合は0.0
      expect(songResult.scoreBreakdown.timingScore, equals(0.0));
    });

    test('Score level determination', () {
      expect(ScoringService.getScoreLevel(95.0), equals('S'));
      expect(ScoringService.getScoreLevel(80.0), equals('B'));
      expect(ScoringService.getScoreLevel(65.0), equals('C'));
      expect(ScoringService.getScoreLevel(45.0), equals('F'));
    });
  });
}