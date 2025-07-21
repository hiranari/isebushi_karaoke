import 'dart:convert';
import 'dart:io';
import '../lib/utils/singer_encoder.dart';

/// エンコード・デコード機能のテスト
void main() async {
  print('=== 歌手名エンコード・デコード テスト ===\n');
  
  // 1. 直接テスト
  print('1. 直接エンコード・デコードテスト');
  final testNames = ['岡嵜和義', '西村一男', '伊勢節の歌手'];
  
  for (final name in testNames) {
    final encoded = SingerEncoder.encode(name);
    final decoded = SingerEncoder.decode(encoded);
    final isEncoded = SingerEncoder.isEncoded(encoded);
    
    print('  元の名前: $name');
    print('  エンコード: $encoded');
    print('  デコード: $decoded');
    print('  エンコード判定: $isEncoded');
    print('  正常: ${name == decoded}');
    print('');
  }
  
  // 2. 実際のファイルテスト
  print('2. 実際のsong.jsonファイル読み込みテスト');
  
  try {
    final file = File('assets/data/song.json');
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      final List<dynamic> songs = json.decode(jsonString);
      
      print('  ファイル読み込み成功: ${songs.length}曲');
      
      for (int i = 0; i < songs.length; i++) {
        final song = songs[i];
        if (song['singer'] != null) {
          final encodedSinger = song['singer'] as String;
          final decodedSinger = SingerEncoder.decode(encodedSinger);
          final isEncoded = SingerEncoder.isEncoded(encodedSinger);
          
          print('  楽曲${i + 1}: ${song['title']}');
          print('    エンコード済み歌手: $encodedSinger');
          print('    デコード後歌手: $decodedSinger');
          print('    エンコード判定: $isEncoded');
          print('');
        }
      }
    } else {
      print('  エラー: song.json が見つかりません');
    }
  } catch (e) {
    print('  エラー: $e');
  }
  
  // 3. 非エンコードデータとの互換性テスト
  print('3. 非エンコードデータとの互換性テスト');
  final plainNames = ['平文の歌手名', 'Plain Singer Name'];
  
  for (final name in plainNames) {
    final decoded = SingerEncoder.decode(name); // 平文をデコードしても同じ値が返るはず
    final isEncoded = SingerEncoder.isEncoded(name);
    
    print('  平文: $name');
    print('  「デコード」結果: $decoded');
    print('  エンコード判定: $isEncoded');
    print('  正常: ${name == decoded}');
    print('');
  }
  
  print('=== テスト完了 ===');
}
