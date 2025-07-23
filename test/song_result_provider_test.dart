import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/application/providers/song_result_provider.dart';

/// SongResultProviderの単体テスト
/// 
/// Phase 3の段階的表示機能と結果管理をテストします
void main() {
  group('SongResultProvider Tests', () {
    late SongResultProvider provider;

    setUp(() {
      provider = SongResultProvider();
    });

    test('初期状態が正しく設定される', () {
      expect(provider.currentResult, isNull);
      expect(provider.isProcessing, false);
      expect(provider.processingStatus, isEmpty);
      expect(provider.displayState, ResultDisplayState.none);
    });

    test('結果計算開始時の状態変更', () async {
      // テスト用データ
      final referencePitches = [440.0, 493.88, 523.25];
      final recordedPitches = [438.0, 495.0, 520.0];

      // 計算実行（非同期）
      final future = provider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: referencePitches,
        recordedPitches: recordedPitches,
      );

      // 計算完了を待つ
      await future;

      // 計算完了後の状態確認
      expect(provider.isProcessing, false);
      expect(provider.currentResult, isNotNull);
    });

    test('段階的表示状態の進行', () async {
      // テスト用データ
      final referencePitches = [440.0, 493.88, 523.25];
      final recordedPitches = [438.0, 495.0, 520.0];

      // 結果を計算
      await provider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: referencePitches,
        recordedPitches: recordedPitches,
      );

      // 計算完了後の状態確認
      expect(provider.isProcessing, false);
      expect(provider.currentResult, isNotNull);
      expect(provider.displayState, ResultDisplayState.totalScore);

      // 段階的表示の進行テスト
      provider.advanceDisplayState();
      expect(provider.displayState, ResultDisplayState.detailedAnalysis);

      provider.advanceDisplayState();
      expect(provider.displayState, ResultDisplayState.actionableAdvice);

      // 最終段階では変化しない
      provider.advanceDisplayState();
      expect(provider.displayState, ResultDisplayState.actionableAdvice);
    });

    test('表示状態リセット', () async {
      // 結果を設定
      final referencePitches = [440.0];
      final recordedPitches = [440.0];
      
      await provider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: referencePitches,
        recordedPitches: recordedPitches,
      );

      // 表示状態を進行
      provider.advanceDisplayState();
      expect(provider.displayState, ResultDisplayState.detailedAnalysis);

      // リセット
      provider.resetDisplayState();
      expect(provider.displayState, ResultDisplayState.none);
      // 注意: resetDisplayStateは結果をクリアしない
      expect(provider.currentResult, isNotNull);
    });

    test('結果クリア', () async {
      // 結果を設定
      final referencePitches = [440.0];
      final recordedPitches = [440.0];
      
      await provider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: referencePitches,
        recordedPitches: recordedPitches,
      );

      expect(provider.currentResult, isNotNull);

      // 結果をクリア
      provider.clearResult();
      expect(provider.currentResult, isNull);
      expect(provider.displayState, ResultDisplayState.none);
    });

    test('空のデータでのエラーハンドリング', () async {
      await provider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: [],
        recordedPitches: [],
      );

      // 空のデータでも結果が生成される（0点のスコア）
      expect(provider.currentResult, isNotNull);
      expect(provider.currentResult!.totalScore, equals(0.0));
      expect(provider.isProcessing, false);
    });

    test('hasNextメソッドの動作確認', () {
      // none状態
      expect(provider.displayState.hasNext, true);

      // 各状態での確認
      expect(ResultDisplayState.totalScore.hasNext, true);
      expect(ResultDisplayState.detailedAnalysis.hasNext, true);
      expect(ResultDisplayState.actionableAdvice.hasNext, false);
    });

    test('複数回の結果計算', () async {
      final referencePitches = [440.0];
      final recordedPitches1 = [430.0];
      final recordedPitches2 = [450.0];

      // 1回目の計算
      await provider.calculateSongResult(
        songTitle: 'テスト楽曲1',
        referencePitches: referencePitches,
        recordedPitches: recordedPitches1,
      );
      
      final firstResult = provider.currentResult;
      expect(firstResult!.songTitle, 'テスト楽曲1');

      // 2回目の計算（新しい結果で上書き）
      await provider.calculateSongResult(
        songTitle: 'テスト楽曲2',
        referencePitches: referencePitches,
        recordedPitches: recordedPitches2,
      );

      final secondResult = provider.currentResult;
      expect(secondResult!.songTitle, 'テスト楽曲2');
      expect(secondResult.totalScore, isNot(equals(firstResult.totalScore)));
    });

    test('便利メソッドの動作確認', () async {
      // 結果がない時
      expect(provider.scoreLevel, isNull);
      expect(provider.isExcellentResult, false);
      expect(provider.recommendedFocus, isEmpty);

      // 結果を設定
      await provider.calculateSongResult(
        songTitle: 'テスト楽曲',
        referencePitches: [440.0],
        recordedPitches: [440.0],
      );

      // 結果がある時
      expect(provider.scoreLevel, isNotNull);
      expect(provider.recommendedFocus, isA<List<String>>());
    });
  });
}
