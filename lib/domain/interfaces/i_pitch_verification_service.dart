import '../../domain/models/pitch_verification_result.dart';

/// ピッチ検証サービスのインターフェース
abstract class IPitchVerificationService {
  /// ピッチデータを検証し、統計情報を生成
  Future<PitchVerificationResult> verifyPitchData(
    String path, {
    required bool isAsset,
    bool useCache = true,
  });

  /// 基準ピッチデータを抽出
  Future<List<double>> extractReferencePitches(
    String path, {
    required bool isAsset,
    bool useCache = true,
  });

  /// 結果をJSON形式でエクスポート
  Future<void> exportToJson(PitchVerificationResult result, String outputPath);

  /// 基準ピッチとの比較統計を計算
  ComparisonStats compareWithReference(
      List<double> pitches, List<double> referencePitches);
}
