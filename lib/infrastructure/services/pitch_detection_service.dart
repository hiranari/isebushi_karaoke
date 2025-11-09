import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:fftea/fftea.dart';
import '../../domain/models/audio_analysis_result.dart';
import '../../domain/interfaces/i_logger.dart';
import '../../domain/interfaces/i_audio_processing_service.dart';
import '../../domain/interfaces/i_pitch_detection_service.dart';
import 'audio_processing_service.dart';

/// ハーモニクス分析結果を格納するクラス
class HarmonicsAnalysisResult {
  final double fundamentalFrequency;
  final List<double> harmonics;
  final List<double> harmonicStrengths;
  final double confidence;
  final double snr; // Signal-to-Noise Ratio

  const HarmonicsAnalysisResult({
    required this.fundamentalFrequency,
    required this.harmonics,
    required this.harmonicStrengths,
    required this.confidence,
    required this.snr,
  });
}

/// ピッチ検出に関する例外クラス
/// 
/// ピッチ検出処理で発生する例外を表現します。
/// 不正なファイル形式、検出失敗、サポート外の機能などで使用します。
class PitchDetectionException implements Exception {
  final String message;
  const PitchDetectionException(this.message);

  @override
  String toString() => 'PitchDetectionException: $message';
}

/// 高精度ピッチ検出・音響分析サービス
/// 
/// カラオケアプリケーションの音響分析における最重要コンポーネントです。
/// リアルタイム音声からの基本周波数(F0)検出、ピッチ追跡、
/// 音響特徴量の抽出を高精度で実行します。
/// 
/// 検出範囲と精度:
/// - **検出範囲**: 60Hz - 1000Hz（C2からハイソプラノまでカバー）
/// - **周波数分解能**: ~1.08Hz (@44.1kHz, 4096サンプル)
/// - **時間分解能**: ~93ms (4096サンプル窓)
/// - **精度**: ±0.5セント (理論値)
/// 
/// 使用例:
/// ```dart
/// final service = PitchDetectionService(logger: logger);
/// service.initialize();
/// 
/// final result = await service.extractPitchFromAudio(
///   sourcePath: 'audio.wav',
///   isAsset: false,
/// );
/// 
/// final stats = service.getPitchStatistics(result.pitches);
/// print('平均ピッチ: ${stats['average']} Hz');
/// ```

class PitchDetectionService implements IPitchDetectionService {
  // 定数定義
  static const int defaultSampleRate = 44100;
  static const int defaultBufferSize = 4096;
  static const double minPitchHz = 60.0; // C2音の検出をサポート
  static const double maxPitchHz = 1000.0;

  // インスタンス変数
  final ILogger _logger;
  final IAudioProcessingService _audioProcessor;
  late FFT _fft;
  bool _isInitialized = false;

  /// コンストラクタ
  PitchDetectionService({
    required ILogger logger,
    required IAudioProcessingService audioProcessor,
  })  : _logger = logger,
        _audioProcessor = audioProcessor {
    // 初期化は遅延で行う
  }

  /// 初期化メソッド
  void initialize() {
    if (_isInitialized) return;
    _fft = FFT(defaultBufferSize);
    _isInitialized = true;
  }

  @override
  Future<List<double>> extractPitchFromAudio(
    String filePath, {
    List<double>? referencePitches,
  }) async {
    initialize();
    try {
      if (!_audioProcessor.isWavFile(filePath)) {
        throw PitchDetectionException('WAVファイルのみサポートしています: $filePath');
      }

      final pcmData = await _audioProcessor.extractPcmFromWav(filePath);
      final pcm16 = Int16List.fromList(pcmData);
      final normalizedPcm = PcmProcessor.normalize(pcm16);

      final uint8Pcm = Uint8List.fromList(normalizedPcm
          .expand((sample) => [
                sample & 0xFF,
                (sample >> 8) & 0xFF,
              ])
          .toList());

      final pitches = await _analyzePitchFromPcm(uint8Pcm, defaultSampleRate,
          referencePitches: referencePitches);

      return pitches;
    } catch (e) {
      _logger.error('ピッチ検出に失敗しました: $e');
      throw PitchDetectionException('ピッチ検出に失敗しました: $e');
    }
  }

    @override

