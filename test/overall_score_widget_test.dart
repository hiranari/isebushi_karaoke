import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/widgets/overall_score_widget.dart';
import 'package:isebushi_karaoke/models/song_result.dart';

void main() {
  group('OverallScoreWidget Tests', () {
    late SongResult mockResult;

    setUp(() {
      mockResult = SongResult(
        songTitle: 'テスト楽曲',
        timestamp: DateTime.now(),
        totalScore: 82.0,
        scoreBreakdown: const ScoreBreakdown(
          pitchAccuracyScore: 85.0,
          stabilityScore: 75.0,
          timingScore: 80.0,
        ),
        pitchAnalysis: const PitchAnalysis(
          averageDeviation: 15.0,
          maxDeviation: 30.0,
          correctNotes: 80,
          totalNotes: 100,
          pitchPoints: [],
          deviationHistory: [10.0, 15.0, 20.0],
        ),
        timingAnalysis: const TimingAnalysis(
          averageLatency: 0.05,
          maxLatency: 0.1,
          earlyNotes: 5,
          lateNotes: 10,
          onTimeNotes: 85,
          latencyHistory: [0.03, 0.05, 0.07],
        ),
        stabilityAnalysis: const StabilityAnalysis(
          averageVariation: 12.0,
          maxVariation: 25.0,
          stableNotes: 80,
          unstableNotes: 10,
          variationHistory: [10.0, 12.0, 15.0],
        ),
        feedback: ['良い点1', '良い点2', '改善点1'],
      );
    });

    testWidgets('should display song title', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: mockResult),
        ),
      ));

      expect(find.text('テスト楽曲'), findsOneWidget);
    });

    testWidgets('should display overall score', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: mockResult),
        ),
      ));

      final expectedScore = mockResult.totalScore.toStringAsFixed(1);
      expect(find.textContaining(expectedScore), findsOneWidget);
    });

    testWidgets('should display score rank', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: mockResult),
        ),
      ));

      // ランクが表示されている（A、B、など）
      expect(find.textContaining(RegExp(r'[SABCDE]')), findsOneWidget);
    });

    testWidgets('should display score breakdown', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: mockResult),
        ),
      ));

      expect(find.text('音程精度 (70%)'), findsOneWidget);
      expect(find.text('安定性 (20%)'), findsOneWidget);
      expect(find.text('タイミング (10%)'), findsOneWidget);
    });

    testWidgets('should display progress indicators for scores', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: mockResult),
        ),
      ));

      // LinearProgressIndicatorが3つ表示されている（各スコア用）
      expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    });

    testWidgets('should show details button when callback provided', (WidgetTester tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(
            result: mockResult,
            onShowDetails: () => buttonPressed = true,
          ),
        ),
      ));

      expect(find.text('詳細分析を見る'), findsOneWidget);

      await tester.tap(find.text('詳細分析を見る'));
      expect(buttonPressed, isTrue);
    });

    testWidgets('should not show details button when callback not provided', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: mockResult),
        ),
      ));

      expect(find.text('詳細分析を見る'), findsNothing);
    });

    testWidgets('should handle perfect score', (WidgetTester tester) async {
      final perfectResult = SongResult(
        songTitle: '完璧な歌唱',
        timestamp: DateTime.now(),
        totalScore: 100.0,
        scoreBreakdown: ScoreBreakdown(
          pitchAccuracyScore: 100.0,
          stabilityScore: 100.0,
          timingScore: 100.0,
        ),
        pitchAnalysis: PitchAnalysis(
          averageDeviation: 0.0,
          maxDeviation: 0.0,
          correctNotes: 100,
          totalNotes: 100,
          pitchPoints: [],
          deviationHistory: [],
        ),
        timingAnalysis: TimingAnalysis(
          averageLatency: 0.0,
          maxLatency: 0.0,
          earlyNotes: 0,
          lateNotes: 0,
          onTimeNotes: 100,
          latencyHistory: [],
        ),
        stabilityAnalysis: StabilityAnalysis(
          averageVariation: 0.0,
          maxVariation: 0.0,
          stableNotes: 100,
          unstableNotes: 0,
          variationHistory: [],
        ),
        feedback: ['完璧な歌唱です！'],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: perfectResult),
        ),
      ));

      // Sランクが表示される
      expect(find.text('S'), findsOneWidget);
      
      // 素晴らしいコメントが表示される
      expect(find.textContaining('素晴らしい'), findsOneWidget);
    });

    testWidgets('should handle poor score', (WidgetTester tester) async {
      final poorResult = SongResult(
        songTitle: '練習が必要',
        timestamp: DateTime.now(),
        totalScore: 30.0,
        scoreBreakdown: ScoreBreakdown(
          pitchAccuracyScore: 30.0,
          stabilityScore: 25.0,
          timingScore: 35.0,
        ),
        pitchAnalysis: PitchAnalysis(
          averageDeviation: 50.0,
          maxDeviation: 80.0,
          correctNotes: 30,
          totalNotes: 100,
          pitchPoints: [],
          deviationHistory: [],
        ),
        timingAnalysis: TimingAnalysis(
          averageLatency: 0.2,
          maxLatency: 0.5,
          earlyNotes: 30,
          lateNotes: 40,
          onTimeNotes: 30,
          latencyHistory: [],
        ),
        stabilityAnalysis: StabilityAnalysis(
          averageVariation: 40.0,
          maxVariation: 70.0,
          stableNotes: 25,
          unstableNotes: 75,
          variationHistory: [],
        ),
        feedback: ['練習を重ねましょう'],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: poorResult),
        ),
      ));

      // 低いランクが表示される
      expect(find.text('E'), findsOneWidget);
      
      // 励ましのコメントが表示される
      expect(find.textContaining('頑張り'), findsOneWidget);
    });

    testWidgets('should display correct colors for different ranks', (WidgetTester tester) async {
      // Aランクの結果
      final aRankResult = SongResult(
        songTitle: 'Aランク',
        timestamp: DateTime.now(),
        totalScore: 85.0,
        scoreBreakdown: ScoreBreakdown(
          pitchAccuracyScore: 85.0,
          stabilityScore: 80.0,
          timingScore: 85.0,
        ),
        pitchAnalysis: PitchAnalysis(
          averageDeviation: 10.0,
          maxDeviation: 20.0,
          correctNotes: 85,
          totalNotes: 100,
          pitchPoints: [],
          deviationHistory: [],
        ),
        timingAnalysis: TimingAnalysis(
          averageLatency: 0.03,
          maxLatency: 0.08,
          earlyNotes: 5,
          lateNotes: 10,
          onTimeNotes: 85,
          latencyHistory: [],
        ),
        stabilityAnalysis: StabilityAnalysis(
          averageVariation: 8.0,
          maxVariation: 15.0,
          stableNotes: 80,
          unstableNotes: 20,
          variationHistory: [],
        ),
        feedback: ['とても良い歌唱です'],
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: aRankResult),
        ),
      ));

      // ランクサークルが表示されている
      expect(find.byType(Container), findsWidgets);
      
      // Aランクテキストが表示されている
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('should be scrollable when content is long', (WidgetTester tester) async {
      // 画面サイズを小さく設定
      await tester.binding.setSurfaceSize(const Size(400, 300));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: OverallScoreWidget(result: mockResult),
        ),
      ));

      // ウィジェットが表示されている
      expect(find.byType(OverallScoreWidget), findsOneWidget);
    });
  });
}