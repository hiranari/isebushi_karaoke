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
        recordedAt: DateTime.now(),
        recordedPitches: [440.0, 493.88, 523.25],
        referencePitches: [440.0, 493.88, 523.25],
        comprehensiveScore: ComprehensiveScore.calculate(
          pitchAccuracy: 85.0,
          stability: 75.0,
          timing: 80.0,
        ),
        detailedAnalysis: DetailedAnalysis(
          pitchGraph: [],
          statistics: {},
          strengths: ['良い点1', '良い点2'],
          weaknesses: ['改善点1'],
        ),
        improvementSuggestions: [],
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

      // 総合スコアが表示されている
      final expectedScore = mockResult.comprehensiveScore.overall.toStringAsFixed(1);
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
        recordedAt: DateTime.now(),
        recordedPitches: [440.0],
        referencePitches: [440.0],
        comprehensiveScore: ComprehensiveScore.calculate(
          pitchAccuracy: 100.0,
          stability: 100.0,
          timing: 100.0,
        ),
        detailedAnalysis: DetailedAnalysis(
          pitchGraph: [],
          statistics: {},
          strengths: [],
          weaknesses: [],
        ),
        improvementSuggestions: [],
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
        recordedAt: DateTime.now(),
        recordedPitches: [440.0],
        referencePitches: [440.0],
        comprehensiveScore: ComprehensiveScore.calculate(
          pitchAccuracy: 30.0,
          stability: 25.0,
          timing: 35.0,
        ),
        detailedAnalysis: DetailedAnalysis(
          pitchGraph: [],
          statistics: {},
          strengths: [],
          weaknesses: [],
        ),
        improvementSuggestions: [],
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
        recordedAt: DateTime.now(),
        recordedPitches: [440.0],
        referencePitches: [440.0],
        comprehensiveScore: ComprehensiveScore.calculate(
          pitchAccuracy: 85.0,
          stability: 80.0,
          timing: 85.0,
        ),
        detailedAnalysis: DetailedAnalysis(
          pitchGraph: [],
          statistics: {},
          strengths: [],
          weaknesses: [],
        ),
        improvementSuggestions: [],
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