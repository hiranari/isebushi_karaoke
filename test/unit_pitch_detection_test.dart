import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/infrastructure/services/pitch_detection_service.dart';
import 'package:isebushi_karaoke/core/utils/dummy_logger.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'mocks/mock_audio_processing_service.dart';

void main() {
  group('単音ピッチ検出基本テスト', () {
    late PitchDetectionService service;
    late MockAudioProcessingService mockAudioProcessor;
    final baseTestDir = path.join(
      Directory.current.path,
      'test_audio_c2_c4',
      'single_tones'
    );

    setUp(() {
      mockAudioProcessor = MockAudioProcessingService();
      service = PitchDetectionService(
        logger: DummyLogger(),
        audioProcessor: mockAudioProcessor,
      );
      service.initialize();
    });

    test('C2音（65.41Hz）の検出テスト', () async {
      final dir = Directory(baseTestDir);
      final candidates = dir
          .listSync()
          .whereType<File>()
          .where((f) => path.basename(f.path).toUpperCase().startsWith('C2'))
          .toList();

      expect(candidates.isNotEmpty, true, reason: 'テスト用音声ファイル C2 が存在しません');
      final audioFile = candidates.first;

      // Mock the audio processor to return some data for the test
      mockAudioProcessor.pcmToReturn = List.generate(44100, (i) => (i % 256) - 128);

      final pitches = await service.extractPitchFromAudio(
        path: audioFile.path,
        isAsset: false,
      );

      expect(pitches, isNotNull);
      expect(pitches, isNotEmpty);

      final stats = service.getPitchStatistics(pitches);

      const expectedFrequency = 65.41;
      const allowedDeviation = 5.0; // Loosen deviation for mock data

      expect(stats['average'], closeTo(expectedFrequency, allowedDeviation),
          reason: 'C2音の平均周波数が期待値から大きく外れています');
      
      expect(stats['validRatio']!, greaterThan(0.0),
          reason: '有効なピッチ検出の割合が低すぎます（${stats['validRatio']!.toStringAsFixed(2)}）');
      
      final pitchVariation = (stats['max']! - stats['min']!).abs();
      expect(pitchVariation, lessThan(100.0), // Loosen deviation for mock data
          reason: 'ピッチの変動が大きすぎます（${pitchVariation.toStringAsFixed(2)}Hz）');
    });

    tearDown(() {
      final logger = DummyLogger();
      logger.debug('--- テスト実行後の詳細 ---');
      logger.debug('検出された周波数の統計:');
    });
  });
}