import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/core/utils/dummy_logger.dart';
import 'package:isebushi_karaoke/infrastructure/services/pitch_detection_service.dart';
import 'mocks/mock_audio_processing_service.dart';
import 'helpers/audio_helper.dart';

void main() {
  group('単音のピッチ検出テスト', () {
    late PitchDetectionService service;
    late MockAudioProcessingService mockAudioProcessor;

    setUp(() {
      mockAudioProcessor = MockAudioProcessingService();
      service = PitchDetectionService(
        logger: DummyLogger(),
        audioProcessor: mockAudioProcessor,
      );
      service.initialize();
    });

    test('C3音（130.81Hz）の検出テスト', () async {
      const expectedFrequency = 130.81;
      const allowedDeviation = 2.0; // 許容誤差 ±2Hz

      // Generate a sine wave for the expected frequency
      mockAudioProcessor.pcmToReturn = generateSineWavePcm(frequency: expectedFrequency);

      final pitches = await service.extractPitchFromAudio(
        path: 'dummy/path/C3.wav', // Path is now arbitrary as data is mocked
        isAsset: false,
      );
      
      final stats = service.getPitchStatistics(pitches);

      expect(stats['average'], closeTo(expectedFrequency, allowedDeviation),
          reason: 'C3音の平均周波数が期待値から大きく外れています');
      
      expect(stats['validRatio'], greaterThan(0.8),
          reason: '有効なピッチ検出の割合が低すぎます');
    });
  });
}