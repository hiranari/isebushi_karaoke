import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/services.dart' show rootBundle;

/// MP3ファイルの音声処理を担当するサービスクラス
class AudioProcessingService {
  static const int DEFAULT_SAMPLE_RATE = 16000;
  static const int DEFAULT_CHANNELS = 1;
  static const int WAV_HEADER_SIZE = 44;

  /// MP3ファイルをPCMデータに変換
  ///
  /// [assetPath] 変換対象のMP3ファイルパス
  /// 戻り値: PCMデータ（Int16List）
  static Future<Int16List> convertMp3ToPcm(String assetPath) async {
    try {
      // アセットファイルの存在確認
      final bytes = await rootBundle.load(assetPath);

      // TODO: Phase 1では簡易実装
      // 実際のMP3デコードはネイティブプラグインが必要
      // 現在はダミーデータを返す
      final dummyPcmData = _generateDummyPcmData(bytes.lengthInBytes);

      return dummyPcmData;
    } catch (e) {
      throw AudioProcessingException('MP3変換に失敗しました: $e');
    }
  }

  /// WAVファイルからPCMデータを抽出
  ///
  /// [assetPath] WAVファイルのパス
  /// 戻り値: PCMデータ（Int16List）
  static Future<Int16List> extractPcmFromWav(String assetPath) async {
    try {
      final bytes = await rootBundle.load(assetPath);
      final wavData = bytes.buffer.asUint8List();

      // WAVヘッダーの検証
      if (wavData.length < WAV_HEADER_SIZE) {
        throw AudioProcessingException('WAVファイルが不正です（サイズが小さすぎます）');
      }

      // WAVヘッダーの簡易チェック
      if (!_isValidWavHeader(wavData)) {
        throw AudioProcessingException('有効なWAVファイルではありません');
      }

      // WAVヘッダー（44バイト）をスキップしてPCM部分を取得
      final pcmData = wavData.sublist(WAV_HEADER_SIZE);
      return Int16List.view(pcmData.buffer, pcmData.offsetInBytes, pcmData.lengthInBytes ~/ 2);
    } catch (e) {
      throw AudioProcessingException('WAV処理に失敗しました: $e');
    }
  }

  /// WAVヘッダーの簡易検証
  static bool _isValidWavHeader(Uint8List wavData) {
    // "RIFF" チェック
    if (wavData[0] != 0x52 || wavData[1] != 0x49 || wavData[2] != 0x46 || wavData[3] != 0x46) {
      return false;
    }

    // "WAVE" チェック
    if (wavData[8] != 0x57 || wavData[9] != 0x41 || wavData[10] != 0x56 || wavData[11] != 0x45) {
      return false;
    }

    return true;
  }

  /// PCMデータを指定サイズのチャンクに分割
  ///
  /// [pcmData] 分割対象のPCMデータ
  /// [chunkSize] チャンクサイズ
  /// [overlap] オーバーラップサイズ（デフォルト0）
  /// 戻り値: 分割されたPCMデータのリスト
  static List<List<double>> splitPcmIntoChunks(
    Int16List pcmData,
    int chunkSize, {
    int overlap = 0,
  }) {
    final chunks = <List<double>>[];
    final step = chunkSize - overlap;

    for (int i = 0; i < pcmData.length; i += step) {
      final end = math.min(i + chunkSize, pcmData.length);

      if (end - i < chunkSize ~/ 2) break; // 小さすぎるチャンクは除外

      final chunk = pcmData.sublist(i, end).map((sample) => sample.toDouble()).toList();

      // チャンクサイズが足りない場合はゼロパディング
      while (chunk.length < chunkSize) {
        chunk.add(0.0);
      }

      chunks.add(chunk);
    }

    return chunks;
  }

  /// ダミーPCMデータ生成（開発用）
  /// MP3の実装が完了するまでの暫定処理
  static Int16List _generateDummyPcmData(int originalSize) {
    // 元ファイルサイズに基づいてダミーデータサイズを決定
    // 実際のMP3圧縮比を考慮して約10倍のPCMデータを生成
    final dummySize = (originalSize * 10 / 2).round(); // 16bit = 2byte
    final dummy = Int16List(dummySize);

    // 複数の周波数を混合した複雑な波形を生成
    final frequencies = [220.0, 440.0, 660.0]; // A3, A4, E5

    for (int i = 0; i < dummySize; i++) {
      double sample = 0.0;

      for (final freq in frequencies) {
        // 各周波数の振幅を時間で変調
        final amplitude = 0.3 * math.sin(2 * math.pi * 0.1 * i / DEFAULT_SAMPLE_RATE);
        sample += amplitude * math.sin(2 * math.pi * freq * i / DEFAULT_SAMPLE_RATE);
      }

      // 32767は16bit符号付き整数の最大値
      dummy[i] = (sample * 16383).round().clamp(-32767, 32767);
    }

    return dummy;
  }

  /// PCMデータの音量を正規化
  static Int16List normalizePcmData(Int16List pcmData) {
    if (pcmData.isEmpty) return pcmData;

    // 最大絶対値を取得
    int maxValue = 0;
    for (final sample in pcmData) {
      maxValue = math.max(maxValue, sample.abs());
    }

    if (maxValue == 0) return pcmData;

    // 正規化係数を計算
    final normalizationFactor = 32767.0 / maxValue;

    // 正規化されたデータを生成
    final normalized = Int16List(pcmData.length);
    for (int i = 0; i < pcmData.length; i++) {
      normalized[i] = (pcmData[i] * normalizationFactor).round();
    }

    return normalized;
  }
}

/// 音声処理に関する例外クラス
class AudioProcessingException implements Exception {
  final String message;
  const AudioProcessingException(this.message);

  @override
  String toString() => 'AudioProcessingException: $message';
}
