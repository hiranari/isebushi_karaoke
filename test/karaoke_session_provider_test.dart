import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/providers/karaoke_session_provider.dart';

/// Phase 3: KaraokeSessionProviderのテスト
/// 
/// リアルタイムピッチ検出と状態管理の動作を検証します。
void main() {
  group('KaraokeSessionProvider', () {
    late KaraokeSessionProvider provider;

    setUp(() {
      provider = KaraokeSessionProvider();
    });

    test('初期状態が正しく設定される', () {
      expect(provider.state, KaraokeSessionState.ready);
      expect(provider.isRecording, false);
      expect(provider.currentPitch, null);
      expect(provider.recordedPitches, isEmpty);
    });

    test('セッション初期化が正しく動作する', () {
      const songTitle = 'テスト楽曲';
      const referencePitches = [220.0, 440.0, 880.0];

      provider.initializeSession(songTitle, referencePitches);

      expect(provider.selectedSongTitle, songTitle);
      expect(provider.referencePitches, referencePitches);
      expect(provider.state, KaraokeSessionState.ready);
      expect(provider.recordedPitches, isEmpty);
    });

    test('録音開始時の状態変更が正しく動作する', () {
      provider.initializeSession('テスト楽曲', [220.0]);

      provider.startRecording();

      expect(provider.state, KaraokeSessionState.recording);
      expect(provider.isRecording, true);
      expect(provider.recordedPitches, isEmpty);
    });

    test('リアルタイムピッチ更新が正しく動作する', () {
      provider.initializeSession('テスト楽曲', [220.0]);
      provider.startRecording();

      // ピッチ値を更新
      provider.updateCurrentPitch(330.0);

      expect(provider.currentPitch, 330.0);
      expect(provider.recordedPitches, [330.0]);
    });

    test('録音中のピッチ値が正しく記録される', () {
      provider.initializeSession('テスト楽曲', [220.0]);
      provider.startRecording();

      // 複数のピッチ値を更新
      provider.updateCurrentPitch(220.0);
      provider.updateCurrentPitch(440.0);
      provider.updateCurrentPitch(null); // 無音
      provider.updateCurrentPitch(880.0);

      expect(provider.recordedPitches, [220.0, 440.0, 880.0]);
      expect(provider.currentPitch, 880.0);
    });

    test('録音停止時の状態変更が正しく動作する', () async {
      provider.initializeSession('テスト楽曲', [220.0]);
      provider.startRecording();
      provider.updateCurrentPitch(330.0);

      provider.stopRecording();

      // 録音停止後の状態を確認
      expect(provider.isRecording, false);
      expect(provider.recordedPitches, [330.0]);
      
      // 分析が完了するまで待つ
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 分析完了後の状態を確認
      expect(provider.state, KaraokeSessionState.completed);
    });

    test('録音停止後はピッチが記録されない', () {
      provider.initializeSession('テスト楽曲', [220.0]);
      provider.startRecording();
      provider.updateCurrentPitch(330.0);
      provider.stopRecording();

      // 録音停止後にピッチを更新
      provider.updateCurrentPitch(440.0);

      expect(provider.recordedPitches, [330.0]); // 追加されない
      expect(provider.currentPitch, 440.0); // 現在のピッチは更新される
    });

    test('無効なピッチ値は記録されない', () {
      provider.initializeSession('テスト楽曲', [220.0]);
      provider.startRecording();

      // 無効なピッチ値を更新
      provider.updateCurrentPitch(null);
      provider.updateCurrentPitch(-100.0);
      provider.updateCurrentPitch(0.0);
      provider.updateCurrentPitch(440.0); // 有効なピッチ

      expect(provider.recordedPitches, [440.0]);
    });

    test('セッションリセットが正しく動作する', () {
      provider.initializeSession('テスト楽曲', [220.0]);
      provider.startRecording();
      provider.updateCurrentPitch(330.0);

      provider.resetSession();

      expect(provider.state, KaraokeSessionState.ready);
      expect(provider.isRecording, false);
      expect(provider.currentPitch, null);
      expect(provider.recordedPitches, isEmpty);
    });

    test('不正な状態遷移が無視される', () {
      provider.initializeSession('テスト楽曲', [220.0]);

      // ready状態から直接stopRecordingを呼ぶ
      provider.stopRecording();

      expect(provider.state, KaraokeSessionState.ready);
      expect(provider.isRecording, false);
    });
  });
}