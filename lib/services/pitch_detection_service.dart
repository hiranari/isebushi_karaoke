import 'dart:typed_data';
import 'dart:math' as math;
import 'package:pitch_detector_dart/pitch_detector.dart';
import '../models/audio_analysis_result.dart';
import 'audio_processing_service.dart';

/// ピッチ検出を担当するサービスクラス
class PitchDetectionService {
  static const int DEFAULT_SAMPLE_RATE = 16000;
  static const int DEFAULT_BUFFER_SIZE = 1024;
  static const double MIN_PITCH_HZ = 80.0; // 最低ピッチ（E2付近）
  static const double MAX_PITCH_HZ = 2000.0; // 最高ピッチ（B6付近）

  late final PitchDetector _pitchDetector;
  bool _isInitialized = false;

  /// PitchDetectionServiceの初期化
  void initialize() {
    if (!_isInitialized) {
      _pitchDetector = PitchDetector(DEFAULT_SAMPLE_RATE, DEFAULT_BUFFER_SIZE);
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

      // ピッチ検出実行
      final pitches = await _analyzePitchFromPcm(normalizedPcm);

      return AudioAnalysisResult(
        pitches: pitches,
        sampleRate: DEFAULT_SAMPLE_RATE,
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

      // ピッチ検出実行
      final pitches = await _analyzePitchFromPcm(normalizedPcm);

      return AudioAnalysisResult(
        pitches: pitches,
        sampleRate: DEFAULT_SAMPLE_RATE,
        createdAt: DateTime.now(),
        sourceFile: assetPath,
      );
    } catch (e) {
      throw PitchDetectionException('WAVピッチ検出に失敗しました: $e');
    }
  }

  /// PCMデータからピッチを解析
  ///
  /// [pcmData] 解析対象のPCMデータ
  /// 戻り値: 検出されたピッチのリスト
  Future<List<double>> _analyzePitchFromPcm(Int16List pcmData) async {
    final pitches = <double>[];

    // PCMデータをオーバーラップありでチャンクに分割
    final chunks = AudioProcessingService.splitPcmIntoChunks(
      pcmData,
      DEFAULT_BUFFER_SIZE,
      overlap: DEFAULT_BUFFER_SIZE ~/ 2,
    );

    // 各チャンクでピッチ検出
    for (int i = 0; i < chunks.length; i++) {
      final chunk = chunks[i];

      // 音量チェック（無音区間の除外）
      if (_isSilent(chunk)) {
        pitches.add(0.0);
        continue;
      }

      try {
        final result = _pitchDetector.getPitch(chunk);

        if (result.pitched && result.pitch >= MIN_PITCH_HZ && result.pitch <= MAX_PITCH_HZ) {
          pitches.add(result.pitch);
        } else {
          pitches.add(0.0);
        }
      } catch (e) {
        // 個別チャンクのエラーは無音として扱う
        pitches.add(0.0);
      }
    }

    // ピッチデータの後処理
    return _postProcessPitches(pitches);
  }

  /// 音量が小さすぎる（無音）かどうかを判定
  bool _isSilent(List<double> samples) {
    const double silenceThreshold = 500.0; // 16bit PCMでの閾値

    double rms = 0.0;
    for (final sample in samples) {
      rms += sample * sample;
    }
    rms = math.sqrt(rms / samples.length);

    return rms < silenceThreshold;
  }

  /// ピッチデータの後処理
  /// ノイズ除去や平滑化を行う
  List<double> _postProcessPitches(List<double> pitches) {
    if (pitches.length < 3) return pitches;

    final processed = <double>[];

    for (int i = 0; i < pitches.length; i++) {
      if (pitches[i] == 0.0) {
        processed.add(0.0);
        continue;
      }

      // 前後のピッチとの差が大きすぎる場合はノイズとして除去
      if (i > 0 && i < pitches.length - 1) {
        final prev = pitches[i - 1];
        final next = pitches[i + 1];
        final current = pitches[i];

        // 前後のピッチが有効値の場合の妥当性チェック
        if (prev > 0 && next > 0) {
          final avgNeighbor = (prev + next) / 2;
          final deviation = (current - avgNeighbor).abs();

          // 平均から50Hz以上離れている場合はノイズとして除去
          if (deviation > 50.0) {
            processed.add(0.0);
            continue;
          }
        }
      }

      processed.add(pitches[i]);
    }

    return processed;
  }

  /// ピッチデータの平滑化処理
  ///
  /// [pitches] 平滑化対象のピッチデータ
  /// [windowSize] 平滑化ウィンドウサイズ
  /// 戻り値: 平滑化されたピッチデータ
  static List<double> smoothPitches(List<double> pitches, int windowSize) {
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
  static Map<String, double> getPitchStatistics(List<double> pitches) {
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
