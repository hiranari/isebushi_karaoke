import 'dart:typed_data';
import '../../domain/models/audio_data.dart';
import 'wav_processor.dart';
import '../../core/utils/pcm_processor.dart';

/// 音声処理サービス
/// Single Responsibility Principle: 音声処理の統一インターフェースのみを提供
/// Open/Closed Principle: 新しい音声形式の追加に対してオープン、既存コードの変更に対してクローズ
/// Dependency Inversion Principle: 具体的な実装ではなく抽象化に依存
class AudioProcessingService {
  /// WAVファイルをアセットから読み込み、AudioDataに変換
  /// 
  /// Delegation Pattern: WavProcessorに処理を委譲し、結果をAudioDataに変換
  static Future<AudioData> loadWavFromAsset(String assetPath) async {
    final samples = await WavProcessor.loadFromAsset(assetPath);
    return AudioData.simple(samples: samples.toList());
  }

  /// WAVファイルをファイルパスから読み込み、AudioDataに変換
  /// 
  /// Delegation Pattern: WavProcessorに処理を委譲し、結果をAudioDataに変換
  static Future<AudioData> loadWavFromFile(String filePath) async {
    final samples = await WavProcessor.loadFromFile(filePath);
    return AudioData.simple(samples: samples.toList());
  }

  /// PCMデータをチャンクに分割
  /// 
  /// Delegation Pattern: PcmProcessorに処理を委譲
  static List<List<double>> splitIntoChunks(Int16List samples, int chunkSize) {
    return PcmProcessor.splitIntoChunks(samples, chunkSize);
  }

  /// PCMデータを正規化
  /// 
  /// Delegation Pattern: PcmProcessorに処理を委譲
  static Int16List normalize(Int16List samples) {
    return PcmProcessor.normalize(samples);
  }

  /// Int16ListからList\<int>への変換ユーティリティ
  static List<int> int16ListToIntList(Int16List samples) {
    return samples.toList();
  }

  /// List\<int>からInt16Listへの変換ユーティリティ
  static Int16List intListToInt16List(List<int> samples) {
    return Int16List.fromList(samples);
  }

  /// PCMデータを正規化（テスト用のメソッド名互換性）
  /// 
  /// Delegation Pattern: 内部のnormalizeメソッドに委譲
  static Int16List normalizePcmData(Int16List samples) {
    return normalize(samples);
  }

  /// WAVファイルからPCMデータを抽出（テスト用のメソッド名互換性）
  /// 
  /// Delegation Pattern: WavProcessorに処理を委譲
  static Future<Int16List> extractPcmFromWavFile(String filePath) async {
    return WavProcessor.loadFromFile(filePath);
  }

  /// サポートされている形式を取得
  static List<String> getSupportedFormats() {
    return ['wav', 'pcm'];
  }

  /// 音声データの有効性チェック
  static bool isValidAudioData(AudioData audioData) {
    return audioData.isValid;
  }
}
