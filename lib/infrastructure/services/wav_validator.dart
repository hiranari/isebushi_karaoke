import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/// WAVファイルの構造検証結果
class WavValidationResult {
  final bool isValid;
  final List<WavIssue> issues;
  final WavFileInfo fileInfo;
  
  const WavValidationResult({
    required this.isValid,
    required this.issues,
    required this.fileInfo,
  });
  
  bool get hasBlockAlignIssue => issues.any((issue) => issue.type == WavIssueType.blockAlign);
  bool get hasByteRateIssue => issues.any((issue) => issue.type == WavIssueType.byteRate);
  bool get hasLongSilenceIssue => issues.any((issue) => issue.type == WavIssueType.longSilence);
  bool get hasCorruptionIssue => issues.any((issue) => issue.type == WavIssueType.corruption);
  bool get hasFileNotFoundIssue => issues.any((issue) => issue.type == WavIssueType.fileNotFound);
}

/// WAVファイルの問題種別
enum WavIssueType {
  blockAlign,
  byteRate,
  longSilence,
  corruption,
  unsupportedFormat,
  fileNotFound,
}

/// WAVファイルの問題詳細
class WavIssue {
  final WavIssueType type;
  final String message;
  final String solution;
  final int? actualValue;
  final int? expectedValue;
  
  const WavIssue({
    required this.type,
    required this.message,
    required this.solution,
    this.actualValue,
    this.expectedValue,
  });
}

/// WAVファイル基本情報
class WavFileInfo {
  final int channels;
  final int sampleRate;
  final int bitsPerSample;
  final int blockAlign;
  final int byteRate;
  final int dataSize;
  final double durationSeconds;
  final int silenceDurationMs;
  
  const WavFileInfo({
    required this.channels,
    required this.sampleRate,
    required this.bitsPerSample,
    required this.blockAlign,
    required this.byteRate,
    required this.dataSize,
    required this.durationSeconds,
    required this.silenceDurationMs,
  });
}

/// WAVファイル検証サービス
class WavValidator {
  /// WAVファイルを検証する
  static Future<WavValidationResult> validateWavFile(String filePath) async {
    try {
      List<int> bytes;
      
      // Flutterアプリ内のassetファイルとして読み込み
      try {
        final byteData = await rootBundle.load(filePath);
        bytes = byteData.buffer.asUint8List();
      } catch (e) {
        // assetファイルとしての読み込みに失敗した場合、通常ファイルとして試行
        final file = File(filePath);
        if (!await file.exists()) {
          // MP3ファイルの存在を確認
          final mp3Path = filePath.replaceAll('.wav', '.mp3');
          final mp3File = File(mp3Path);
          final hasMP3 = await mp3File.exists();
          
          return WavValidationResult(
            isValid: false,
            issues: [
              WavIssue(
                type: WavIssueType.fileNotFound,
                message: hasMP3 
                    ? 'WAVファイルが見つかりません（MP3ファイルは存在します）'
                    : 'ファイルが見つかりません: $filePath',
                solution: hasMP3 
                    ? 'MP3ファイルをWAV形式に変換してください'
                    : 'ファイルパスを確認するか、WAV形式で録音してください',
              ),
            ],
            fileInfo: _createEmptyFileInfo(),
          );
        }
        bytes = await file.readAsBytes();
      }
      
      return _validateWavData(bytes);
    } catch (e) {
      return WavValidationResult(
        isValid: false,
        issues: [
          WavIssue(
            type: WavIssueType.corruption,
            message: 'ファイル読み込みエラー: $e',
            solution: 'ファイルが破損している可能性があります',
          ),
        ],
        fileInfo: _createEmptyFileInfo(),
      );
    }
  }
  
