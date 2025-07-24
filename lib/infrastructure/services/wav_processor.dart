import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/utils/debug_logger.dart';

/// WAVファイル処理の単一責任クラス (SRP適用)
class WavProcessor {
  static const int wavHeaderSize = 44;

  /// アセットからWAVファイルを読み込み
  static Future<Int16List> loadFromAsset(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final wavData = bytes.buffer.asUint8List();
      return _processWavData(wavData, assetPath);
    } catch (e) {
      throw AudioProcessingException('アセット読み込みに失敗: $e');
    }
  }

  /// ファイルシステムからWAVファイルを読み込み
  static Future<Int16List> loadFromFile(String filePath) async {
    try {
      DebugLogger.info('WAVファイル読み込み開始: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw AudioProcessingException('ファイルが存在しません: $filePath');
      }

      final wavData = await file.readAsBytes();
      DebugLogger.info('WAVファイルサイズ: ${wavData.length} バイト');
      
      return _processWavData(wavData, filePath);
    } catch (e) {
      DebugLogger.error('WAVファイル読み込みエラー: $filePath', e);
      throw AudioProcessingException('WAVファイル処理に失敗: $e');
    }
  }

  /// WAVデータの処理 (共通処理でDRY適用)
  static Int16List _processWavData(Uint8List wavData, String source) {
    if (wavData.length < wavHeaderSize) {
      throw const AudioProcessingException('WAVファイルサイズが不正です');
    }

    if (_isValidWavHeader(wavData)) {
      DebugLogger.info('有効なWAVヘッダーを検出: $source');
      return _extractPcmFromWav(wavData);
    } else {
      DebugLogger.info('RAW PCMデータとして処理: $source');
      return RawPcmProcessor.process(wavData);
    }
  }

  /// WAVヘッダーの検証 (KISS適用)
  static bool _isValidWavHeader(Uint8List wavData) {
    // "RIFF" チェック
    if (wavData[0] != 0x52 || wavData[1] != 0x49 || 
        wavData[2] != 0x46 || wavData[3] != 0x46) {
      return false;
    }

    // "WAVE" チェック  
    if (wavData[8] != 0x57 || wavData[9] != 0x41 || 
        wavData[10] != 0x56 || wavData[11] != 0x45) {
      return false;
    }

    return true;
  }

  /// WAVファイルからPCMデータを抽出
  static Int16List _extractPcmFromWav(Uint8List wavData) {
    final pcmData = wavData.sublist(wavHeaderSize);
    return Int16List.view(
      pcmData.buffer, 
      pcmData.offsetInBytes, 
      pcmData.lengthInBytes ~/ 2
    );
  }
}

/// RAW PCMデータ処理の単一責任クラス (SRP適用)
class RawPcmProcessor {
  static const int noiseThreshold = 100;
  static const int silenceSkipSamples = 1000;

  /// RAW PCMデータの処理
  static Int16List process(Uint8List rawData) {
    try {
      DebugLogger.info('RAW PCMデータ処理開始: ${rawData.length} バイト');
      
      final adjustedData = _adjustDataLength(rawData);
      final samples = _convertToSamples(adjustedData);
      final trimmedSamples = _skipSilence(samples);
      
      DebugLogger.info('RAW PCM処理完了: ${trimmedSamples.length} サンプル');
      return trimmedSamples;
    } catch (e) {
      DebugLogger.error('RAW PCMデータ処理エラー', e);
      throw AudioProcessingException('RAW PCMデータ処理に失敗: $e');
    }
  }

  /// データ長の調整 (偶数バイトに修正)
  static Uint8List _adjustDataLength(Uint8List rawData) {
    if (rawData.length % 2 != 0) {
      DebugLogger.info('奇数バイトを修正: ${rawData.length} → ${rawData.length - 1}');
      return rawData.sublist(0, rawData.length - 1);
    }
    return rawData;
  }

  /// バイトデータをサンプルに変換
  static Int16List _convertToSamples(Uint8List data) {
    return Int16List.view(
      data.buffer, 
      data.offsetInBytes, 
      data.lengthInBytes ~/ 2
    );
  }

  /// 無音期間のスキップ
  static Int16List _skipSilence(Int16List samples) {
    final firstNonZeroIndex = _findFirstNonZeroSample(samples);
    
    if (firstNonZeroIndex > 0) {
      DebugLogger.info('無音期間スキップ: $firstNonZeroIndex サンプル');
      return Int16List.fromList(samples.sublist(firstNonZeroIndex));
    }
    
    return samples;
  }

  /// 最初の非ゼロサンプルを検出
  static int _findFirstNonZeroSample(Int16List samples) {
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].abs() > noiseThreshold) {
        return (i - silenceSkipSamples).clamp(0, samples.length);
      }
    }
    return 0;
  }
}

/// 音声処理例外クラス
class AudioProcessingException implements Exception {
  final String message;
  const AudioProcessingException(this.message);

  @override
  String toString() => 'AudioProcessingException: $message';
}