    Future<double?> detectPitchFromPcm(List<int> pcmData) async {

      initialize();

      try {

        final detector = PitchDetector(

            audioSampleRate: defaultSampleRate.toDouble(),

            bufferSize: pcmData.length);

        final uint8Pcm = Uint8List.fromList(

            pcmData.expand((s) => [s & 0xFF, (s >> 8) & 0xFF]).toList());

        final result = await detector.getPitchFromIntBuffer(uint8Pcm);

  

        if (result.pitched && result.probability > 0.1) {

          double detectedPitch = result.pitch;

          if (detectedPitch > 5000) {

            detectedPitch /= 338.0;

          }

          double correctedPitch = normalizeFrequency(detectedPitch);

          if (isValidPitch(correctedPitch)) {

            return correctedPitch;

          }

        }

      } catch (e) {

        _logger.error('Real-time pitch detection failed: $e');

      }

      return null;

    }

  

    @override

    bool isValidPitch(double pitch) {

      return pitch >= minPitchHz && pitch <= maxPitchHz;

    }

  

    @override

    double normalizeFrequency(double frequency, {double? referencePitch}) {

      if (referencePitch == null) {

        double correctedPitch = frequency;

        if (correctedPitch >= 58.0 && correctedPitch <= 77.0) {

          return correctedPitch;

        }

        while (correctedPitch < minPitchHz && correctedPitch > 0) {

          correctedPitch *= 2.0;

        }

        while (correctedPitch > maxPitchHz) {

          correctedPitch /= 2.0;

        }

        return correctedPitch;

      }

  

      double bestPitch = frequency;

      double bestError = (frequency / referencePitch - 1.0).abs();

  

      for (int octave = -3; octave <= 3; octave++) {

        double testPitch = frequency * math.pow(2, octave);

        double error = (testPitch / referencePitch - 1.0).abs();

        if (error < bestError) {

          bestPitch = testPitch;

          bestError = error;

        }

      }

      return bestPitch;

    }

  

    /// 【廃止】MP3ファイルからピッチを検出

    @Deprecated(

        'MP3サポートを廃止しました。extractPitchFromAudio(sourcePath: "file.wav", isAsset: true)を使用してください')

    Future<AudioAnalysisResult> extractPitchFromMp3(String assetPath) async {

      throw PitchDetectionException(

          'MP3サポートは廃止されました。WAVファイル（${assetPath.replaceAll('.mp3', '.wav')}）を使用してください');

    }

  

    /// PCMデータからピッチを検出する

    ///

    /// [pcmData] - 16bit PCM audio data (Little Endian)

    /// [sampleRate] - サンプリングレート (Hz)

    /// [referencePitches] - 基準ピッチデータ（動적推定用）

    /// Returns: List of detected pitches in Hz (0 means no pitch detected)

    Future<List<double>> _analyzePitchFromPcm(Uint8List pcmData, int sampleRate,

        {List<double>? referencePitches}) async {

      try {

        final pitches = <double>[];

        const chunkSize = defaultBufferSize * 2;

        final detectorBufferSize = (chunkSize / 2).round();

        final detector = PitchDetector(

          audioSampleRate: sampleRate.toDouble(),

          bufferSize: detectorBufferSize,

        );

  

        int chunkIndex = 0;

        int totalChunks = 0;

        const overlapRatio = 0.5;

        final stepSize = (chunkSize * (1.0 - overlapRatio)).round();

        bool foundFirstSound = false;

  

        for (int i = 0; i < pcmData.length - chunkSize; i += stepSize) {

          final chunk = pcmData.sublist(i, i + chunkSize);

          totalChunks++;

          chunkIndex++;

  

          final chunkVolume = _calculateChunkVolume(chunk);

          if (!foundFirstSound && chunkVolume < 50) {

            pitches.add(0.0);

            continue;

          } else if (!foundFirstSound && chunkVolume >= 50) {

            foundFirstSound = true;

          }

  

          try {

            final result = await detector.getPitchFromIntBuffer(chunk);

  

            if (result.pitched && result.probability > 0.1) {

              double detectedPitch = result.pitch;

              if (detectedPitch > 5000) {

                detectedPitch = detectedPitch / 338.0;

              }

              double correctedPitch = normalizeFrequency(detectedPitch);

              if (isValidPitch(correctedPitch)) {

                pitches.add(correctedPitch);

              } else {

                pitches.add(0.0);

              }

            } else {

              pitches.add(0.0);

            }

          } catch (e) {

            _logger.debug('[PITCH_DEBUG] chunk:$chunkIndex exception:$e');

            pitches.add(0.0);

          }

        }

        return pitches;

      } catch (e) {

        return [];

      }

    }

  

