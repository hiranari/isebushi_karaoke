import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/infrastructure/services/pitch_detection_service.dart';
import 'package:isebushi_karaoke/core/utils/dummy_logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('単音ピッチ検出基本テスト', () {
    late PitchDetectionService service;
    final baseTestDir = path.join(
      Directory.current.path,
      'test_audio_c2_c4',
      'single_tones'
    );

    setUp(() {
      service = PitchDetectionService(logger: DummyLogger());
      service.initialize();
    });

    test('C2音（65.41Hz）の検出テスト', () async {
      // リポジトリ内のファイル名は "C2_65.41Hz.wav" のように周波数を含む場合があるため、
      // ディレクトリから 'C2' で始まるファイルを探して使用する
      final dir = Directory(baseTestDir);
      final candidates = dir
          .listSync()
          .whereType<File>()
          .where((f) => path.basename(f.path).toUpperCase().startsWith('C2'))
          .toList();

      expect(candidates.isNotEmpty, true, reason: 'テスト用音声ファイル C2 が存在しません');
      final audioFile = candidates.first;

      final result = await service.extractPitchFromAudio(
        sourcePath: audioFile.path,
        isAsset: false,
      );

      expect(result, isNotNull);
      expect(result.pitches, isNotEmpty);

      // 統計情報を取得
      final stats = service.getPitchStatistics(result.pitches);

      // 期待値との比較
      const expectedFrequency = 65.41; // C2の周波数
      const allowedDeviation = 1.0;    // 許容誤差 ±1Hz

      expect(stats['average'], closeTo(expectedFrequency, allowedDeviation),
          reason: 'C2音の平均周波数が期待値から大きく外れています');
      
      // 検出の安定性をチェック
      expect(stats['validRatio']!, greaterThan(0.8),
          reason: '有効なピッチ検出の割合が低すぎます（${stats['validRatio']!.toStringAsFixed(2)}）');
      
      final pitchVariation = (stats['max']! - stats['min']!).abs();
      expect(pitchVariation, lessThan(5.0),
          reason: 'ピッチの変動が大きすぎます（${pitchVariation.toStringAsFixed(2)}Hz）');
    });

    // 詳細なログ出力用
    tearDown(() {
      final logger = DummyLogger();
      logger.debug('--- テスト実行後の詳細 ---');
      logger.debug('検出された周波数の統計:');
      // stats の詳細を出力
    });
  });
}