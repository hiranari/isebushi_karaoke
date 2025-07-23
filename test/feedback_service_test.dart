import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/services/feedback_service.dart';
import 'package:isebushi_karaoke/models/song_result.dart';

/// FeedbackServiceの単体テスト
/// 
/// フィードバック生成ロジックをテストします
void main() {
  group('FeedbackService Tests', () {
    group('高スコア時のフィードバック', () {
      test('完璧なスコアでのフィードバック生成', () {
        final perfectResult = _createMockSongResult(
          totalScore: 100.0,
          pitchAccuracy: 100.0,
          stability: 100.0,
          timing: 100.0,
        );

        final feedback = FeedbackService.generateFeedback(perfectResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('完璧') || f.contains('素晴らしい')), isTrue);
      });

      test('優秀なスコアでのフィードバック生成', () {
        final excellentResult = _createMockSongResult(
          totalScore: 95.0,
          pitchAccuracy: 95.0,
          stability: 93.0,
          timing: 97.0,
        );

        final feedback = FeedbackService.generateFeedback(excellentResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('優秀') || f.contains('素晴らしい')), isTrue);
      });

      test('良いスコアでのフィードバック生成', () {
        final goodResult = _createMockSongResult(
          totalScore: 85.0,
          pitchAccuracy: 85.0,
          stability: 82.0,
          timing: 88.0,
        );

        final feedback = FeedbackService.generateFeedback(goodResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('良い') || f.contains('上手')), isTrue);
      });
    });

    group('中程度スコア時のフィードバック', () {
      test('平均的なスコアでのフィードバック生成', () {
        final averageResult = _createMockSongResult(
          totalScore: 70.0,
          pitchAccuracy: 68.0,
          stability: 72.0,
          timing: 70.0,
        );

        final feedback = FeedbackService.generateFeedback(averageResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('練習') || f.contains('改善')), isTrue);
      });

      test('改善が必要なスコアでのフィードバック生成', () {
        final needsImprovementResult = _createMockSongResult(
          totalScore: 60.0,
          pitchAccuracy: 55.0,
          stability: 65.0,
          timing: 60.0,
        );

        final feedback = FeedbackService.generateFeedback(needsImprovementResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('練習') || f.contains('頑張')), isTrue);
      });
    });

    group('低スコア時のフィードバック', () {
      test('低スコアでのフィードバック生成', () {
        final poorResult = _createMockSongResult(
          totalScore: 40.0,
          pitchAccuracy: 35.0,
          stability: 45.0,
          timing: 40.0,
        );

        final feedback = FeedbackService.generateFeedback(poorResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('練習') || f.contains('基礎')), isTrue);
      });

      test('非常に低いスコアでのフィードバック生成', () {
        final veryPoorResult = _createMockSongResult(
          totalScore: 20.0,
          pitchAccuracy: 15.0,
          stability: 25.0,
          timing: 20.0,
        );

        final feedback = FeedbackService.generateFeedback(veryPoorResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('基礎') || f.contains('練習')), isTrue);
      });
    });

    group('特定項目の強化ポイント', () {
      test('ピッチ精度が低い場合のフィードバック', () {
        final pitchPoorResult = _createMockSongResult(
          totalScore: 60.0,
          pitchAccuracy: 40.0, // 低いピッチ精度
          stability: 70.0,
          timing: 75.0,
        );

        final feedback = FeedbackService.generateFeedback(pitchPoorResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('ピッチ') || f.contains('音程')), isTrue);
      });

      test('安定性が低い場合のフィードバック', () {
        final stabilityPoorResult = _createMockSongResult(
          totalScore: 60.0,
          pitchAccuracy: 75.0,
          stability: 35.0, // 低い安定性
          timing: 70.0,
        );

        final feedback = FeedbackService.generateFeedback(stabilityPoorResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('安定') || f.contains('ブレ')), isTrue);
      });

      test('タイミングが低い場合のフィードバック', () {
        final timingPoorResult = _createMockSongResult(
          totalScore: 60.0,
          pitchAccuracy: 70.0,
          stability: 75.0,
          timing: 35.0, // 低いタイミング
        );

        final feedback = FeedbackService.generateFeedback(timingPoorResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('タイミング') || f.contains('リズム')), isTrue);
      });
    });

    group('エッジケース', () {
      test('ゼロスコアでのフィードバック生成', () {
        final zeroResult = _createMockSongResult(
          totalScore: 0.0,
          pitchAccuracy: 0.0,
          stability: 0.0,
          timing: 0.0,
        );

        final feedback = FeedbackService.generateFeedback(zeroResult);

        expect(feedback, isNotEmpty);
        expect(feedback.any((f) => f.contains('練習') || f.contains('基礎')), isTrue);
      });

      test('不均等なスコアでのフィードバック生成', () {
        final unevenResult = _createMockSongResult(
          totalScore: 65.0,
          pitchAccuracy: 90.0, // 高い
          stability: 30.0,     // 低い
          timing: 75.0,        // 中程度
        );

        final feedback = FeedbackService.generateFeedback(unevenResult);

        expect(feedback, isNotEmpty);
        // 弱点（安定性）に対するアドバイスが含まれることを確認
        expect(feedback.any((f) => f.contains('安定')), isTrue);
        // 強み（ピッチ）への言及もあることを確認
        expect(feedback.any((f) => f.contains('ピッチ') || f.contains('音程')), isTrue);
      });
    });

    group('フィードバックの品質', () {
      test('フィードバックが空でないことを確認', () {
        final result = _createMockSongResult(
          totalScore: 75.0,
          pitchAccuracy: 75.0,
          stability: 75.0,
          timing: 75.0,
        );

        final feedback = FeedbackService.generateFeedback(result);

        expect(feedback, isNotEmpty);
        expect(feedback.every((f) => f.isNotEmpty), isTrue);
      });

      test('フィードバックの数が適切な範囲内', () {
        final result = _createMockSongResult(
          totalScore: 80.0,
          pitchAccuracy: 80.0,
          stability: 80.0,
          timing: 80.0,
        );

        final feedback = FeedbackService.generateFeedback(result);

        expect(feedback.length, greaterThanOrEqualTo(1));
        expect(feedback.length, lessThanOrEqualTo(10)); // 適度な数
      });

      test('フィードバックに具体性があることを確認', () {
        final result = _createMockSongResult(
          totalScore: 65.0,
          pitchAccuracy: 60.0,
          stability: 70.0,
          timing: 65.0,
        );

        final feedback = FeedbackService.generateFeedback(result);

        expect(feedback, isNotEmpty);
        // 具体的な改善方法が含まれていることを確認
        expect(feedback.any((f) => f.length > 10), isTrue); // ある程度の長さがある
      });
    });
  });
}

