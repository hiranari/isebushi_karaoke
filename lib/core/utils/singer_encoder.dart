import 'dart:convert';

/// 歌手名のエンコード/デコードユーティリティ
/// 
/// パブリックリポジトリでの人名公開を避けるため、
/// 歌手名をBase64エンコードして保存し、表示時にデコードします。
class SingerEncoder {
  /// 歌手名をエンコード（Base64）
  /// 
  /// [singerName] エンコードする歌手名
  /// @return Base64エンコードされた文字列
  static String encode(String singerName) {
    final bytes = utf8.encode(singerName);
    return base64.encode(bytes);
  }

  /// 歌手名をデコード（Base64）
  /// 
  /// [encodedSinger] Base64エンコードされた歌手名
  /// @return デコードされた歌手名
  static String decode(String encodedSinger) {
    try {
      final bytes = base64.decode(encodedSinger);
      return utf8.decode(bytes);
    } catch (e) {
      // デコードに失敗した場合は、そのまま返す（既存データとの互換性）
      return encodedSinger;
    }
  }

  /// 歌手名が既にエンコードされているかチェック
  /// 
  /// [singer] チェックする文字列
  /// @return エンコード済みの場合true
  static bool isEncoded(String singer) {
    try {
      // Base64文字列の基本的な形式チェック
      if (singer.length % 4 != 0) return false;
      
      // Base64デコードを試行
      final bytes = base64.decode(singer);
      final decoded = utf8.decode(bytes);
      
      // デコード結果が日本語文字を含むかチェック
      return decoded.contains(RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]'));
    } catch (e) {
      return false;
    }
  }

  /// 既存のsong.jsonデータを一括変換するヘルパー
  /// 
  /// [songs] 楽曲データのリスト
  /// @return エンコード済みの楽曲データ
  static List<Map<String, dynamic>> encodeSongsData(List<Map<String, dynamic>> songs) {
    return songs.map((song) {
      final encodedSong = Map<String, dynamic>.from(song);
      if (encodedSong['singer'] != null && !isEncoded(encodedSong['singer'])) {
        encodedSong['singer'] = encode(encodedSong['singer']);
      }
      return encodedSong;
    }).toList();
  }
}
