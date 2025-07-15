import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/audio_analysis_result.dart';

/// ピッチ検出結果のキャッシュを管理するサービスクラス
class CacheService {
  static const String CACHE_DIRECTORY = 'pitch_cache';
  static const String CACHE_FILE_EXTENSION = '.json';
  static const String CACHE_VERSION = '1.0';
  static const int MAX_CACHE_AGE_DAYS = 30;

  /// キャッシュファイルのパスを生成
  ///
  /// [assetPath] 元ファイルのパス
  /// 戻り値: キャッシュファイルのパス
  static Future<String> _getCacheFilePath(String assetPath) async {
    final directory = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${directory.path}/$CACHE_DIRECTORY');

    // キャッシュディレクトリが存在しない場合は作成
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }

    // ファイル名を生成（パスをハッシュ化して安全なファイル名にする）
    final fileName = assetPath.hashCode.abs().toString();
    return '${cacheDir.path}/$fileName$CACHE_FILE_EXTENSION';
  }

  /// キャッシュからピッチデータを読み込み
  ///
  /// [assetPath] 元ファイルのパス
  /// 戻り値: キャッシュされた解析結果（存在しない場合はnull）
  static Future<AudioAnalysisResult?> loadFromCache(String assetPath) async {
    try {
      final cacheFilePath = await _getCacheFilePath(assetPath);
      final cacheFile = File(cacheFilePath);

      if (!await cacheFile.exists()) {
        return null;
      }

      // キャッシュファイルの年齢チェック
      final fileStat = await cacheFile.stat();
      final age = DateTime.now().difference(fileStat.modified).inDays;

      if (age > MAX_CACHE_AGE_DAYS) {
        // 古いキャッシュは削除
        await cacheFile.delete();
        return null;
      }

      final jsonString = await cacheFile.readAsString();
      final jsonData = jsonDecode(jsonString);

      // バージョンチェック
      if (jsonData['version'] != CACHE_VERSION) {
        // バージョンが異なる場合は削除
        await cacheFile.delete();
        return null;
      }

      return AudioAnalysisResult.fromJson(jsonData['data']);
    } catch (e) {
      // キャッシュ読み込みエラーは無視（再解析で対応）
      print('キャッシュ読み込みエラー: $e');
      return null;
    }
  }

  /// ピッチデータをキャッシュに保存
  ///
  /// [assetPath] 元ファイルのパス
  /// [result] 保存する解析結果
  static Future<void> saveToCache(String assetPath, AudioAnalysisResult result) async {
    try {
      final cacheFilePath = await _getCacheFilePath(assetPath);
      final cacheFile = File(cacheFilePath);

      // バージョン情報を含むデータ構造
      final cacheData = {
        'version': CACHE_VERSION,
        'savedAt': DateTime.now().toIso8601String(),
        'data': result.toJson(),
      };

      final jsonString = jsonEncode(cacheData);
      await cacheFile.writeAsString(jsonString);

      print('キャッシュ保存完了: $assetPath');
    } catch (e) {
      // キャッシュ保存エラーは無視（機能に影響しない）
      print('キャッシュ保存エラー: $e');
    }
  }

  /// 特定のファイルのキャッシュを削除
  ///
  /// [assetPath] 対象ファイルのパス
  static Future<void> clearCache(String assetPath) async {
    try {
      final cacheFilePath = await _getCacheFilePath(assetPath);
      final cacheFile = File(cacheFilePath);

      if (await cacheFile.exists()) {
        await cacheFile.delete();
        print('キャッシュ削除完了: $assetPath');
      }
    } catch (e) {
      print('キャッシュ削除エラー: $e');
    }
  }

  /// 全キャッシュを削除
  static Future<void> clearAllCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/$CACHE_DIRECTORY');

      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        print('全キャッシュ削除完了');
      }
    } catch (e) {
      print('全キャッシュ削除エラー: $e');
    }
  }

  /// キャッシュサイズを取得
  ///
  /// 戻り値: キャッシュサイズ（バイト）
  static Future<int> getCacheSize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/$CACHE_DIRECTORY');

      if (!await cacheDir.exists()) {
        return 0;
      }

      int totalSize = 0;
      await for (final file in cacheDir.list()) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return totalSize;
    } catch (e) {
      print('キャッシュサイズ取得エラー: $e');
      return 0;
    }
  }

  /// キャッシュ情報の取得
  ///
  /// 戻り値: キャッシュファイル数とサイズの情報
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/$CACHE_DIRECTORY');

      if (!await cacheDir.exists()) {
        return {'fileCount': 0, 'totalSize': 0, 'lastModified': null};
      }

      int fileCount = 0;
      int totalSize = 0;
      DateTime? lastModified;

      await for (final file in cacheDir.list()) {
        if (file is File && file.path.endsWith(CACHE_FILE_EXTENSION)) {
          fileCount++;
          final stat = await file.stat();
          totalSize += stat.size;

          if (lastModified == null || stat.modified.isAfter(lastModified)) {
            lastModified = stat.modified;
          }
        }
      }

      return {
        'fileCount': fileCount,
        'totalSize': totalSize,
        'lastModified': lastModified?.toIso8601String(),
      };
    } catch (e) {
      print('キャッシュ情報取得エラー: $e');
      return {'fileCount': 0, 'totalSize': 0, 'lastModified': null};
    }
  }

  /// 古いキャッシュファイルをクリーンアップ
  static Future<void> cleanupOldCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${directory.path}/$CACHE_DIRECTORY');

      if (!await cacheDir.exists()) {
        return;
      }

      int deletedCount = 0;
      final cutoffDate = DateTime.now().subtract(Duration(days: MAX_CACHE_AGE_DAYS));

      await for (final file in cacheDir.list()) {
        if (file is File && file.path.endsWith(CACHE_FILE_EXTENSION)) {
          final stat = await file.stat();

          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            deletedCount++;
          }
        }
      }

      print('古いキャッシュ削除完了: $deletedCount ファイル');
    } catch (e) {
      print('キャッシュクリーンアップエラー: $e');
    }
  }
}
