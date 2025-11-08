import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/core/utils/dummy_logger.dart';
import 'package:isebushi_karaoke/infrastructure/services/pitch_detection_service.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void main() {
  group('単音のピッチ検出テスト', () {
    late PitchDetectionService service;
    final testAudioDir = path.join(
      Directory.current.path,
      'test_audio_c2_c4',
      'single_tones'
    );

    setUp(() {
      service = PitchDetectionService(logger: DummyLogger());
      service.initialize();
    });

    test('C3音（130.81Hz）の検出テスト', () async {
      final audioFile = File(path.join(testAudioDir, 'C3.wav'));
      expect(await audioFile.exists(), true, reason: 'テスト用音声ファイルが存在しません');

      // 音声ファイルを読み込んでピッチ検出を実行
      final result = await service.extractPitchFromAudio(
        sourcePath: audioFile.path,
        isAsset: false,
      );
      
      // 統計情報を取得
      final stats = service.getPitchStatistics(result.pitches);

      // 期待値との比較
      // C3の周波数は130.81Hz
      const expectedFrequency = 130.81;
      const allowedDeviation = 1.0; // 許容誤差 ±1Hz

      expect(stats['average'], closeTo(expectedFrequency, allowedDeviation),
          reason: 'C3音の平均周波数が期待値から大きく外れています');
      
      // 音程の安定性をチェック
      expect(stats['validRatio'], greaterThan(0.8),
          reason: '有効なピッチ検出の割合が低すぎます');
      
      expect((stats['max'] ?? 0.0) - (stats['min'] ?? 0.0), lessThan(5.0),
          reason: 'ピッチの変動が大きすぎます');
    });
  });
}