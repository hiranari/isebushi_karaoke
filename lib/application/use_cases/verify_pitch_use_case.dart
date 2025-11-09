import 'dart:io';
import '../../domain/interfaces/i_pitch_verification_service.dart';
import '../../domain/models/pitch_verification_result.dart';

/// ピッチ検証ユースケース
/// 
/// ビジネスロジックを管理し、カラオケ画面とツールの共通処理を提供
/// クリーンアーキテクチャのApplication層として機能
class VerifyPitchUseCase {
  final IPitchVerificationService _verificationService;

  const VerifyPitchUseCase({
    required IPitchVerificationService verificationService,
  }) : _verificationService = verificationService;

  /// ピッチ検証を実行
  /// 
  /// [wavFilePath] 検証対象のWAVファイルパス
  /// [useCache] キャッシュを使用するかどうか
  /// [exportJson] JSON出力するかどうか
  /// [outputDir] JSON出力ディレクトリ（null時は./verification_results/）
  /// 
  /// Returns [PitchVerificationResult] 検証結果
  Future<PitchVerificationResult> execute({
    required String wavFilePath,
    required bool isAsset,
    bool useCache = true,
    bool exportJson = false,
    String? outputDir,
  }) async {
    // WAVファイル存在確認
    if (!await _validateWavFile(wavFilePath, isAsset)) {
      throw ArgumentError('WAVファイルが見つかりません: $wavFilePath');
    }

    // ピッチ検証実行
    final result = await _verificationService.verifyPitchData(
      wavFilePath,
      isAsset: isAsset,
      useCache: useCache,
    );

    // JSON出力
    if (exportJson) {
      await _handleJsonExport(result, wavFilePath, outputDir);
    }

    return result;
  }

  /// 基準ピッチとの比較を含む検証を実行
  /// 
  /// [wavFilePath] 検証対象のWAVファイルパス
  /// [referencePitches] 比較対象の基準ピッチデータ
  /// [useCache] キャッシュを使用するかどうか
  /// [exportJson] JSON出力するかどうか
  /// [outputDir] JSON出力ディレクトリ
  /// 
  /// Returns [PitchVerificationResult] 比較結果を含む検証結果
  Future<PitchVerificationResult> executeWithComparison({
    required String wavFilePath,
    required bool isAsset,
    required List<double> referencePitches,
    bool useCache = true,
    bool exportJson = false,
    String? outputDir,
  }) async {
    // 基本検証実行
    final result = await execute(
      wavFilePath: wavFilePath,
      isAsset: isAsset,
      useCache: useCache,
      exportJson: false, // 比較結果を含めるため、ここではJSON出力しない
    );

    // 比較統計の計算
    final comparison = _verificationService.compareWithReference(
      result.pitches,
      referencePitches,
    );

    // 比較結果を含む新しい結果を作成
    final resultWithComparison = PitchVerificationResult(
      wavFilePath: result.wavFilePath,
      analyzedAt: result.analyzedAt,
      pitches: result.pitches,
      statistics: result.statistics,
      fromCache: result.fromCache,
      comparison: comparison,
    );

    // JSON出力
    if (exportJson) {
      await _handleJsonExport(resultWithComparison, wavFilePath, outputDir);
    }

    return resultWithComparison;
  }

  /// 基準ピッチのみを抽出（軽量版）
  /// 
  /// [wavFilePath] 対象のWAVファイルパス
  /// [useCache] キャッシュを使用するかどうか
  /// 
  /// Returns [List<double>] 抽出されたピッチデータ
  Future<List<double>> extractPitchesOnly({
    required String wavFilePath,
    required bool isAsset,
    bool useCache = true,
  }) async {
    if (!await _validateWavFile(wavFilePath, isAsset)) {
      throw ArgumentError('WAVファイルが見つかりません: $wavFilePath');
    }

    return await _verificationService.extractReferencePitches(
      wavFilePath,
      isAsset: isAsset,
      useCache: useCache,
    );
  }

  /// WAVファイルの存在確認
  Future<bool> _validateWavFile(String filePath, bool isAsset) async {
    // アセットファイルの場合は存在確認をスキップ
    if (isAsset) {
      return true;
    }

    // 通常のファイルシステムファイルの場合
    final file = File(filePath);
    return await file.exists();
  }

  /// JSON出力処理
  Future<void> _handleJsonExport(
    PitchVerificationResult result,
    String wavFilePath,
    String? outputDir,
  ) async {
    final outputPath = _generateOutputPath(wavFilePath, outputDir);
    await _verificationService.exportToJson(result, outputPath);
  }

  /// JSON出力パスを生成
  String _generateOutputPath(String wavFilePath, String? outputDir) {
    // 出力ディレクトリのデフォルト設定
    final baseDir = outputDir ?? './verification_results';
    
    // ファイル名生成（拡張子を除いたベース名 + タイムスタンプ）
    final file = File(wavFilePath);
    final fileName = file.uri.pathSegments.last;
    final baseName = fileName.contains('.') ? fileName.split('.').first : fileName;
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final outputFileName = '${baseName}_verification_$timestamp.json';
    
    return '$baseDir/$outputFileName';
  }
}