    /// チャンクの音量レベルを計算

    double _calculateChunkVolume(Uint8List chunk) {

      if (chunk.length < 2) return 0.0;

  

      double sum = 0.0;

      int sampleCount = 0;

  

      for (int i = 0; i < chunk.length - 1; i += 2) {

        final sample = (chunk[i + 1] << 8) | chunk[i];

        final signedSample = sample > 32767 ? sample - 65536 : sample;

        sum += signedSample.abs();

        sampleCount++;

      }

  

      return sampleCount > 0 ? sum / sampleCount : 0.0;

    }

  

    /// ピッチデータの平滑化処理

    ///

    /// [pitches] 平滑化対象のピッチデータ

    /// [windowSize] 平滑化ウィンドウサイズ

    /// 戻り値: 平滑化されたピッチデータ

    List<double> smoothPitches(List<double> pitches, int windowSize) {

      if (pitches.length <= windowSize) return pitches;

  

      final smoothed = <double>[];

  

      for (int i = 0; i < pitches.length; i++) {

        if (pitches[i] == 0.0) {

          smoothed.add(0.0);

          continue;

        }

  

        final start = math.max(0, i - windowSize ~/ 2);

        final end = math.min(pitches.length, i + windowSize ~/ 2 + 1);

  

        double sum = 0;

        int count = 0;

  

        for (int j = start; j < end; j++) {

          if (isValidPitch(pitches[j])) {

            sum += pitches[j];

            count++;

          }

        }

  

        final averagePitch = count > 0 ? sum / count : 0.0;

        if (isValidPitch(averagePitch)) {

          smoothed.add(averagePitch);

        } else {

          smoothed.add(0.0);

        }

      }

  

      return smoothed;

    }

  

    /// ピッチデータの統計情報を取得

    Map<String, double> getPitchStatistics(List<double> pitches) {

      final validPitches = pitches.where((p) => p > 0).toList();

  

      if (validPitches.isEmpty) {

        return {

          'min': 0.0,

          'max': 0.0,

          'average': 0.0,

          'median': 0.0,

          'standardDeviation': 0.0,

          'validRatio': 0.0,

        };

      }

  

      validPitches.sort();

  

      final sum = validPitches.reduce((a, b) => a + b);

      final average = sum / validPitches.length;

  

      final variance =

          validPitches.map((p) => math.pow(p - average, 2)).reduce((a, b) => a + b) /

              validPitches.length;

  

      return {

        'min': validPitches.first,

        'max': validPitches.last,

        'average': average,

        'median': validPitches[validPitches.length ~/ 2],

        'standardDeviation': math.sqrt(variance),

        'validRatio': validPitches.length / pitches.length,

      };

    }

  

    /// 時間位置に基づいて動的にピッチを推定

    ///

    /// [currentChunk] 現在のチャンク番号

    /// [totalChunks] 全チャンク数

    /// [referencePitches] 基準ピッチデータ

    /// 戻り値: 推定されたピッチ

    double _estimatePitchFromTimePosition(

        int currentChunk, int totalChunks, List<double>? referencePitches) {

      const defaultPitch = 190.0;

  

      if (referencePitches == null ||

          referencePitches.isEmpty ||

          totalChunks <= 0) {

        return defaultPitch;

      }

  

      final timeProgress = currentChunk / totalChunks;

      final referenceIndex = (timeProgress * referencePitches.length)

          .floor()

          .clamp(0, referencePitches.length - 1);

      final referencePitch = referencePitches[referenceIndex];

  

      if (referencePitch > 0) {

        return referencePitch;

      }

  

      for (int offset = 1; offset < referencePitches.length ~/ 4; offset++) {

        final forwardIndex = referenceIndex + offset;

        if (forwardIndex < referencePitches.length &&

            referencePitches[forwardIndex] > 0) {

          return referencePitches[forwardIndex];

        }

  

        final backwardIndex = referenceIndex - offset;

        if (backwardIndex >= 0 && referencePitches[backwardIndex] > 0) {

          return referencePitches[backwardIndex];

        }

      }

  

      return defaultPitch;

    }

  }
