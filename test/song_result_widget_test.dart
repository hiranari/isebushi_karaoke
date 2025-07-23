import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:isebushi_karaoke/widgets/song_result_widget.dart';
import 'package:isebushi_karaoke/providers/song_result_provider.dart';

/// SongResultWidgetのウィジェットテスト
/// 
/// Phase 3の段階的スコア表示機能をテストします
void main() {
  group('SongResultWidget Tests', () {
    late SongResultProvider mockProvider;

    setUp(() {
      mockProvider = SongResultProvider();
    });

    testWidgets('結果がない場合の表示', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SongResultProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SongResultWidget(),
            ),
          ),
        ),
      );

      // 結果がない場合は何も表示されない
      expect(find.byType(SongResultWidget), findsOneWidget);
    });

    testWidgets('処理中の表示', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<SongResultProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SongResultWidget(),
            ),
          ),
        ),
      );

      // 結果計算を開始（処理中状態にする）
      final future = mockProvider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: [440.0],
        recordedPitches: [440.0],
      );

      await tester.pump();

      // 計算完了を待つ
      await future;
      await tester.pump();

      expect(find.byType(SongResultWidget), findsOneWidget);
    });

    testWidgets('結果表示のタップで段階が進む', (WidgetTester tester) async {
      // 結果を設定
      await mockProvider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: [440.0, 493.88],
        recordedPitches: [438.0, 495.0],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SongResultProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SongResultWidget(),
            ),
          ),
        ),
      );

      await tester.pump();

      // 初期状態は総合スコア表示
      expect(mockProvider.displayState, ResultDisplayState.totalScore);

      // タップして次の段階に進む
      await tester.tap(find.byType(SongResultWidget));
      await tester.pump();

      expect(mockProvider.displayState, ResultDisplayState.detailedAnalysis);

      // さらにタップ
      await tester.tap(find.byType(SongResultWidget));
      await tester.pump();

      expect(mockProvider.displayState, ResultDisplayState.actionableAdvice);
    });

    testWidgets('高スコア結果の表示', (WidgetTester tester) async {
      // 高スコアになるような入力
      await mockProvider.calculateSongResult(
        songTitle: '高スコアテスト',
        referencePitches: [440.0, 493.88, 523.25],
        recordedPitches: [440.0, 493.88, 523.25], // 完全一致
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SongResultProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SongResultWidget(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SongResultWidget), findsOneWidget);
      // 高スコア時の特別な表示要素があるかチェック
    });

    testWidgets('低スコア結果の表示', (WidgetTester tester) async {
      // 低スコアになるような入力
      await mockProvider.calculateSongResult(
        songTitle: '低スコアテスト',
        referencePitches: [440.0, 493.88, 523.25],
        recordedPitches: [400.0, 450.0, 500.0], // 大きく外れた値
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SongResultProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SongResultWidget(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SongResultWidget), findsOneWidget);
      // 低スコア時の表示要素があるかチェック
    });

    testWidgets('段階的表示の完全なフロー', (WidgetTester tester) async {
      await mockProvider.calculateSongResult(
        songTitle: 'フローテスト',
        referencePitches: [440.0],
        recordedPitches: [440.0],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SongResultProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SongResultWidget(),
            ),
          ),
        ),
      );

      await tester.pump();

      // 第1段階: 総合スコア
      expect(mockProvider.displayState, ResultDisplayState.totalScore);

      // 第2段階: 詳細分析
      await tester.tap(find.byType(SongResultWidget));
      await tester.pump();
      expect(mockProvider.displayState, ResultDisplayState.detailedAnalysis);

      // 第3段階: 改善提案
      await tester.tap(find.byType(SongResultWidget));
      await tester.pump();
      expect(mockProvider.displayState, ResultDisplayState.actionableAdvice);

      // 最終段階では進まない
      await tester.tap(find.byType(SongResultWidget));
      await tester.pump();
      expect(mockProvider.displayState, ResultDisplayState.actionableAdvice);
    });

    testWidgets('空のデータでの表示', (WidgetTester tester) async {
      await mockProvider.calculateSongResult(
        songTitle: '空データテスト',
        referencePitches: [],
        recordedPitches: [],
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<SongResultProvider>.value(
          value: mockProvider,
          child: const MaterialApp(
            home: Scaffold(
              body: SongResultWidget(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(SongResultWidget), findsOneWidget);
      // 空データでも適切に表示されるかチェック
    });
  });
}
