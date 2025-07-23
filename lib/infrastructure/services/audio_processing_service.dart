import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// MP3ファイルの音声処理を担当するサービスクラス
class AudioProcessingService {
  static const int defaultSampleRate = 44100;  // PitchDetectionServiceと統一
  static const int defaultChannels = 1;
  static const int wavHeaderSize = 44;

  /// 【廃止】MP3ファイルをPCMデータに変換
  ///
  /// MP3デコードは技術的に複雑なため、WAVファイルを使用してください
  /// [assetPath] 変換対象のMP3ファイルパス
  /// 戻り値: エラーを投げる
  @Deprecated('MP3サポートを廃止しました。WAVファイルを使用してください')
  static Future<Int16List> convertMp3ToPcm(String assetPath) async {
    throw AudioProcessingException(
      'MP3サポートは廃止されました。WAVファイル（$assetPath.wavなど）を使用してください。'
    );
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
      if (wavData.length < wavHeaderSize) {
        throw const AudioProcessingException('WAVファイルが不正です（サイズが小さすぎます）');
      }

      // WAVヘッダーの簡易チェック
      if (!_isValidWavHeader(wavData)) {
        throw const AudioProcessingException('有効なWAVファイルではありません');
      }

      // WAVヘッダー（44バイト）をスキップしてPCM部分を取得
      final pcmData = wavData.sublist(wavHeaderSize);
      return Int16List.view(pcmData.buffer, pcmData.offsetInBytes, pcmData.lengthInBytes ~/ 2);
    } catch (e) {
      throw AudioProcessingException('WAV処理に失敗しました: $e');
    }
  }

  /// ファイルシステムからWAVファイルを読み込んでPCMデータを抽出
  /// 
  /// [filePath] WAVファイルのファイルシステムパス
  /// 戻り値: PCMデータ（Int16List）
  static Future<Int16List> extractPcmFromWavFile(String filePath) async {
    try {
      debugPrint('=== WAVファイル処理デバッグ ===');
      debugPrint('WAVファイル: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw AudioProcessingException('ファイルが存在しません: $filePath');
      }

      final wavData = await file.readAsBytes();
      debugPrint('WAVファイルサイズ: ${wavData.length} バイト');
      
      // デバッグ用：ファイルの詳細情報を記録
      // ファイルサイズ: ${wavData.length} バイト
      // 実際のプロダクションではログライブラリの使用を推奨

      // WAVヘッダーの検証
      if (wavData.length < wavHeaderSize) {
        throw const AudioProcessingException('WAVファイルが不正です（サイズが小さすぎます）');
      }

      // WAVヘッダーの簡易チェック
      if (!_isValidWavHeader(wavData)) {
        debugPrint('WAVヘッダーが無効 - RAW PCMデータとして処理を試行');
        // Record パッケージがRAW PCMデータを出力した場合のフォールバック
        // RAW PCMデータとして処理を試行
        return _processRawPcmData(wavData);
      }

      debugPrint('有効なWAVヘッダーを検出');
      // WAVヘッダー（44バイト）をスキップしてPCM部分を取得
      final pcmData = wavData.sublist(wavHeaderSize);
      final result = Int16List.view(pcmData.buffer, pcmData.offsetInBytes, pcmData.lengthInBytes ~/ 2);
      
      debugPrint('PCMデータサイズ: ${result.length} サンプル');
      debugPrint('=== WAVファイル処理デバッグ終了 ===');
      
      return result;
    } catch (e) {
      debugPrint('WAVファイル処理エラー: $e');
      throw AudioProcessingException('WAVファイル処理に失敗しました: $e');
    }
  }  /// WAVヘッダーの簡易検証
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

  /// RAW PCMデータを処理（Record パッケージのフォールバック）
  /// 
  /// [rawData] RAW PCMデータ
  /// 戻り値: 処理されたPCMデータ
  static Int16List _processRawPcmData(Uint8List rawData) {
    try {
      debugPrint('=== RAW PCMデータ処理デバッグ ===');
      debugPrint('RAWデータサイズ: ${rawData.length} バイト');
      
      // RAW PCMデータの場合、直接16bitサンプルとして解釈
      if (rawData.length % 2 != 0) {
        // 奇数バイトの場合、最後の1バイトを削除
        rawData = rawData.sublist(0, rawData.length - 1);
        debugPrint('奇数バイトを修正: ${rawData.length} バイト');
      }
      
      // RAW PCMデータとして処理: ${rawData.length} バイト → ${rawData.length ~/ 2} サンプル
      final result = Int16List.view(rawData.buffer, rawData.offsetInBytes, rawData.lengthInBytes ~/ 2);
      debugPrint('RAW PCMサンプル数: ${result.length}');
      
      // 無音期間をスキップして実際の音声データを探す
      int firstNonZeroIndex = _findFirstNonZeroSample(result);
      if (firstNonZeroIndex > 0) {
        debugPrint('無音期間を検出: 最初の${firstNonZeroIndex}サンプルをスキップ');
        final trimmed = result.sublist(firstNonZeroIndex);
        debugPrint('スキップ後のサンプル数: ${trimmed.length}');
        
        // 最初の10サンプルを表示（スキップ後）
        debugPrint('RAW PCMサンプル（スキップ後の最初の10個）:');
        final sampleData = trimmed.take(10).toList();
        for (int i = 0; i < sampleData.length; i++) {
          debugPrint('  [$i]: ${sampleData[i]}');
        }
        
        debugPrint('=== RAW PCMデータ処理デバッグ終了 ===');
        return Int16List.fromList(trimmed);
      }
      
      // 最初の10サンプルを表示
      debugPrint('RAW PCMサンプル（最初の10個）:');
      final sampleData = result.take(10).toList();
      for (int i = 0; i < sampleData.length; i++) {
        debugPrint('  [$i]: ${sampleData[i]}');
      }
      
      debugPrint('=== RAW PCMデータ処理デバッグ終了 ===');
      return result;
    } catch (e) {
      debugPrint('RAW PCMデータ処理エラー: $e');
      // シミュレーションデータは使用しません - 実際のエラーを報告
      throw AudioProcessingException('WAVファイルの処理に失敗しました: $e');
    }
  }

  /// 最初の非ゼロサンプルのインデックスを見つける
  static int _findFirstNonZeroSample(Int16List samples) {
    const threshold = 100; // 小さなノイズを無視するための閾値
    
    for (int i = 0; i < samples.length; i++) {
      if (samples[i].abs() > threshold) {
        // 音声開始の少し前から開始（バッファとして）
        return math.max(0, i - 1000); // 約22ms前から（44100Hz時）
      }
    }
    
    return 0; // 非ゼロサンプルが見つからない場合
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

  /// PCMデータの音量を正規化
  static Int16List normalizePcmData(Int16List pcmData) {
    if (pcmData.isEmpty) return pcmData;

    debugPrint('=== PCM正規化デバッグ ===');
    debugPrint('正規化前データサイズ: ${pcmData.length} サンプル');

    // 最大絶対値を取得
    int maxValue = 0;
    for (final sample in pcmData) {
      maxValue = math.max(maxValue, sample.abs());
    }

    debugPrint('最大絶対値: $maxValue');

    if (maxValue == 0) {
      debugPrint('無音データのため正規化をスキップ');
      return pcmData;
    }

    // 正規化係数を計算
    final normalizationFactor = 32767.0 / maxValue;
    debugPrint('正規化係数: ${normalizationFactor.toStringAsFixed(3)}');

    // 正規化されたデータを生成
    final normalized = Int16List(pcmData.length);
    for (int i = 0; i < pcmData.length; i++) {
      normalized[i] = (pcmData[i] * normalizationFactor).round();
    }

    // 正規化後の統計情報
    int newMaxValue = 0;
    for (final sample in normalized) {
      newMaxValue = math.max(newMaxValue, sample.abs());
    }
    debugPrint('正規化後最大絶対値: $newMaxValue');
    debugPrint('=== PCM正規化デバッグ終了 ===');

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
