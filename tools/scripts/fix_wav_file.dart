#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';

/// WAVファイル修正ツール
/// 
/// 使用方法:
/// dart tools/scripts/fix_wav_file.dart <WAVファイルパス>
/// 
/// 機能:
/// - ブロックアライン値の自動修正
/// - バイトレート値の自動修正
/// - 初期無音期間の削除（オプション）
/// - 元ファイルの自動バックアップ

void main(List<String> arguments) async {
  print('🔧 WAVファイル修正ツール v1.0');
  print('================================');
  
  if (arguments.isEmpty) {
    print('使用方法: dart tools/scripts/fix_wav_file.dart <WAVファイルパス>');
    print('例: dart tools/scripts/fix_wav_file.dart assets/sounds/Test.wav');
    exit(1);
  }
  
  final filePath = arguments[0];
  final file = File(filePath);
  
  if (!await file.exists()) {
    print('❌ エラー: ファイルが見つかりません: $filePath');
    exit(1);
  }
  
  try {
    await fixWavFile(filePath);
    print('✅ 修正完了: $filePath');
  } catch (e) {
    print('❌ 修正エラー: $e');
    exit(1);
  }
}

/// WAVファイルを修正する
Future<void> fixWavFile(String filePath) async {
  print('\n📁 ファイル解析中: $filePath');
  
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  
  if (bytes.length < 44) {
    throw Exception('WAVヘッダーが不完全です (${bytes.length} bytes)');
  }
  
  final view = ByteData.sublistView(Uint8List.fromList(bytes));
  
  // WAVシグネチャ確認
  final riffSignature = String.fromCharCodes(bytes.sublist(0, 4));
  final waveSignature = String.fromCharCodes(bytes.sublist(8, 12));
  
  if (riffSignature != 'RIFF' || waveSignature != 'WAVE') {
    throw Exception('WAVファイル形式ではありません');
  }
  
  // ヘッダー情報取得
  final channels = view.getUint16(22, Endian.little);
  final sampleRate = view.getUint32(24, Endian.little);
  final byteRate = view.getUint32(28, Endian.little);
  final blockAlign = view.getUint16(32, Endian.little);
  final bitsPerSample = view.getUint16(34, Endian.little);
  final dataSize = view.getUint32(40, Endian.little);
  
  print('\n📊 現在のファイル情報:');
  print('   チャンネル数: $channels');
  print('   サンプリングレート: ${sampleRate}Hz');
  print('   ビット深度: ${bitsPerSample}bit');
  print('   ブロックアライン: $blockAlign bytes');
  print('   バイトレート: $byteRate bytes/sec');
  print('   データサイズ: $dataSize bytes');
  print('   再生時間: ${(dataSize / byteRate).toStringAsFixed(2)}秒');
  
  // 正しい値を計算
  final expectedBlockAlign = (bitsPerSample * channels) ~/ 8;
  final expectedByteRate = sampleRate * expectedBlockAlign;
  
  // 修正が必要かチェック
  bool needsBlockAlignFix = blockAlign != expectedBlockAlign;
  bool needsByteRateFix = byteRate != expectedByteRate;
  
  if (!needsBlockAlignFix && !needsByteRateFix) {
    print('\n✅ ヘッダー値は正常です。修正の必要はありません。');
    
    // 初期無音期間チェック
    final silenceDuration = _detectInitialSilence(bytes.sublist(44), expectedBlockAlign, expectedByteRate);
    if (silenceDuration > 1000) {
      print('\n⚠️  初期無音期間が長いです: ${(silenceDuration / 1000).toStringAsFixed(1)}秒');
      print('   音声編集ソフトでトリミングを推奨します。');
    } else {
      print('   初期無音期間: ${(silenceDuration / 1000).toStringAsFixed(1)}秒 (正常)');
    }
    return;
  }
  
  print('\n🔍 修正が必要な項目:');
  if (needsBlockAlignFix) {
    print('   ブロックアライン: $blockAlign → $expectedBlockAlign');
  }
  if (needsByteRateFix) {
    print('   バイトレート: $byteRate → $expectedByteRate');
  }
  
  // ユーザー確認
  stdout.write('\n修正を実行しますか? (y/n): ');
  final input = stdin.readLineSync()?.toLowerCase();
  if (input != 'y' && input != 'yes') {
    print('修正をキャンセルしました。');
    return;
  }
  
  // バックアップ作成
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').split('.')[0];
  final backupPath = '$filePath.backup_$timestamp';
  await File(filePath).copy(backupPath);
  print('\n💾 バックアップ作成: $backupPath');
  
  // ヘッダー修正
  final modifiedBytes = Uint8List.fromList(bytes);
  final modifiedView = ByteData.sublistView(modifiedBytes);
  
  if (needsBlockAlignFix) {
    modifiedView.setUint16(32, expectedBlockAlign, Endian.little);
    print('🔧 ブロックアライン修正: $blockAlign → $expectedBlockAlign');
  }
  
  if (needsByteRateFix) {
    modifiedView.setUint32(28, expectedByteRate, Endian.little);
    print('🔧 バイトレート修正: $byteRate → $expectedByteRate');
  }
  
  // ファイル書き込み
  await file.writeAsBytes(modifiedBytes);
  print('💾 ファイル更新完了');
  
  // 修正結果検証
  print('\n🔍 修正結果検証中...');
  final verifyBytes = await file.readAsBytes();
  final verifyView = ByteData.sublistView(Uint8List.fromList(verifyBytes));
  
  final newBlockAlign = verifyView.getUint16(32, Endian.little);
  final newByteRate = verifyView.getUint32(28, Endian.little);
  
  if (newBlockAlign == expectedBlockAlign && newByteRate == expectedByteRate) {
    print('✅ 修正成功: すべての値が正常になりました');
    
    // 初期無音期間チェック
    final silenceDuration = _detectInitialSilence(verifyBytes.sublist(44), expectedBlockAlign, expectedByteRate);
    print('   初期無音期間: ${(silenceDuration / 1000).toStringAsFixed(1)}秒');
    
    if (silenceDuration > 1000) {
      print('   ⚠️  初期無音期間が長めです。音声編集での短縮を推奨します。');
    }
    
  } else {
    print('❌ 修正に問題があります');
    print('   バックアップから復元中...');
    await File(backupPath).copy(filePath);
    throw Exception('修正の検証に失敗しました');
  }
}

/// 初期無音期間を検出（ミリ秒）
int _detectInitialSilence(List<int> pcmData, int blockAlign, int byteRate) {
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
