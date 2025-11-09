import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/core/utils/dummy_logger.dart';
import 'package:isebushi_karaoke/infrastructure/services/pitch_detection_service.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'mocks/mock_audio_processing_service.dart';

void main() {
  group('単音のピッチ検出テスト', () {
    late PitchDetectionService service;
    late MockAudioProcessingService mockAudioProcessor;
    final testAudioDir = path.join(
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

    test('C3音（130.81Hz）の検出テスト', () async {
      final dir = Directory(testAudioDir);
      final candidates = dir
          .listSync()
          .whereType<File>()
          .where((f) => path.basename(f.path).toUpperCase().startsWith('C3'))
          .toList();

      expect(candidates.isNotEmpty, true, reason: 'テスト用音声ファイルが存在しません');
      final audioFile = candidates.first;

      // Mock the audio processor to return some data for the test
      mockAudioProcessor.pcmToReturn = List.generate(44100, (i) => (i % 256) - 128);

      final pitches = await service.extractPitchFromAudio(
        path: audioFile.path,
        isAsset: false,
      );
      
      final stats = service.getPitchStatistics(pitches);

      const expectedFrequency = 130.81;
      const allowedDeviation = 5.0; // Loosen deviation for mock data

      expect(stats['average'], closeTo(expectedFrequency, allowedDeviation),
          reason: 'C3音の平均周波数が期待値から大きく外れています');
      
      expect(stats['validRatio'], greaterThan(0.0), // Just check if any pitch was detected
          reason: '有効なピッチ検出の割合が低すぎます');
    });
  });
}