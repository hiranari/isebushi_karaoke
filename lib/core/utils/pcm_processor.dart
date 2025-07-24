import 'dart:typed_data';
import 'dart:math' as math;
import '../../core/utils/debug_logger.dart';

/// PCMデータ処理ユーティリティ (DRY原則適用)
class PcmProcessor {
  /// PCMデータを指定サイズのチャンクに分割
  ///
  /// [pcmData] 分割対象のPCMデータ
  /// [chunkSize] チャンクサイズ
  /// [overlap] オーバーラップサイズ（デフォルト0）
  /// 戻り値: 分割されたPCMデータのリスト
  static List<List<double>> splitIntoChunks(
    Int16List pcmData,
    int chunkSize, {
    int overlap = 0,
  }) {
    if (pcmData.isEmpty || chunkSize <= 0) {
      DebugLogger.warning('無効なチャンク分割パラメータ');
      return [];
    }

    final chunks = <List<double>>[];
    final step = chunkSize - overlap;
    final minChunkSize = chunkSize ~/ 2;

    for (int i = 0; i < pcmData.length; i += step) {
      final end = math.min(i + chunkSize, pcmData.length);

      // 小さすぎるチャンクは除外 (KISS原則)
      if (end - i < minChunkSize) break;

      final chunk = _createChunk(pcmData, i, end, chunkSize);
      chunks.add(chunk);
    }

    DebugLogger.info('PCMチャンク分割完了: ${chunks.length}個');
    return chunks;
  }

  /// PCMデータの音量を正規化
  static Int16List normalize(Int16List pcmData) {
    if (pcmData.isEmpty) {
      DebugLogger.warning('空のPCMデータのため正規化をスキップ');
      return pcmData;
    }

    DebugLogger.info('PCM正規化開始: ${pcmData.length} サンプル');

    final maxValue = _findMaxAbsoluteValue(pcmData);
    
    if (maxValue == 0) {
      DebugLogger.warning('無音データのため正規化をスキップ');
      return pcmData;
    }

    final normalizationFactor = 32767.0 / maxValue;
    final normalized = _applyNormalization(pcmData, normalizationFactor);

    DebugLogger.success('PCM正規化完了 (係数: ${normalizationFactor.toStringAsFixed(3)})');
    return normalized;
  }

  /// チャンクを作成 (ゼロパディング含む)
  static List<double> _createChunk(Int16List pcmData, int start, int end, int chunkSize) {
    final chunk = pcmData
        .sublist(start, end)
        .map((sample) => sample.toDouble())
        .toList();

    // ゼロパディング
    while (chunk.length < chunkSize) {
      chunk.add(0.0);
    }

    return chunk;
  }

  /// 最大絶対値を検索
  static int _findMaxAbsoluteValue(Int16List pcmData) {
    int maxValue = 0;
    for (final sample in pcmData) {
      maxValue = math.max(maxValue, sample.abs());
    }
    return maxValue;
  }

  /// 正規化を適用
  static Int16List _applyNormalization(Int16List pcmData, double factor) {
    final normalized = Int16List(pcmData.length);
    for (int i = 0; i < pcmData.length; i++) {
      normalized[i] = (pcmData[i] * factor).round();
    }
    return normalized;
  }
}
