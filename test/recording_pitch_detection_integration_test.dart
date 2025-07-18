import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:isebushi_karaoke/providers/karaoke_session_provider.dart';
import 'package:isebushi_karaoke/widgets/realtime_pitch_visualizer.dart';

/// 録音開始後のピッチ表示とUI状態遷移のテスト
/// 
/// このテストは、問題の報告にあった「録音開始後にマイクに向かって発声しても
/// 画面上にピッチや波形などが一切変化しない」問題が修正されたことを確認します。
void main() {
  group('録音・ピッチ検出・UI連携テスト', () {
    late KaraokeSessionProvider provider;

    setUp(() {
      provider = KaraokeSessionProvider();
    });

    testWidgets('録音開始後にピッチが検出されUIが更新される', (WidgetTester tester) async {
      // テスト用のウィジェットを作成
      await tester.pumpWidget(
        ChangeNotifierProvider<KaraokeSessionProvider>(
          create: (_) => provider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<KaraokeSessionProvider>(
                builder: (context, sessionProvider, child) {
                  return Column(
                    children: [
                      // 録音状態を表示
                      Text(
                        '録音状態: ${sessionProvider.isRecording ? "録音中" : "停止中"}',
                        key: const Key('recording_status'),
                      ),
                      // 現在のピッチを表示
                      Text(
                        'ピッチ: ${sessionProvider.currentPitch?.toStringAsFixed(1) ?? "---"}Hz',
                        key: const Key('current_pitch'),
                      ),
                      // ピッチビジュアライザー
                      RealtimePitchVisualizer(
                        currentPitch: sessionProvider.currentPitch,
                        referencePitches: sessionProvider.referencePitches,
                        recordedPitches: sessionProvider.recordedPitches,
                        isRecording: sessionProvider.isRecording,
                      ),
                      // 録音ボタン
                      ElevatedButton(
                        onPressed: () {
                          if (sessionProvider.isRecording) {
                            sessionProvider.stopRecording();
                          } else {
                            sessionProvider.startRecording();
                          }
                        },
                        child: Text(sessionProvider.isRecording ? '録音停止' : '録音開始'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 初期状態の確認
      expect(find.text('録音状態: 停止中'), findsOneWidget);
      expect(find.text('ピッチ: ---Hz'), findsOneWidget);
      expect(find.text('録音開始'), findsOneWidget);

      // セッションを初期化
      provider.initializeSession('テスト楽曲', [220.0, 440.0, 880.0]);
      await tester.pump();

      // 録音を開始
      await tester.tap(find.text('録音開始'));
      await tester.pump();

      // 録音状態の変化を確認
      expect(find.text('録音状態: 録音中'), findsOneWidget);
      expect(find.text('録音停止'), findsOneWidget);

      // ピッチ値を更新（マイクからの入力をシミュレート）
      provider.updateCurrentPitch(330.0);
      await tester.pump();

      // ピッチがUIに反映されることを確認
      expect(find.text('ピッチ: 330.0Hz'), findsOneWidget);

      // 複数のピッチを更新
      provider.updateCurrentPitch(440.0);
      await tester.pump();
      expect(find.text('ピッチ: 440.0Hz'), findsOneWidget);

      // 無音の場合
      provider.updateCurrentPitch(null);
      await tester.pump();
      expect(find.text('ピッチ: ---Hz'), findsOneWidget);

      // 再度ピッチを検出
      provider.updateCurrentPitch(550.0);
      await tester.pump();
      expect(find.text('ピッチ: 550.0Hz'), findsOneWidget);

      // 録音を停止
      await tester.tap(find.text('録音停止'));
      await tester.pump();

      // 録音状態の変化を確認
      expect(find.text('録音状態: 停止中'), findsOneWidget);
      expect(find.text('録音開始'), findsOneWidget);

      // ピッチは表示されたまま
      expect(find.text('ピッチ: 550.0Hz'), findsOneWidget);
    });

    testWidgets('録音中のピッチデータが正しく記録される', (WidgetTester tester) async {
      // セッションを初期化
      provider.initializeSession('テスト楽曲', [220.0, 440.0]);
      
      // 録音を開始
      provider.startRecording();
      expect(provider.isRecording, true);
      expect(provider.recordedPitches, isEmpty);

      // 複数のピッチを更新
      provider.updateCurrentPitch(220.0);
      provider.updateCurrentPitch(330.0);
      provider.updateCurrentPitch(null); // 無音は記録されない
      provider.updateCurrentPitch(440.0);
      provider.updateCurrentPitch(0.0);  // 無効なピッチは記録されない
      provider.updateCurrentPitch(550.0);

      // 録音されたピッチを確認
      expect(provider.recordedPitches, [220.0, 330.0, 440.0, 550.0]);

      // 録音を停止
      provider.stopRecording();
      expect(provider.isRecording, false);

      // 録音停止後はピッチが記録されない
      provider.updateCurrentPitch(660.0);
      expect(provider.recordedPitches, [220.0, 330.0, 440.0, 550.0]);
    });

    testWidgets('RealtimePitchVisualizerが録音状態に応じて動作する', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<KaraokeSessionProvider>(
          create: (_) => provider,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<KaraokeSessionProvider>(
                builder: (context, sessionProvider, child) {
                  return RealtimePitchVisualizer(
                    currentPitch: sessionProvider.currentPitch,
                    referencePitches: sessionProvider.referencePitches,
                    recordedPitches: sessionProvider.recordedPitches,
                    isRecording: sessionProvider.isRecording,
                  );
                },
              ),
            ),
          ),
        ),
      );

      // 初期状態でウィジェットが表示される
      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);

      // セッションを初期化
      provider.initializeSession('テスト楽曲', [220.0, 440.0]);
      await tester.pump();

      // 録音を開始
      provider.startRecording();
      await tester.pump();

      // ピッチを更新
      provider.updateCurrentPitch(330.0);
      await tester.pump();

      // ウィジェットが更新されることを確認（詳細は CustomPainter 内で処理）
      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);

      // 録音を停止
      provider.stopRecording();
      await tester.pump();

      // 停止後もウィジェットは表示される
      expect(find.byType(RealtimePitchVisualizer), findsOneWidget);
    });

    test('状態遷移が正しく動作する', () async {
      // 初期状態
      expect(provider.state, KaraokeSessionState.ready);
      expect(provider.isRecording, false);

      // セッション初期化
      provider.initializeSession('テスト楽曲', [220.0]);
      expect(provider.state, KaraokeSessionState.ready);

      // 録音開始
      provider.startRecording();
      expect(provider.state, KaraokeSessionState.recording);
      expect(provider.isRecording, true);

      // 録音停止
      provider.stopRecording();
      expect(provider.isRecording, false);

      // 分析が完了するまで待つ
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 分析完了後の状態を確認
      expect(provider.state, KaraokeSessionState.completed);
    });
  });
}