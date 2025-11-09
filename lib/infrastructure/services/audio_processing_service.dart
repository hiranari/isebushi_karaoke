import 'dart:typed_data';
import '../../domain/models/audio_data.dart';
import '../../domain/interfaces/i_audio_processing_service.dart';
import 'wav_processor.dart';
import '../../core/utils/pcm_processor.dart';

/// 音声処理・音響分析統合サービス
///
/// カラオケアプリケーションの音声処理パイプラインを担当する
/// インフラストラクチャ層の中核サービスです。
/// リアルタイム音声入力から高品質な音響特徴量を抽出し、
/// 歌唱評価システムで使用可能な形式に変換します。
class AudioProcessingService implements IAudioProcessingService {
  @override
  Future<List<int>> extractPcm({required String path, required bool isAsset}) async {
    final Int16List samples;
    if (isAsset) {
      samples = await WavProcessor.loadFromAsset(path);
    } else {
      samples = await WavProcessor.loadFromFile(path);
    }
    return samples.toList();
  }

  @override
  bool isWavFile(String filePath) {
    return filePath.toLowerCase().endsWith('.wav');
  }

  @override
  Future<bool> validateAudioFile(String filePath) async {
    if (!isWavFile(filePath)) {
      return false;
    }
    try {
      // ファイルヘッダだけでも読めればOKとする
      await WavProcessor.loadFromFile(filePath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// WAVファイルをアセットから読み込み、AudioDataに変換
  Future<AudioData> loadWavFromAsset(String assetPath) async {
    final samples = await WavProcessor.loadFromAsset(assetPath);
    return AudioData.simple(samples: samples.toList());
  }

  /// WAVファイルをファイルパスから読み込み、AudioDataに変換
  Future<AudioData> loadWavFromFile(String filePath) async {
    final samples = await WavProcessor.loadFromFile(filePath);
    return AudioData.simple(samples: samples.toList());
  }

  /// PCMデータをチャンクに分割
  List<List<double>> splitIntoChunks(Int16List samples, int chunkSize) {
    return PcmProcessor.splitIntoChunks(samples, chunkSize);
  }

  /// PCMデータを正規化
  Int16List normalize(Int16List samples) {
    return PcmProcessor.normalize(samples);
  }

  /// Int16ListからList<int>への変換ユーティリティ
  List<int> int16ListToIntList(Int16List samples) {
    return samples.toList();
  }

  /// List<int>からInt16Listへの変換ユーティリティ
  Int16List intListToInt16List(List<int> samples) {
    return Int16List.fromList(samples);
  }
}
