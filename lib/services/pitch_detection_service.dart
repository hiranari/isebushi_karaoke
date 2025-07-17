import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pitch_detector_dart/pitch_detector.dart';
import '../models/audio_analysis_result.dart';
import 'audio_processing_service.dart';

/// ピッチ検出を担当するサービスクラス
class PitchDetectionService {
  static const int defaultSampleRate = 44100;
  static const int defaultBufferSize = 4096;
  static const double minPitchHz = 80.0;
  static const double maxPitchHz = 800.0;

  bool _isInitialized = false;

  /// PitchDetectionServiceの初期化
  void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  /// MP3ファイルからピッチを検出
  ///
  /// [assetPath] 解析対象のMP3ファイルパス
  /// 戻り値: ピッチ検出結果
  Future<AudioAnalysisResult> extractPitchFromMp3(String assetPath) async {
    initialize();

    try {
      // MP3をPCMに変換
      final pcmData = await AudioProcessingService.convertMp3ToPcm(assetPath);

      // PCMデータを正規化
      final normalizedPcm = AudioProcessingService.normalizePcmData(pcmData);

      // Int16ListをUint8Listに変換
      final uint8Pcm = Uint8List.fromList(normalizedPcm.expand((sample) => [
        sample & 0xFF,        // 下位バイト
        (sample >> 8) & 0xFF, // 上位バイト
      ]).toList());

      // ピッチ検出実行
      final pitches = await _analyzePitchFromPcm(uint8Pcm, defaultSampleRate);

      return AudioAnalysisResult(
        pitches: pitches,
        sampleRate: defaultSampleRate,
        createdAt: DateTime.now(),
        sourceFile: assetPath,
      );
    } catch (e) {
      throw PitchDetectionException('MP3ピッチ検出に失敗しました: $e');
    }
  }

  /// WAVファイルからピッチを検出
  ///
  /// [assetPath] 解析対象のWAVファイルパス
  /// 戻り値: ピッチ検出結果
  Future<AudioAnalysisResult> extractPitchFromWav(String assetPath) async {
    initialize();

    try {
      // WAVからPCMデータを抽出
      final pcmData = await AudioProcessingService.extractPcmFromWav(assetPath);

      // PCMデータを正規化
      final normalizedPcm = AudioProcessingService.normalizePcmData(pcmData);

      // Int16ListをUint8Listに変換
      final uint8Pcm = Uint8List.fromList(normalizedPcm.expand((sample) => [
        sample & 0xFF,        // 下位バイト
        (sample >> 8) & 0xFF, // 上位バイト
      ]).toList());

      // ピッチ検出実行
      final pitches = await _analyzePitchFromPcm(uint8Pcm, defaultSampleRate);

      return AudioAnalysisResult(
        pitches: pitches,
        sampleRate: defaultSampleRate,
        createdAt: DateTime.now(),
        sourceFile: assetPath,
      );
    } catch (e) {
      throw PitchDetectionException('WAVピッチ検出に失敗しました: $e');
    }
  }

  /// PCMデータからピッチを検出する
  /// 
  /// [pcmData] - 16bit PCM audio data (Little Endian)
  /// [sampleRate] - サンプリングレート (Hz)
  /// Returns: List of detected pitches in Hz (0 means no pitch detected)
  Future<List<double>> _analyzePitchFromPcm(Uint8List pcmData, int sampleRate) async {
    try {
      final detector = PitchDetector(
        audioSampleRate: sampleRate.toDouble(),
        bufferSize: 2048,
      );

      final pitches = <double>[];
      const chunkSize = 2048 * 2; // 16bit = 2 bytes per sample
      
      // PCMデータをチャンクに分割して解析
      for (int i = 0; i < pcmData.length - chunkSize; i += chunkSize) {
        final chunk = pcmData.sublist(i, i + chunkSize);
        
        try {
          // pitch_detector_dartの正しいAPIを使用してピッチを検出
          final result = await detector.getPitchFromIntBuffer(chunk);
          
          // 結果が有効な場合のみピッチを追加
          if (result.pitched && result.probability > 0.8) {
            pitches.add(result.pitch);
          } else {
            pitches.add(0.0); // ピッチが検出されなかった場合
          }
        } catch (e) {
          // エラーの場合は0を追加
          pitches.add(0.0);
        }
      }

      return pitches;
    } catch (e) {
      // エラーが発生した場合は空のリストを返す
      return [];
    }
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
        if (pitches[j] > 0) {
          // 無音部分を除外
          sum += pitches[j];
          count++;
        }
      }

      smoothed.add(count > 0 ? sum / count : 0.0);
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

    // 標準偏差の計算
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
}

/// ピッチ検出に関する例外クラス
class PitchDetectionException implements Exception {
  final String message;
  const PitchDetectionException(this.message);

  @override
  String toString() => 'PitchDetectionException: $message';
}
