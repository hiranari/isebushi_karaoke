import 'package:flutter_test/flutter_test.dart';
import 'package:isebushi_karaoke/infrastructure/services/pitch_detection_service.dart';
import 'package:isebushi_karaoke/core/utils/dummy_logger.dart';
import 'mocks/mock_audio_processing_service.dart';
import 'helpers/audio_helper.dart';

void main() {
  group('単音ピッチ検出基本テスト', () {
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

    test('C2音（65.41Hz）の検出テスト', () async {
      const expectedFrequency = 65.41; // C2の周波数
      const allowedDeviation = 2.0;    // 許容誤差 ±2Hz

      // Generate a sine wave for the expected frequency
      mockAudioProcessor.pcmToReturn = generateSineWavePcm(frequency: expectedFrequency);

      final pitches = await service.extractPitchFromAudio(
        path: 'dummy/path/C2.wav', // Path is now arbitrary as data is mocked
        isAsset: false,
      );

      expect(pitches, isNotNull);
      expect(pitches, isNotEmpty);

      final stats = service.getPitchStatistics(pitches);

      expect(stats['average'], closeTo(expectedFrequency, allowedDeviation),
          reason: 'C2音の平均周波数が期待値から大きく外れています');
      
      expect(stats['validRatio']!, greaterThan(0.8),
          reason: '有効なピッチ検出の割合が低すぎます（${stats['validRatio']!.toStringAsFixed(2)}）');
      
      final pitchVariation = (stats['max']! - stats['min']!).abs();
      expect(pitchVariation, lessThan(5.0),
          reason: 'ピッチの変動が大きすぎます（${pitchVariation.toStringAsFixed(2)}Hz）');
    });

    tearDown(() {
      final logger = DummyLogger();
      logger.debug('--- テスト実行後の詳細 ---');
      logger.debug('検出された周波数の統計:');
    });
  });
}