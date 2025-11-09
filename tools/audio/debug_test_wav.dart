// TODO: 実装後に有効化 - 現在はコンパイルエラー回避のためコメントアウト
/*#!/usr/bin/env dart

/// Test.wavファイルの詳細デバッグスクリプト
/// ピッチ検出が失敗する原因を詳細に分析する

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

void main() async {
  const filePath = 'assets/sounds/Test.wav';
  
  print('=== Test.wav 詳細分析開始 ===');
  
  // ファイル存在確認
  final file = File(filePath);
  if (!file.existsSync()) {
    print('❌ ファイルが存在しません: $filePath');
    return;
  }
  
  final fileSize = file.lengthSync();
  print('📁 ファイルサイズ: $fileSize bytes');
  
  // ファイル全体を読み込み
  final bytes = await file.readAsBytes();
  print('📊 読み込み完了: ${bytes.length} bytes');
  
  // WAVヘッダー詳細解析
  print('\n=== WAVヘッダー詳細解析 ===');
  if (bytes.length < 44) {
    print('❌ WAVファイルとしては短すぎます');
    return;
  }
  
  // RIFFヘッダー
  final riffChunk = String.fromCharCodes(bytes.sublist(0, 4));
  final fileLength = _readUint32(bytes, 4);
  final waveFormat = String.fromCharCodes(bytes.sublist(8, 12));
  
  print('RIFF Chunk: $riffChunk');
  print('ファイル長: $fileLength bytes');
  print('WAVE Format: $waveFormat');
  
  // fmtチャンク
  final fmtChunk = String.fromCharCodes(bytes.sublist(12, 16));
  final fmtSize = _readUint32(bytes, 16);
  final audioFormat = _readUint16(bytes, 20);
  final numChannels = _readUint16(bytes, 22);
  final sampleRate = _readUint32(bytes, 24);
  final byteRate = _readUint32(bytes, 28);
  final blockAlign = _readUint16(bytes, 32);
  final bitsPerSample = _readUint16(bytes, 34);
  
  print('\nfmt Chunk: $fmtChunk');
  print('fmt サイズ: $fmtSize');
  print('オーディオフォーマット: $audioFormat (1=PCM)');
  print('チャンネル数: $numChannels');
  print('サンプリングレート: $sampleRate Hz');
  print('バイトレート: $byteRate bytes/sec');
  print('ブロックアライン: $blockAlign');
  print('ビット深度: $bitsPerSample bits');
  
  // dataチャンクを探す
  int dataOffset = 36;
  String dataChunk = '';
  int dataSize = 0;
  
  // dataチャンクが36バイト目にない場合は探す
  while (dataOffset + 8 < bytes.length) {
    final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
    final chunkSize = _readUint32(bytes, dataOffset + 4);
    
    print('\nチャンク発見: "$chunkId" (サイズ: $chunkSize bytes, オフセット: $dataOffset)');
    
    if (chunkId == 'data') {
      dataChunk = chunkId;
      dataSize = chunkSize;
      dataOffset += 8; // ヘッダー分をスキップしてPCMデータ開始位置へ
      break;
    } else {
      // 他のチャンクをスキップ
      dataOffset += 8 + chunkSize;
      if (chunkSize % 2 == 1) dataOffset++; // パディング
    }
  }
  
  print('\ndata Chunk: $dataChunk');
  print('data サイズ: $dataSize bytes');
  print('PCMデータ開始オフセット: $dataOffset');
  
  if (dataChunk != 'data') {
    print('❌ dataチャンクが見つかりません');
    return;
  }
  
  // PCMデータ抽出
  final pcmData = bytes.sublist(dataOffset, dataOffset + dataSize);
  print('PCMデータ長: ${pcmData.length} bytes');
  
  // PCMデータ統計解析
  print('\n=== PCMデータ統計解析 ===');
  final sampleCount = pcmData.length ~/ (bitsPerSample ~/ 8) ~/ numChannels;
  final durationSeconds = sampleCount / sampleRate;
  
  print('サンプル数: $sampleCount');
  print('再生時間: ${durationSeconds.toStringAsFixed(2)} 秒');
  
  // 16bit PCMサンプル解析
  if (bitsPerSample == 16) {
    final samples = <int>[];
    
    for (int i = 0; i < pcmData.length - 1; i += 2) {
      // Little Endian 16bit signed integer
      final sample = (pcmData[i + 1] << 8) | pcmData[i];
      samples.add(sample > 32767 ? sample - 65536 : sample);
    }
    
    // 統計情報
    if (samples.isNotEmpty) {
      final minSample = samples.reduce((a, b) => a < b ? a : b);
      final maxSample = samples.reduce((a, b) => a > b ? a : b);
      final avgSample = samples.fold<double>(0, (sum, s) => sum + s) / samples.length;
      final range = maxSample - minSample;
      final rms = math.sqrt(samples.fold<double>(0, (sum, s) => sum + s * s) / samples.length);
      
      print('振幅範囲: $minSample 〜 $maxSample (レンジ: $range)');
      print('平均値: ${avgSample.toStringAsFixed(2)}');
      print('RMS: ${rms.toStringAsFixed(2)}');
      
      // 無音区間の分析
      int silentSamples = 0;
      const silentThreshold = 100; // 無音閾値
      for (final sample in samples) {
        if (sample.abs() < silentThreshold) {
          silentSamples++;
        }
      }
      final silentRatio = silentSamples / samples.length;
      print('無音サンプル数: $silentSamples / ${samples.length} (${(silentRatio * 100).toStringAsFixed(1)}%)');
      
      // 最初の1秒間のサンプルを詳細表示
      print('\n=== 最初の1秒間の詳細分析 ===');
      final firstSecondSamples = samples.take(sampleRate * numChannels).toList();
      if (firstSecondSamples.isNotEmpty) {
        final firstMin = firstSecondSamples.reduce((a, b) => a < b ? a : b);
        final firstMax = firstSecondSamples.reduce((a, b) => a > b ? a : b);
        final firstAvg = firstSecondSamples.fold<double>(0, (sum, s) => sum + s) / firstSecondSamples.length;
        
        print('最初の1秒: 範囲=$firstMin〜$firstMax, 平均=${firstAvg.toStringAsFixed(2)}');
        
        // 最初の20サンプルを表示
        final first20 = firstSecondSamples.take(20).map((s) => s.toString()).join(', ');
        print('最初の20サンプル: $first20');
        
        // 振幅変化の分析
        final amplitudeVariations = <int>[];
        for (int i = 1; i < firstSecondSamples.length; i++) {
          amplitudeVariations.add((firstSecondSamples[i] - firstSecondSamples[i - 1]).abs());
        }
        
        if (amplitudeVariations.isNotEmpty) {
          final avgVariation = amplitudeVariations.fold<double>(0, (sum, v) => sum + v) / amplitudeVariations.length;
          final maxVariation = amplitudeVariations.reduce((a, b) => a > b ? a : b);
          print('振幅変化: 平均=${avgVariation.toStringAsFixed(2)}, 最大=$maxVariation');
        }
      }
    }
  }
  
  print('\n=== 分析完了 ===');
  
  // 結論と推定
  print('\n=== 問題の可能性 ===');
  
  if (audioFormat != 1) {
    print('⚠️ 非PCMフォーマット（圧縮音源の可能性）');
  }
  
  if (numChannels != 1 && numChannels != 2) {
    print('⚠️ 想定外のチャンネル数');
  }
  
  if (bitsPerSample != 16) {
    print('⚠️ 16bit以外のビット深度');
  }
  
  if (sampleRate < 8000 || sampleRate > 48000) {
    print('⚠️ 想定外のサンプリングレート');
  }
  
  final expectedBlockAlign = numChannels * (bitsPerSample ~/ 8);
  if (blockAlign != expectedBlockAlign) {
    print('⚠️ ブロックアライン不整合 (実際:$blockAlign, 期待:$expectedBlockAlign)');
  }
}

int _readUint32(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

int _readUint16(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}
*/

void main() {
  print("debug_test_wav.dart - 実装待ち");
}