  /// WAVデータを検証する
  static WavValidationResult _validateWavData(List<int> bytes) {
    if (bytes.length < 44) {
      return WavValidationResult(
        isValid: false,
        issues: [
          const WavIssue(
            type: WavIssueType.corruption,
            message: 'WAVヘッダーが不完全です',
            solution: 'ファイルを再作成してください',
          ),
        ],
        fileInfo: _createEmptyFileInfo(),
      );
    }
    
    final view = ByteData.sublistView(Uint8List.fromList(bytes));
    final issues = <WavIssue>[];
    
    // WAVシグネチャ確認
    final riffSignature = String.fromCharCodes(bytes.sublist(0, 4));
    final waveSignature = String.fromCharCodes(bytes.sublist(8, 12));
    
    if (riffSignature != 'RIFF' || waveSignature != 'WAVE') {
      issues.add(const WavIssue(
        type: WavIssueType.corruption,
        message: 'WAVファイル形式ではありません',
        solution: 'WAV形式で保存し直してください',
      ));
    }
    
    // ヘッダー情報取得
    final channels = view.getUint16(22, Endian.little);
    final sampleRate = view.getUint32(24, Endian.little);
    final byteRate = view.getUint32(28, Endian.little);
    final blockAlign = view.getUint16(32, Endian.little);
    final bitsPerSample = view.getUint16(34, Endian.little);
    final dataSize = view.getUint32(40, Endian.little);
    
    // サポートされていない形式をチェック
    if (channels < 1 || channels > 2) {
      issues.add(WavIssue(
        type: WavIssueType.unsupportedFormat,
        message: '${channels}チャンネルはサポートされていません',
        solution: 'モノラルまたはステレオで録音してください',
      ));
    }
    
    if (bitsPerSample != 16) {
      issues.add(WavIssue(
        type: WavIssueType.unsupportedFormat,
        message: '${bitsPerSample}bitはサポートされていません',
        solution: '16bitで録音してください',
      ));
    }
    
    // ブロックアライン検証
    final expectedBlockAlign = (bitsPerSample * channels) ~/ 8;
    if (blockAlign != expectedBlockAlign) {
      issues.add(WavIssue(
        type: WavIssueType.blockAlign,
        message: 'ブロックアライン値が正しくありません',
        solution: '外部ツールで修正するか、ファイルを再作成してください',
        actualValue: blockAlign,
        expectedValue: expectedBlockAlign,
      ));
    }
    
    // バイトレート検証
    final expectedByteRate = sampleRate * expectedBlockAlign;
    if (byteRate != expectedByteRate) {
      issues.add(WavIssue(
        type: WavIssueType.byteRate,
        message: 'バイトレート値が正しくありません',
        solution: '外部ツールで修正するか、ファイルを再作成してください',
        actualValue: byteRate,
        expectedValue: expectedByteRate,
      ));
    }
    
    // 初期無音期間検証
    final silenceDuration = _detectInitialSilence(bytes.sublist(44), expectedBlockAlign, expectedByteRate);
    if (silenceDuration > 1000) { // 1秒以上の無音
      issues.add(WavIssue(
        type: WavIssueType.longSilence,
        message: '初期無音期間が長すぎます (${(silenceDuration / 1000).toStringAsFixed(1)}秒)',
        solution: '音声編集ソフトで無音部分を削除してください',
      ));
    }
    
    final fileInfo = WavFileInfo(
      channels: channels,
      sampleRate: sampleRate,
      bitsPerSample: bitsPerSample,
      blockAlign: blockAlign,
      byteRate: byteRate,
      dataSize: dataSize,
      durationSeconds: dataSize / expectedByteRate,
      silenceDurationMs: silenceDuration,
    );
    
    return WavValidationResult(
      isValid: issues.isEmpty,
      issues: issues,
      fileInfo: fileInfo,
    );
  }
  
  /// 初期無音期間を検出（ミリ秒）
  static int _detectInitialSilence(List<int> pcmData, int blockAlign, int byteRate) {
    int consecutiveZeroBytes = 0;
    
    for (int i = 0; i < pcmData.length - blockAlign; i += blockAlign) {
      bool isSilent = true;
      
      for (int j = 0; j < blockAlign; j += 2) {
        if (i + j + 1 < pcmData.length) {
          final sample = (pcmData[i + j + 1] << 8) | pcmData[i + j];
          final signedSample = sample > 32767 ? sample - 65536 : sample;
          
          if (signedSample.abs() > 50) {
            isSilent = false;
            break;
          }
        }
      }
      
      if (isSilent) {
        consecutiveZeroBytes += blockAlign;
      } else {
        break;
      }
    }
    
    return ((consecutiveZeroBytes / byteRate) * 1000).round();
  }
  
  static WavFileInfo _createEmptyFileInfo() {
    return const WavFileInfo(
      channels: 0,
      sampleRate: 0,
      bitsPerSample: 0,
      blockAlign: 0,
      byteRate: 0,
      dataSize: 0,
      durationSeconds: 0,
      silenceDurationMs: 0,
    );
  }
}
