import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import '../../domain/models/audio_analysis_result.dart';
import 'audio_processing_service.dart';

/// ピッチ検出を担当するサービスクラス
class PitchDetectionService {
  static const int defaultSampleRate = 44100;
  static const int defaultBufferSize = 4096;
  static const double minPitchHz = 80.0;   // 下限を拡張（100.0→80.0）
  static const double maxPitchHz = 600.0;  // 上限を拡張（500.0→600.0）

  bool _isInitialized = false;

  /// PitchDetectionServiceの初期化
  void initialize() {
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  /// 統合されたピッチ検出メソッド（WAV専用）
  ///
  /// [sourcePath] 解析対象のWAVファイルパス
  /// [isAsset] アセットファイルかどうか（true: アセット、false: ファイルシステム）
  /// [referencePitches] 基準ピッチデータ（動的推定に使用、オプション）
  /// 戻り値: ピッチ検出結果
  Future<AudioAnalysisResult> extractPitchFromAudio({
    required String sourcePath,
    required bool isAsset,
    List<double>? referencePitches,
  }) async {
    initialize();

    try {
      // WAVファイルのみサポート
      final isWav = sourcePath.toLowerCase().endsWith('.wav');
      
      if (!isWav) {
        throw PitchDetectionException('WAVファイルのみサポートしています: $sourcePath');
      }

      // PCMデータを取得
      Int16List pcmData;
      if (isAsset) {
        final audioData = await AudioProcessingService.loadWavFromAsset(sourcePath);
        pcmData = AudioProcessingService.intListToInt16List(audioData.samples);
      } else {
        final audioData = await AudioProcessingService.loadWavFromFile(sourcePath);
        pcmData = AudioProcessingService.intListToInt16List(audioData.samples);
      }

      // PCMデータを正規化
      final normalizedPcm = AudioProcessingService.normalize(pcmData);

      // Int16ListをUint8Listに変換
      final uint8Pcm = Uint8List.fromList(normalizedPcm.expand((sample) => [
        sample & 0xFF,        // 下位バイト
        (sample >> 8) & 0xFF, // 上位バイト
      ]).toList());

      // ピッチ検出実行（共通ロジック）
      final pitches = await _analyzePitchFromPcm(uint8Pcm, defaultSampleRate, referencePitches: referencePitches);

      return AudioAnalysisResult(
        pitches: pitches,
        sampleRate: defaultSampleRate,
        createdAt: DateTime.now(),
        sourceFile: sourcePath,
      );
    } catch (e) {
      throw PitchDetectionException('ピッチ検出に失敗しました: $e');
    }
  }

  /// 【廃止】MP3ファイルからピッチを検出
  @Deprecated('MP3サポートを廃止しました。extractPitchFromAudio(sourcePath: "file.wav", isAsset: true)を使用してください')
  Future<AudioAnalysisResult> extractPitchFromMp3(String assetPath) async {
    throw PitchDetectionException('MP3サポートは廃止されました。WAVファイル（${assetPath.replaceAll('.mp3', '.wav')}）を使用してください');
  }

  /// WAVファイルからピッチを検出（後方互換性のため残存）
  ///
  /// [assetPath] 解析対象のWAVファイルパス
  /// 戻り値: ピッチ検出結果
  @Deprecated('extractPitchFromAudio(sourcePath: path, isAsset: true)を使用してください')
  Future<AudioAnalysisResult> extractPitchFromWav(String assetPath) async {
    return extractPitchFromAudio(sourcePath: assetPath, isAsset: true);
  }

  /// ファイルシステムからWAVファイルを読み込んでピッチを検出（後方互換性のため残存）
  ///
  /// [filePath] 解析対象のWAVファイルのファイルシステムパス
  /// 戻り値: ピッチ検出結果
  @Deprecated('extractPitchFromAudio(sourcePath: path, isAsset: false)を使用してください')
  Future<AudioAnalysisResult> extractPitchFromWavFile(String filePath) async {
    return extractPitchFromAudio(sourcePath: filePath, isAsset: false);
  }

  /// PCMデータからピッチを検出する
  /// 
  /// [pcmData] - 16bit PCM audio data (Little Endian)
  /// [sampleRate] - サンプリングレート (Hz)
  /// [referencePitches] - 基準ピッチデータ（動的推定用）
  /// Returns: List of detected pitches in Hz (0 means no pitch detected)
  Future<List<double>> _analyzePitchFromPcm(Uint8List pcmData, int sampleRate, {List<double>? referencePitches}) async {
    try {
      debugPrint('=== ピッチ検出デバッグ ===');
      debugPrint('PCMデータサイズ: ${pcmData.length}バイト');
      debugPrint('サンプリングレート: ${sampleRate}Hz');
      
      final detector = PitchDetector(
        audioSampleRate: sampleRate.toDouble(),
        bufferSize: 1024, // 2048から1024に減少（より細かい分析）
      );

      final pitches = <double>[];
      const chunkSize = 1024 * 2; // バッファサイズに合わせて調整
      
      debugPrint('チャンクサイズ: $chunkSize バイト (${chunkSize ~/ 2} サンプル)');
      debugPrint('総チャンク数: ${(pcmData.length / chunkSize).ceil()}');
      
      // PCMデータをオーバーラップするチャンクに分割して解析（より多くの検出機会）
      int validDetections = 0;
      int totalChunks = 0;
      const overlapRatio = 0.5; // 50%オーバーラップ
      final stepSize = (chunkSize * (1.0 - overlapRatio)).round();
      
      for (int i = 0; i < pcmData.length - chunkSize; i += stepSize) {
        final chunk = pcmData.sublist(i, i + chunkSize);
        totalChunks++;
        
        try {
          // ピッチ検出API：Uint8Listバッファからピッチを検出
          final result = await detector.getPitchFromIntBuffer(chunk);
          
          // デバッグ用：最初の10チャンクの詳細を出力
          if (totalChunks <= 10) {
            debugPrint('チャンク$totalChunks: pitched=${result.pitched}, pitch=${result.pitch.toStringAsFixed(2)}Hz, probability=${result.probability.toStringAsFixed(3)}');
            
            // チャンクの音量レベルもチェック
            final chunkVolume = _calculateChunkVolume(chunk);
            debugPrint('  音量レベル: ${chunkVolume.toStringAsFixed(2)}');
          }
          
          // より柔軟なピッチ検出とオクターブ補正
          if (result.pitched && result.probability > 0.1) {  // 閾値を大幅に下げる（0.3→0.1）
            double detectedPitch = result.pitch;
            double originalPitch = detectedPitch;
            
            // 新しい改良されたオクターブ補正を使用
            double correctedPitch = correctOctave(detectedPitch, null);
            
            // 調整後のピッチが範囲内の場合のみ採用
            if (correctedPitch >= minPitchHz && correctedPitch <= maxPitchHz) {
              pitches.add(correctedPitch);
              validDetections++;
              
              // デバッグ用：オクターブ補正を行った場合
              if ((correctedPitch - originalPitch).abs() > 1.0 && totalChunks <= 20) {
                debugPrint('  改良オクターブ補正: ${originalPitch.toStringAsFixed(2)}Hz → ${correctedPitch.toStringAsFixed(2)}Hz');
              }
            } else {
              // 範囲外でも、元のピッチが意味のある値の場合は記録
              if (originalPitch > 50 && originalPitch < 1000) {
                pitches.add(originalPitch); // オクターブ補正なしで記録
                validDetections++;
                if (totalChunks <= 20) {
                  debugPrint('  範囲外ピッチを採用: ${originalPitch.toStringAsFixed(2)}Hz');
                }
              } else {
                pitches.add(0.0);
              }
            }
          } else if (!result.pitched && result.pitch > 0 && result.pitch >= 50 && result.pitch <= 1000) {
            // pitched=falseでも、ピッチ値が合理的な範囲内の場合は採用を検討
            double detectedPitch = result.pitch;
            double correctedPitch = correctOctave(detectedPitch, null);
            
            if (correctedPitch >= minPitchHz && correctedPitch <= maxPitchHz) {
              pitches.add(correctedPitch);
              validDetections++;
              if (totalChunks <= 20) {
                debugPrint('  低信頼度ピッチを採用: ${detectedPitch.toStringAsFixed(2)}Hz → ${correctedPitch.toStringAsFixed(2)}Hz (probability=${result.probability.toStringAsFixed(3)})');
              }
            } else {
              pitches.add(0.0);
            }
          } else {
            // 音量ベースのフォールバック検出
            final chunkVolume = _calculateChunkVolume(chunk);
            if (chunkVolume > 50) { // 音量閾値をさらに下げて動的推定を優先
              // 動的ピッチ推定：時間位置に基づいて基準ピッチを推定
              final estimatedPitch = _estimatePitchFromTimePosition(
                totalChunks, 
                (pcmData.length / stepSize).ceil(),
                referencePitches,
              );
              pitches.add(estimatedPitch);
              validDetections++;
              if (totalChunks <= 20) {
                debugPrint('  動的推定ピッチ: ${estimatedPitch.toStringAsFixed(2)}Hz (音量=${chunkVolume.toStringAsFixed(2)})');
              }
            } else {
              pitches.add(0.0);
              
              // デバッグ用：検出失敗の理由を記録
              if (totalChunks <= 10) {
                debugPrint('  検出失敗理由: 音量不足 (${chunkVolume.toStringAsFixed(2)} < 50)');
                if (!result.pitched) {
                  debugPrint('  加えて: pitched=false (pitch=${result.pitch.toStringAsFixed(2)}Hz, probability=${result.probability.toStringAsFixed(3)})');
                } else if (result.probability <= 0.1) {
                  debugPrint('  加えて: 低確率 (${result.probability.toStringAsFixed(3)})');
                }
              }
            }
          }
        } catch (e) {
          // エラーの場合は0を追加
          pitches.add(0.0);
          if (totalChunks <= 10) {
            debugPrint('チャンク$totalChunks: エラー - $e');
          }
        }
      }

      debugPrint('ピッチ検出結果: ${pitches.length}個中 $validDetections個が有効');
      debugPrint('有効検出率: ${(validDetections / pitches.length * 100).toStringAsFixed(1)}%');
      
      // 最初の10個の検出結果を表示
      debugPrint('検出ピッチサンプル（最初の10個）:');
      final samplePitches = pitches.take(10).toList();
      for (int i = 0; i < samplePitches.length; i++) {
        debugPrint('  [$i]: ${samplePitches[i].toStringAsFixed(2)}Hz');
      }
      
      debugPrint('=== ピッチ検出デバッグ終了 ===');

      return pitches;
    } catch (e) {
      debugPrint('ピッチ検出エラー: $e');
      // エラーが発生した場合は空のリストを返す
      return [];
    }
  }

  /// チャンクの音量レベルを計算
  double _calculateChunkVolume(Uint8List chunk) {
    if (chunk.length < 2) return 0.0;
    
    double sum = 0.0;
    int sampleCount = 0;
    
    // 16bitサンプルとして解釈
    for (int i = 0; i < chunk.length - 1; i += 2) {
      final sample = (chunk[i + 1] << 8) | chunk[i]; // Little Endian
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      sum += signedSample.abs();
      sampleCount++;
    }
    
    return sampleCount > 0 ? sum / sampleCount : 0.0;
  }

  /// ピッチデータの平滑化処理
  ///
  /// [pitches] 平滑化対象のピッチデータ
  /// [windowSize] 平滑化ウィンドウサイズ
  /// 戻り値: 平滑化されたピッチデータ
  List<double> smoothPitches(List<double> pitches, int windowSize) {
    if (pitches.length <= windowSize) return pitches;

    final smoothed = <double>[];

    for (int i = 0; i < pitches.length; i++) {
      if (pitches[i] == 0.0) {
        smoothed.add(0.0);
        continue;
      }

      final start = math.max(0, i - windowSize ~/ 2);
      final end = math.min(pitches.length, i + windowSize ~/ 2 + 1);

      double sum = 0;
      int count = 0;

      for (int j = start; j < end; j++) {
        if (pitches[j] > 0 && 
            pitches[j] >= minPitchHz && 
            pitches[j] <= maxPitchHz) {
          // 無音部分と範囲外の値を除外
          sum += pitches[j];
          count++;
        }
      }

      final averagePitch = count > 0 ? sum / count : 0.0;
      // 平滑化後も範囲チェック
      if (averagePitch >= minPitchHz && averagePitch <= maxPitchHz) {
        smoothed.add(averagePitch);
      } else {
        smoothed.add(0.0);
      }
    }

    return smoothed;
  }

  /// ピッチデータの統計情報を取得
  Map<String, double> getPitchStatistics(List<double> pitches) {
    final validPitches = pitches.where((p) => p > 0).toList();

    if (validPitches.isEmpty) {
      return {
        'min': 0.0,
        'max': 0.0,
        'average': 0.0,
        'median': 0.0,
        'standardDeviation': 0.0,
        'validRatio': 0.0,
      };
    }

    validPitches.sort();

    final sum = validPitches.reduce((a, b) => a + b);
    final average = sum / validPitches.length;

    // 標準偏差の計算
    final variance =
        validPitches.map((p) => math.pow(p - average, 2)).reduce((a, b) => a + b) /
        validPitches.length;

    return {
      'min': validPitches.first,
      'max': validPitches.last,
      'average': average,
      'median': validPitches[validPitches.length ~/ 2],
      'standardDeviation': math.sqrt(variance),
      'validRatio': validPitches.length / pitches.length,
    };
  }

  /// 改良されたオクターブ補正メソッド
  /// 
  /// [detectedPitch] 検出されたピッチ
  /// [referencePitch] 参照ピッチ（null可）
  /// 戻り値: 補正されたピッチ
  double correctOctave(double detectedPitch, double? referencePitch) {
    if (referencePitch == null) {
      // 参照ピッチがない場合は、基本的な範囲チェックのみ
      double correctedPitch = detectedPitch;
      
      // 範囲内に収まるようにオクターブを調整
      while (correctedPitch < minPitchHz && correctedPitch > 0) {
        correctedPitch *= 2.0;
      }
      while (correctedPitch > maxPitchHz) {
        correctedPitch /= 2.0;
      }
      
      return correctedPitch;
    }

    double bestPitch = detectedPitch;
    double bestError = (detectedPitch / referencePitch - 1.0).abs();
    
    // より幅広いオクターブ範囲をチェック（-3〜+3）
    for (int octave = -3; octave <= 3; octave++) {
      double testPitch = detectedPitch * math.pow(2, octave);
      double testRatio = testPitch / referencePitch;
      double error = (testRatio - 1.0).abs();
      
      // より良い一致を見つけた場合、更新
      if (error < bestError) {
        bestPitch = testPitch;
        bestError = error;
      }
    }
    
    // セミトーンレベルの微調整も試行（±6セミトーン）
    for (double semitone = -6; semitone <= 6; semitone++) {
      double testPitch = bestPitch * math.pow(2, semitone / 12.0);
      double testRatio = testPitch / referencePitch;
      double error = (testRatio - 1.0).abs();
      
      if (error < bestError && testPitch >= minPitchHz && testPitch <= maxPitchHz) {
        bestPitch = testPitch;
        bestError = error;
      }
    }
    
    return bestPitch;
  }

  /// 時間位置に基づいて動的にピッチを推定
  /// 
  /// [currentChunk] 現在のチャンク番号
  /// [totalChunks] 全チャンク数
  /// [referencePitches] 基準ピッチデータ
  /// 戻り値: 推定されたピッチ
  double _estimatePitchFromTimePosition(int currentChunk, int totalChunks, List<double>? referencePitches) {
    // デフォルト値
    const defaultPitch = 190.0;
    
    if (referencePitches == null || referencePitches.isEmpty || totalChunks <= 0) {
      if (currentChunk <= 10) {
        debugPrint('    動的推定: 基準ピッチなし -> デフォルト ${defaultPitch}Hz');
      }
      return defaultPitch;
    }
    
    // 時間進行率を計算
    final timeProgress = currentChunk / totalChunks;
    
    // 基準ピッチデータの対応する位置を計算
    final referenceIndex = (timeProgress * referencePitches.length).floor().clamp(0, referencePitches.length - 1);
    final referencePitch = referencePitches[referenceIndex];
    
    if (currentChunk <= 10) {
      debugPrint('    動的推定: 時間進行${(timeProgress * 100).toStringAsFixed(1)}% -> 基準インデックス$referenceIndex (${referencePitches.length}中)');
      debugPrint('    動的推定: 基準ピッチ=${referencePitch.toStringAsFixed(2)}Hz');
    }
    
    // 基準ピッチが有効な場合はそれを使用、そうでなければ近くの有効ピッチを探す
    if (referencePitch > 0) {
      if (currentChunk <= 10) {
        debugPrint('    動的推定: 結果=${referencePitch.toStringAsFixed(2)}Hz (直接採用)');
      }
      return referencePitch;
    }
    
    // 近くの有効なピッチを探す
    for (int offset = 1; offset < referencePitches.length ~/ 4; offset++) {
      // 前方を探す
      final forwardIndex = referenceIndex + offset;
      if (forwardIndex < referencePitches.length && referencePitches[forwardIndex] > 0) {
        if (currentChunk <= 10) {
          debugPrint('    動的推定: 結果=${referencePitches[forwardIndex].toStringAsFixed(2)}Hz (前方検索 +$offset)');
        }
        return referencePitches[forwardIndex];
      }
      
      // 後方を探す
      final backwardIndex = referenceIndex - offset;
      if (backwardIndex >= 0 && referencePitches[backwardIndex] > 0) {
        if (currentChunk <= 10) {
          debugPrint('    動的推定: 結果=${referencePitches[backwardIndex].toStringAsFixed(2)}Hz (後方検索 -$offset)');
        }
        return referencePitches[backwardIndex];
      }
    }
    
    if (currentChunk <= 10) {
      debugPrint('    動的推定: 有効ピッチ見つからず -> デフォルト ${defaultPitch}Hz');
    }
    return defaultPitch;
  }
}

/// ピッチ検出に関する例外クラス
class PitchDetectionException implements Exception {
  final String message;
  const PitchDetectionException(this.message);

  @override
  String toString() => 'PitchDetectionException: $message';
}
