#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';

/// WAVファイル一括検証・修正ツール
/// 
/// 使用方法:
/// dart tools/scripts/validate_all_wavs.dart
/// 
/// 機能:
/// - 全WAVファイルの一括検証
/// - 問題ファイルのリスト表示
/// - 一括修正オプション
/// - 修正結果の検証

void main() async {
  print('🔍 WAVファイル一括検証ツール v1.0');
  print('====================================');
  
  final soundsDir = Directory('assets/sounds');
  if (!await soundsDir.exists()) {
    print('❌ エラー: assets/soundsディレクトリが見つかりません');
    exit(1);
  }
  
  final wavFiles = await soundsDir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.wav'))
      .cast<File>()
      .toList();
  
  if (wavFiles.isEmpty) {
    print('ℹ️  WAVファイルが見つかりませんでした');
    return;
  }
  
  print('\n📁 検証対象ファイル: ${wavFiles.length}個');
  
  final results = <String, ValidationResult>{};
  
  for (final file in wavFiles) {
    final relativePath = file.path.replaceAll(RegExp(r'^.*assets/'), 'assets/');
    print('\n🔍 検証中: $relativePath');
    
    try {
      final result = await validateWavFile(file);
      results[relativePath] = result;
      
      if (result.isValid) {
        print('   ✅ 正常');
      } else {
        print('   ❌ 問題あり: ${result.issues.join(', ')}');
      }
    } catch (e) {
      results[relativePath] = ValidationResult(false, ['エラー: $e']);
      print('   ❌ エラー: $e');
    }
  }
  
  // 結果サマリー
  final validFiles = results.values.where((r) => r.isValid).length;
  final invalidFiles = results.length - validFiles;
  
  print('\n📊 検証結果サマリー');
  print('==================');
  print('正常ファイル: $validFiles個');
  print('問題ファイル: $invalidFiles個');
  
  if (invalidFiles > 0) {
    print('\n⚠️  問題のあるファイル:');
    results.forEach((path, result) {
      if (!result.isValid) {
        print('   $path');
        for (final issue in result.issues) {
          print('     - $issue');
        }
      }
    });
    
    print('\n修正ツールの使用方法:');
    print('dart tools/scripts/fix_wav_file.dart <ファイルパス>');
    
    // 一括修正オプション
    stdout.write('\n全ての問題ファイルを一括修正しますか? (y/n): ');
    final input = stdin.readLineSync()?.toLowerCase();
    
    if (input == 'y' || input == 'yes') {
      print('\n🔧 一括修正開始...');
      
      for (final entry in results.entries) {
        if (!entry.value.isValid) {
          try {
            print('\n修正中: ${entry.key}');
            await fixWavFile(entry.key);
            print('✅ 修正完了');
          } catch (e) {
            print('❌ 修正失敗: $e');
          }
        }
      }
      
      print('\n✅ 一括修正完了');
    }
  } else {
    print('\n🎉 すべてのファイルが正常です！');
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> issues;
  
  ValidationResult(this.isValid, this.issues);
}

/// WAVファイルを検証する
Future<ValidationResult> validateWavFile(File file) async {
  final bytes = await file.readAsBytes();
  final issues = <String>[];
  
  if (bytes.length < 44) {
    return ValidationResult(false, ['WAVヘッダーが不完全']);
  }
  
  final view = ByteData.sublistView(Uint8List.fromList(bytes));
  
  // WAVシグネチャ確認
  final riffSignature = String.fromCharCodes(bytes.sublist(0, 4));
  final waveSignature = String.fromCharCodes(bytes.sublist(8, 12));
  
  if (riffSignature != 'RIFF' || waveSignature != 'WAVE') {
    issues.add('WAVファイル形式ではありません');
  }
  
  final channels = view.getUint16(22, Endian.little);
  final sampleRate = view.getUint32(24, Endian.little);
  final byteRate = view.getUint32(28, Endian.little);
  final blockAlign = view.getUint16(32, Endian.little);
  final bitsPerSample = view.getUint16(34, Endian.little);
  // dataSize変数は検証では使用しないため削除
  
  // サポート外形式チェック
  if (channels < 1 || channels > 2) {
    issues.add('チャンネル数が無効 ($channels)');
  }
  
  if (bitsPerSample != 16) {
    issues.add('ビット深度が無効 ($bitsPerSample)');
  }
  
  // ヘッダー整合性チェック
  final expectedBlockAlign = (bitsPerSample * channels) ~/ 8;
  final expectedByteRate = sampleRate * expectedBlockAlign;
  
  if (blockAlign != expectedBlockAlign) {
    issues.add('ブロックアライン不正 ($blockAlign, 期待値: $expectedBlockAlign)');
  }
  
  if (byteRate != expectedByteRate) {
    issues.add('バイトレート不正 ($byteRate, 期待値: $expectedByteRate)');
  }
  
  // 初期無音期間チェック
  final silenceDuration = _detectInitialSilence(bytes.sublist(44), expectedBlockAlign, expectedByteRate);
  if (silenceDuration > 1000) {
    issues.add('初期無音期間が長い (${(silenceDuration / 1000).toStringAsFixed(1)}秒)');
  }
  
  return ValidationResult(issues.isEmpty, issues);
}

/// WAVファイルを修正する（fix_wav_file.dartから移植）
Future<void> fixWavFile(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  
  if (bytes.length < 44) {
    throw Exception('WAVヘッダーが不完全です');
  }
  
  final view = ByteData.sublistView(Uint8List.fromList(bytes));
  
  // ヘッダー情報取得
  final channels = view.getUint16(22, Endian.little);
  final sampleRate = view.getUint32(24, Endian.little);
  final byteRate = view.getUint32(28, Endian.little);
  final blockAlign = view.getUint16(32, Endian.little);
  final bitsPerSample = view.getUint16(34, Endian.little);
  
  // 正しい値を計算
  final expectedBlockAlign = (bitsPerSample * channels) ~/ 8;
  final expectedByteRate = sampleRate * expectedBlockAlign;
  
  // 修正が必要かチェック
  bool needsBlockAlignFix = blockAlign != expectedBlockAlign;
  bool needsByteRateFix = byteRate != expectedByteRate;
  
  if (!needsBlockAlignFix && !needsByteRateFix) {
    return; // 修正不要
  }
  
  // バックアップ作成
  final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').replaceAll('-', '').split('.')[0];
  final backupPath = '$filePath.backup_$timestamp';
  await file.copy(backupPath);
  
  // ヘッダー修正
  final modifiedBytes = Uint8List.fromList(bytes);
  final modifiedView = ByteData.sublistView(modifiedBytes);
  
  if (needsBlockAlignFix) {
    modifiedView.setUint16(32, expectedBlockAlign, Endian.little);
  }
  
  if (needsByteRateFix) {
    modifiedView.setUint32(28, expectedByteRate, Endian.little);
  }
  
  // ファイル書き込み
  await file.writeAsBytes(modifiedBytes);
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
