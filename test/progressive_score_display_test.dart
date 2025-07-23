import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/presentation/widgets/karaoke/progressive_score_display.dart';
import 'package:isebushi_karaoke/domain/models/song_result.dart';
import 'package:isebushi_karaoke/application/providers/karaoke_session_provider.dart';

void main() {
  group('ProgressiveScoreDisplay Tests', () {
    testWidgets('基本的なレンダリング', (WidgetTester tester) async {
      final songResult = SongResult(
        songTitle: 'テスト楽曲',
        timestamp: DateTime.now(),
        totalScore: 85.0,
        scoreBreakdown: ScoreBreakdown(
          pitchAccuracyScore: 80.0,
          stabilityScore: 85.0,
          timingScore: 90.0,
        ),
        pitchAnalysis: const PitchAnalysis(
          averageDeviation: 10.0,
          maxDeviation: 25.0,
          correctNotes: 8,
          totalNotes: 10,
          pitchPoints: [],
          deviationHistory: [5.0, 10.0, 15.0],
        ),
        timingAnalysis: const TimingAnalysis(
          averageLatency: 50.0,
          maxLatency: 100.0,
          earlyNotes: 1,
          lateNotes: 1,
          onTimeNotes: 8,
          latencyHistory: [30.0, 50.0, 70.0],
        ),
        stabilityAnalysis: const StabilityAnalysis(
          averageVariation: 10.0,
          maxVariation: 25.0,
          stableNotes: 8,
          unstableNotes: 2,
          variationHistory: [8.0, 10.0, 12.0],
        ),
        feedback: ['素晴らしい歌唱です！'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveScoreDisplay(
              songResult: songResult,
              displayMode: ScoreDisplayMode.totalScore,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ProgressiveScoreDisplay), findsOneWidget);
    });

    testWidgets('段階的表示モード', (WidgetTester tester) async {
      final songResult = SongResult(
        songTitle: 'テスト楽曲',
        timestamp: DateTime.now(),
        totalScore: 85.0,
        scoreBreakdown: ScoreBreakdown(
          pitchAccuracyScore: 80.0,
          stabilityScore: 85.0,
          timingScore: 90.0,
        ),
        pitchAnalysis: const PitchAnalysis(
          averageDeviation: 10.0,
          maxDeviation: 25.0,
          correctNotes: 8,
          totalNotes: 10,
          pitchPoints: [],
          deviationHistory: [5.0, 10.0, 15.0],
        ),
        timingAnalysis: const TimingAnalysis(
          averageLatency: 50.0,
          maxLatency: 100.0,
          earlyNotes: 1,
          lateNotes: 1,
          onTimeNotes: 8,
          latencyHistory: [30.0, 50.0, 70.0],
        ),
        stabilityAnalysis: const StabilityAnalysis(
          averageVariation: 10.0,
          maxVariation: 25.0,
          stableNotes: 8,
          unstableNotes: 2,
          variationHistory: [8.0, 10.0, 12.0],
        ),
        feedback: ['素晴らしい歌唱です！'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProgressiveScoreDisplay(
              songResult: songResult,
              displayMode: ScoreDisplayMode.detailedAnalysis,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(ProgressiveScoreDisplay), findsOneWidget);
    });
  });
}
