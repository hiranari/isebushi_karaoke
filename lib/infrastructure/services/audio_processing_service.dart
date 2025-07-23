import 'dart:typed_data';
import '../../domain/models/audio_data.dart';
import 'wav_processor.dart';
import '../../core/utils/pcm_processor.dart';

/// 音声処理・音響分析統合サービス
/// 
/// カラオケアプリケーションの音声処理パイプラインを担当する
/// インフラストラクチャ層の中核サービスです。
/// リアルタイム音声入力から高品質な音響特徴量を抽出し、
/// 歌唱評価システムで使用可能な形式に変換します。
/// 
/// アーキテクチャ位置:
/// ```
/// Hardware層 (マイク、スピーカー)
///     ↓ (生音声データ)
/// Infrastructure層 ← AudioProcessingService
///     ↓ (処理済み音響データ)
/// Domain層 (音響分析モデル)
///     ↓ (評価結果)
/// Application層 (ビジネスロジック)
/// ```
/// 
/// 責任範囲:
/// - 音声ファイルの読み込みと前処理
/// - 音声データフォーマットの統一化
/// - PCMデータの正規化と品質向上
/// - AudioDataモデルへの変換
/// - 音声処理エラーの適切なハンドリング
/// 
/// 音声処理パイプライン:
/// ```
/// 音声ファイル/アセット
///     ↓
/// 1. ファイル読み込み
///    ├── アセットからの読み込み
///    ├── ローカルファイルからの読み込み
///    └── フォーマット検証
///     ↓
/// 2. 音声データ変換
///    ├── WAV形式のパース
///    ├── サンプリングレート確認
///    ├── チャンネル情報取得
///    └── 生PCMデータ抽出
///     ↓
/// 3. 前処理・正規化
///    ├── PCMデータ正規化
///    ├── ノイズ除去
///    ├── 振幅調整
///    └── 品質チェック
///     ↓
/// 4. ドメインモデル変換
///    ├── AudioDataオブジェクト生成
///    ├── メタデータ付与
///    └── 型安全性保証
/// ```
/// 
/// 設計原則の適用:
/// - **Single Responsibility**: 音声処理の統一インターフェースのみを提供
/// - **Open/Closed**: 新しい音声形式の追加に対してオープン、既存コードの変更に対してクローズ
/// - **Dependency Inversion**: 具体的な実装ではなく抽象化に依存
/// - **Delegation Pattern**: 専門処理をWavProcessor等に委譲
/// 
/// 使用例:
/// ```dart
/// // アセットからの音声読み込み
/// final audioData = await AudioProcessingService.loadWavFromAsset(
///   'assets/sounds/reference_song.wav'
/// );
/// 
/// // ローカルファイルからの読み込み
/// final recordedData = await AudioProcessingService.loadWavFromFile(
///   '/path/to/recorded_audio.wav'
/// );
/// 
/// // PCMデータの正規化
/// final normalizedPcm = AudioProcessingService.normalizePcmData(
///   audioData.samples
/// );
/// ```
/// 
/// エラーハンドリング:
/// - ファイル読み込みエラーの適切な処理
/// - 不正な音声フォーマットの検出
/// - メモリ不足エラーの回復
/// - プラットフォーム固有エラーの抽象化
/// 
/// パフォーマンス考慮:
/// - 静的メソッドによる軽量実装
/// - メモリ効率的なデータ変換
/// - 必要最小限の処理ステップ
/// - ガベージコレクション負荷の軽減
/// 
/// 依存関係:
/// - WavProcessor: WAV形式の専門処理
/// - PcmProcessor: PCMデータの正規化
/// - AudioData: ドメインモデル
/// 
/// 将来拡張:
/// - MP3、AAC等の追加フォーマット対応
/// - リアルタイムストリーミング処理
/// - 高品質リサンプリング
/// - ノイズリダクション機能
/// 
/// 参照: [UMLドキュメント](../../UML_DOCUMENTATION.md#audio-processing-service)
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
