import '../models/pitch_verification_result.dart';

/// ピッチ検証サービスインターフェース
/// 
/// 基準ピッチデータの検証、統計分析、JSON出力を担当
/// カラオケ画面とツールの共通ロジック抽象化
abstract class IPitchVerificationService {
  /// ピッチデータを検証し、詳細な分析結果を返す
  /// 
  /// [wavFilePath] 検証対象のWAVファイルパス
  /// [useCache] キャッシュを使用するかどうか
  /// 
  /// Returns [PitchVerificationResult] 検証結果（統計情報含む）
  Future<PitchVerificationResult> verifyPitchData(
    String wavFilePath, {
    bool useCache = true,
  });

  /// WAVファイルから基準ピッチを抽出
  /// 
  /// [wavFilePath] 対象のWAVファイルパス
  /// [useCache] キャッシュを使用するかどうか
  /// 
  /// Returns [List<double>] 抽出されたピッチデータ（Hz）
  Future<List<double>> extractReferencePitches(
    String wavFilePath, {
    bool useCache = true,
  });

  /// 検証結果をJSONファイルに出力
  /// 
  /// [result] 出力する検証結果
  /// [outputPath] 出力先ファイルパス
  Future<void> exportToJson(
    PitchVerificationResult result,
    String outputPath,
  );

  /// 2つのピッチデータを比較し、類似度統計を計算
  /// 
  /// [pitches] 比較対象のピッチデータ
  /// [referencePitches] 基準となるピッチデータ
  /// 
  /// Returns [ComparisonStats] 比較統計情報
  ComparisonStats compareWithReference(
    List<double> pitches,
    List<double> referencePitches,
  );
}
