import 'dart:convert';
import 'dart:io';
import '../lib/utils/singer_encoder.dart';

/// song.jsonの歌手名を一括エンコードするツール
/// 
/// 使用方法:
/// dart tools/encode_singers.dart
void main() async {
  const inputFile = 'assets/data/song.json';
  const outputFile = 'assets/data/song_encoded.json';
  
  try {
    // song.jsonを読み込み
    final file = File(inputFile);
    if (!await file.exists()) {
      print('エラー: $inputFile が見つかりません');
      return;
    }
    
    final jsonString = await file.readAsString();
    final List<dynamic> songsData = json.decode(jsonString);
    
    // 歌手名をエンコード
    final encodedSongs = songsData.map((song) {
      final songMap = Map<String, dynamic>.from(song);
      if (songMap['singer'] != null) {
        final originalSinger = songMap['singer'] as String;
        final encodedSinger = SingerEncoder.encode(originalSinger);
        
        print('エンコード: "$originalSinger" -> "$encodedSinger"');
        songMap['singer'] = encodedSinger;
      }
      return songMap;
    }).toList();
    
    // エンコード済みデータを保存
    final encodedJson = const JsonEncoder.withIndent('    ').convert(encodedSongs);
    await File(outputFile).writeAsString(encodedJson);
    
    print('\n✅ エンコード完了');
    print('出力ファイル: $outputFile');
    print('確認後、元のファイルを置き換えてください。');
    
    // デコードテスト
    print('\n--- デコードテスト ---');
    for (final song in encodedSongs) {
      if (song['singer'] != null) {
        final decoded = SingerEncoder.decode(song['singer']);
        print('${song['title']}: ${song['singer']} -> $decoded');
      }
    }
    
  } catch (e) {
    print('エラー: $e');
  }
}
