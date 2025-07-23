import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/presentation/widgets/karaoke/realtime_pitch_visualizer.dart';

/// RealtimePitchVisualizerのウィジェットテスト
/// 
/// リアルタイムピッチ可視化とジェスチャー機能をテストします
void main() {
  group('RealtimePitchVisualizer Widget Tests', () {
    testWidgets('基本的なレンダリング', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: 440.0,
              referencePitches: [440.0, 493.88, 523.25],
              recordedPitches: [438.0, 495.0],
              isRecording: true,
            ),
          ),
        ),
      );

      // ウィジェットが表示されることを確認
      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
      
      // RealtimePitchVisualizerの中にCustomPaintが含まれることを確認
      final visualizerFinder = find.byType(RealtimePitchVisualizer);
      expect(visualizerFinder, findsOneWidget);
      
      // CustomPaintが存在することを確認（複数あってもOK）
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('録音状態に応じた表示', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: 440.0,
              referencePitches: [440.0],
              recordedPitches: [440.0],
              isRecording: false, // 録音停止状態
            ),
          ),
        ),
      );

      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });

    testWidgets('nullピッチでのレンダリング', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: null, // ピッチなし
              referencePitches: [440.0],
              recordedPitches: [],
              isRecording: true,
            ),
          ),
        ),
      );

      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });

    testWidgets('空のデータでのレンダリング', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: null,
              referencePitches: [], // 空の基準ピッチ
              recordedPitches: [], // 空の録音ピッチ
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });

    testWidgets('タップジェスチャーが動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: 440.0,
              referencePitches: [440.0, 493.88],
              recordedPitches: [438.0, 495.0],
              isRecording: false,
            ),
          ),
        ),
      );

      // タップして詳細情報を表示
      await tester.tap(find.byType(RealtimePitchVisualizer));
      await tester.pumpAndSettle(); // アニメーションの完了を待つ

      // ウィジェット自体が正常に表示されていることを確認
      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });

    testWidgets('ダブルタップジェスチャーが動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: 440.0,
              referencePitches: [440.0, 493.88],
              recordedPitches: [438.0, 495.0],
              isRecording: false,
            ),
          ),
        ),
      );

      // ダブルタップ - より安全な方法で実行
      final center = tester.getCenter(find.byType(RealtimePitchVisualizer));
      
      // 最初のタップ
      await tester.tapAt(center);
      await tester.pump(const Duration(milliseconds: 50));
      
      // 2回目のタップ（ダブルタップとして認識される）
      await tester.tapAt(center);
      await tester.pumpAndSettle(); // すべてのアニメーションと非同期処理の完了を待つ
      
      // ウィジェット自体が正常に表示されていることを確認
      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });

    testWidgets('アニメーション関連のテスト', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: 440.0,
              referencePitches: [440.0],
              recordedPitches: [],
              isRecording: true,
            ),
          ),
        ),
      );

      // 初期描画
      await tester.pump();

      // ピッチ変更をシミュレート
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: 493.88, // ピッチ変更
              referencePitches: [440.0],
              recordedPitches: [440.0],
              isRecording: true,
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });

    testWidgets('極端なピッチ値でのレンダリング', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RealtimePitchVisualizer(
              currentPitch: 2000.0, // 非常に高いピッチ
              referencePitches: [80.0, 800.0], // 最低から最高の範囲
              recordedPitches: [2000.0],
              isRecording: false,
            ),
          ),
        ),
      );

      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });
  });
}
