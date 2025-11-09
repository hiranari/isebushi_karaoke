// TODO: 実装後に有効化 - 現在はコンパイルエラー回避のためコメントアウト
/*#!/usr/bin/env dart

/// Test_improved.wav専用テストスクリプト
/// 改善版音源でのピッチ検出精度をテスト

import 'dart:io';
import 'dart:typed_data';

void main() async {
  print('=== Test_improved.wav ピッチ検出テスト ===');
  
  const audioPath = 'assets/sounds/Test_improved.wav';
  
  // ファイル存在確認
  final audioFile = File(audioPath);
  if (!await audioFile.exists()) {
    print('❌ Test_improved.wavファイルが見つかりません');
    return;
  }
  
  print('✅ Test_improved.wavファイル確認完了');
  print('ファイルサイズ: ${await audioFile.length()} bytes');
  
  // WAVファイル解析
  await _analyzeImprovedWavFile(audioPath);
  
  // 期待されるピッチパターンの表示
  _showExpectedResults();
  
  // テスト手順の表示
  _showTestInstructions();
}

Future<void> _analyzeImprovedWavFile(String audioPath) async {
  print('\n🔍 Test_improved.wav詳細解析:');
  
  final file = File(audioPath);
  final bytes = await file.readAsBytes();
  
  // ヘッダー解析
  final sampleRate = _readUint32(bytes, 24);
  final channels = _readUint16(bytes, 22);
  final bitsPerSample = _readUint16(bytes, 34);
  final blockAlign = _readUint16(bytes, 32);
  final dataSize = _readUint32(bytes, 40);
  
  print('  サンプルレート: ${sampleRate}Hz');
  print('  チャンネル数: $channels');
  print('  ビット深度: $bitsPerSample bits');
  print('  ブロックアライン: $blockAlign');
  print('  データサイズ: $dataSize bytes');
  
  // 総再生時間計算
  final totalSamples = dataSize ~/ (channels * (bitsPerSample ~/ 8));
  final durationSeconds = totalSamples / sampleRate;
  print('  総再生時間: ${durationSeconds.toStringAsFixed(1)}秒');
  
  // PCMデータの最初と最後をチェック
  const pcmOffset = 44;
  if (bytes.length > pcmOffset + 20) {
    print('\n🎵 PCMデータ確認:');
    
    // 最初の10サンプル
    final firstSamples = <int>[];
    for (int i = 0; i < 20; i += 2) {
      final sample = (bytes[pcmOffset + i + 1] << 8) | bytes[pcmOffset + i];
      firstSamples.add(sample > 32767 ? sample - 65536 : sample);
    }
    print('  最初の10サンプル: ${firstSamples.join(', ')}');
    
    // 無音区間チェック
    final silentCount = firstSamples.where((s) => s.abs() < 10).length;
    if (silentCount > firstSamples.length * 0.8) {
      print('  ⚠️ 無音区間が検出されました');
    } else {
      print('  ✅ 音声データが即座に開始されています');
    }
  }
}

void _showExpectedResults() {
  print('\n🎯 期待されるピッチ検出結果:');
  
  const expectedFreqs = [
    {'note': 'ド(C4)', 'freq': 261.63, 'time': '0-1秒'},
    {'note': 'レ(D4)', 'freq': 293.66, 'time': '1-2秒'},
    {'note': 'ミ(E4)', 'freq': 329.63, 'time': '2-3秒'},
    {'note': 'ファ(F4)', 'freq': 349.23, 'time': '3-4秒'},
    {'note': 'ソ(G4)', 'freq': 392.00, 'time': '4-5秒'},
    {'note': 'ラ(A4)', 'freq': 440.00, 'time': '5-6秒'},
    {'note': 'シ(B4)', 'freq': 493.88, 'time': '6-7秒'},
    {'note': 'ド(C5)', 'freq': 523.25, 'time': '7-8秒'},
  ];
  
  for (final note in expectedFreqs) {
    print('  ${note['time']}: ${note['note']} - ${note['freq']}Hz');
  }
  
  print('\n📈 期待される改善点:');
  print('  ✅ 一定値(330Hz)ではなく段階的な周波数変化');
  print('  ✅ 8つの明確に異なるピッチ');
  print('  ✅ 無音区間スキップ不要');
  print('  ✅ 安定したピッチ検出精度');
}

void _showTestInstructions() {
  print('\n📋 Test_improved.wavテスト手順:');
  print('1. Flutterアプリを起動');
  print('   flutter run');
  print('');
  print('2. Test楽曲を選択');
  print('   - 楽曲選択画面で"テスト"楽曲をタップ');
  print('');
  print('3. 改善版音源に切り替え');
  print('   - カラオケ画面右上の緑色のアップグレードボタン🔄が表示されます');
  print('   - このボタンをタップして改善版音源に切り替え');
  print('   - "改善版音源に切り替えました" メッセージを確認');
  print('   ※ボタンが表示されない場合: コンソールで楽曲情報を確認');
  print('');
  print('4. 音源再生でピッチ検出テスト');
  print('   - "音源再生" ボタンをタップ');
  print('   - リアルタイムピッチ表示を観察');
  print('   - 期待: 261Hz→293Hz→329Hz→...→523Hz の段階的変化');
  print('');
  print('5. デバッグログ確認');
  print('   - コンソールログで詳細な検出結果を確認');
  print('   - 楽曲情報とアップグレードボタン表示状態を確認');
  print('');
  print('🎯 成功の判定基準:');
  print('   ✅ ピッチが一定値(330Hz)ではない');
  print('   ✅ 8つの異なる周波数が検出される');
  print('   ✅ 周波数が時間とともに上昇する');
  print('   ✅ 期待値に近い周波数範囲(250-550Hz)');
  print('');
  print('🔧 トラブルシューティング:');
  print('   - アップグレードボタンが表示されない → コンソールで楽曲情報確認');
  print('   - "🎵 選択された楽曲情報" で title: "テスト", audioFile: "assets/sounds/Test.wav" を確認');
  print('   - "アップグレードボタン表示: true" が表示されるか確認');
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
  print("test_improved_wav.dart - 実装待ち");
}
