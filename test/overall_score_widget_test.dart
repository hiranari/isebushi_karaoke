import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/widgets/overall_score_widget.dart';
import 'package:isebushi_karaoke/models/song_result.dart';

void main() {
  group('OverallScoreWidget Tests', () {
    testWidgets('基本的なレンダリング', (WidgetTester tester) async {
      final mockResult = SongResult(
        songTitle: 'テスト楽曲',
        timestamp: DateTime.now(),
        totalScore: 82.0,
        scoreBreakdown: const ScoreBreakdown(
          pitchAccuracyScore: 80.0,
          stabilityScore: 85.0,
          timingScore: 78.0,
        ),
        pitchAnalysis: const PitchAnalysis(
          averageDeviation: 12.5,
          maxDeviation: 35.0,
          correctNotes: 85,
          totalNotes: 100,
          pitchPoints: [],
          deviationHistory: [],
        ),
        timingAnalysis: const TimingAnalysis(
          averageLatency: 0.05,
          maxLatency: 0.2,
          earlyNotes: 2,
          lateNotes: 8,
          onTimeNotes: 90,
          latencyHistory: [],
        ),
        stabilityAnalysis: const StabilityAnalysis(
          averageVariation: 5.2,
          maxVariation: 18.0,
          stableNotes: 88,
          unstableNotes: 12,
          variationHistory: [],
        ),
        feedback: const [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverallScoreWidget(result: mockResult),
          ),
        ),
      );

      // 楽曲タイトルが表示されるか確認
      expect(find.text('テスト楽曲'), findsOneWidget);
    });
  });
}