/// テスト用のSongResultを作成するヘルパーメソッド
SongResult _createMockSongResult({
  required double totalScore,
  required double pitchAccuracy,
  required double stability,
  required double timing,
}) {
  return SongResult(
    songTitle: 'テスト楽曲',
    timestamp: DateTime.now(),
    totalScore: totalScore,
    scoreBreakdown: ScoreBreakdown(
      pitchAccuracyScore: pitchAccuracy,
      stabilityScore: stability,
      timingScore: timing,
    ),
    pitchAnalysis: PitchAnalysis(
      averageDeviation: 100.0 - pitchAccuracy, // スコアに応じた偏差
      maxDeviation: (100.0 - pitchAccuracy) * 2,
      correctNotes: (pitchAccuracy * 0.8).round(),
      totalNotes: 80,
      pitchPoints: const [],
      deviationHistory: const [],
    ),
    timingAnalysis: TimingAnalysis(
      averageLatency: (100.0 - timing) * 0.01, // スコアに応じた遅延
      maxLatency: (100.0 - timing) * 0.02,
      earlyNotes: ((100.0 - timing) * 0.1).round(),
      lateNotes: ((100.0 - timing) * 0.15).round(),
      onTimeNotes: (timing * 0.8).round(),
      latencyHistory: const [],
    ),
    stabilityAnalysis: StabilityAnalysis(
      averageVariation: 100.0 - stability, // スコアに応じた変動
      maxVariation: (100.0 - stability) * 1.5,
      stableNotes: (stability * 0.8).round(),
      unstableNotes: ((100.0 - stability) * 0.8).round(),
      variationHistory: const [],
    ),
    feedback: const [], // フィードバックは空で開始
  );
}
